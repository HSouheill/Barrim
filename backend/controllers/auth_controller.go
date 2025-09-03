package controllers

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math/rand"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"

	"encoding/base64"

	"github.com/HSouheill/barrim_backend/config"
	"github.com/HSouheill/barrim_backend/middleware"
	"github.com/HSouheill/barrim_backend/models"
	"github.com/HSouheill/barrim_backend/services"
	"github.com/HSouheill/barrim_backend/utils"
	"github.com/golang-jwt/jwt"
	"github.com/lestrrat-go/jwx/jwk"
	"github.com/twilio/twilio-go"
)

const (
	twilioBaseURL = "https://verify.twilio.com/v2"
)

// AuthController contains authentication logic
type AuthController struct {
	DB                *mongo.Client
	logger            *log.Logger
	twilioClient      *twilio.RestClient
	accountSid        string
	authToken         string
	twilioPhoneNumber string
	verifyServiceSid  string
	loginAttempts     map[string]struct {
		count       int
		lastAttempt time.Time
	}
	loginAttemptsMu   sync.RWMutex
	loginAttemptsByIP map[string]struct {
		count       int
		lastAttempt time.Time
	}
	loginAttemptsByIPMu sync.RWMutex
}

// NewAuthController creates a new auth controller
func NewAuthController(db *mongo.Client) *AuthController {
	accountSid := os.Getenv("TWILIO_ACCOUNT_SID")
	authToken := os.Getenv("TWILIO_AUTH_TOKEN")
	twilioPhoneNumber := os.Getenv("TWILIO_PHONE_NUMBER")
	verifyServiceSid := os.Getenv("TWILIO_VERIFY_SERVICE_SID")

	twilioClient := twilio.NewRestClientWithParams(twilio.ClientParams{
		Username: accountSid,
		Password: authToken,
	})

	ac := &AuthController{
		DB:                db,
		logger:            log.New(os.Stdout, "[AUTH] ", log.LstdFlags),
		twilioClient:      twilioClient,
		accountSid:        accountSid,
		authToken:         authToken,
		twilioPhoneNumber: twilioPhoneNumber,
		verifyServiceSid:  verifyServiceSid,
		loginAttempts: make(map[string]struct {
			count       int
			lastAttempt time.Time
		}),
		loginAttemptsByIP: make(map[string]struct {
			count       int
			lastAttempt time.Time
		}),
	}

	// Start the OTP cleanup routine
	go ac.startOTPCleanupRoutine()
	go ac.startLoginAttemptCleanupRoutine()
	go ac.startRememberMeCleanupRoutine()

	return ac
}

// saveCompanyLogo saves a company logo and returns the file path
func saveCompanyLogo(logoFile *multipart.FileHeader) (string, error) {
	// Create the uploads/logo directory if it doesn't exist
	uploadDir := filepath.Join("uploads", "logo")
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		return "", err
	}

	// Generate a unique filename
	filename := fmt.Sprintf("%d_%s", time.Now().UnixNano(), logoFile.Filename)
	filePath := filepath.Join(uploadDir, filename)

	// Open the source file
	src, err := logoFile.Open()
	if err != nil {
		return "", err
	}
	defer src.Close()

	// Create the destination file
	dst, err := os.Create(filePath)
	if err != nil {
		return "", err
	}
	defer dst.Close()

	// Copy the file content
	if _, err = io.Copy(dst, src); err != nil {
		return "", err
	}

	// Return the relative path to the file
	return filepath.Join("uploads", "logo", filename), nil
}

// RandomStringGenerator generates a random string of specified length with given charset
func RandomStringGenerator(length int, charsetType string) string {
	rand.Seed(time.Now().UnixNano())

	var charset string
	switch charsetType {
	case "numeric":
		charset = "0123456789"
	case "alphanumeric":
		charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	default:
		charset = "0123456789"
	}

	result := make([]byte, length)
	for i := range result {
		result[i] = charset[rand.Intn(len(charset))]
	}

	return string(result)
}

// generateAuthOTP generates a 6-digit OTP for authentication
func generateAuthOTP() string {
	return RandomStringGenerator(6, "numeric")
}

// Send OTP via SMS using Twilio SMS API
func (ac *AuthController) sendOTP(phone, otp string) error {
	return utils.SendOTPViaSMS(phone, otp)
}

// Signup handler
func (ac *AuthController) Signup(c echo.Context) error {
	// Parse request
	var req models.SignupRequest

	// Check if we have a pre-filled request from SignupWithLogo
	if signupReq, ok := c.Get("signupRequest").(models.SignupRequest); ok {
		req = signupReq
	} else {
		// Parse request normally
		if err := c.Bind(&req); err != nil {
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Invalid request body",
			})
		}
	}

	// Validate and sanitize email
	email, err := utils.SanitizeEmail(req.Email)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid email format",
		})
	}
	req.Email = email

	// Validate and sanitize phone
	phone, err := utils.SanitizePhone(req.Phone)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid phone number format",
		})
	}
	req.Phone = phone

	// Sanitize other fields
	req.FullName = utils.SanitizeInput(req.FullName)
	req.UserType = utils.SanitizeInput(req.UserType)
	req.DateOfBirth = utils.SanitizeInput(req.DateOfBirth)
	req.Gender = utils.SanitizeInput(req.Gender)
	// ProfilePic is optional, only sanitize if provided
	if req.ProfilePic != "" {
		req.ProfilePic = utils.SanitizeInput(req.ProfilePic)
	}

	// Ensure consistent user type for wholesalers
	if strings.ToLower(req.UserType) == "wholesaler" {
		req.UserType = "wholesaler"
	}

	// Validate required fields for regular users
	if req.UserType == "user" {
		if req.DateOfBirth == "" {
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Date of birth is required",
			})
		}
		if req.Gender == "" {
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Gender is required",
			})
		}
		// ProfilePic is optional, so no validation needed
		if len(req.InterestedDeals) == 0 {
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "At least one interested deal is required",
			})
		}
		if req.Location == nil {
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Location is required",
			})
		}
		// Validate location fields
		if req.Location.Country == "" || req.Location.City == "" || req.Location.Street == "" {
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Country, city, and street are required in location",
			})
		}
		// Sanitize location fields
		req.Location.Country = utils.SanitizeInput(req.Location.Country)
		req.Location.City = utils.SanitizeInput(req.Location.City)
		req.Location.Street = utils.SanitizeInput(req.Location.Street)
		req.Location.District = utils.SanitizeInput(req.Location.District)
		req.Location.PostalCode = utils.SanitizeInput(req.Location.PostalCode)

		// Sanitize interested deals
		for i, deal := range req.InterestedDeals {
			req.InterestedDeals[i] = utils.SanitizeInput(deal)
		}
	}

	ctx := context.Background()
	userCollection := ac.DB.Database("barrim").Collection("users")

	// Check if phone number already exists (only for non-company/wholesaler users)
	if req.UserType != "company" && req.UserType != "wholesaler" {
		var existingUserWithPhone models.User
		err = userCollection.FindOne(ctx, bson.M{"phone": req.Phone}).Decode(&existingUserWithPhone)
		if err == nil {
			return c.JSON(http.StatusConflict, models.Response{
				Status:  http.StatusConflict,
				Message: "Phone number already registered",
			})
		}
	}

	// Check if email already exists (only for non-company/wholesaler users)
	if req.UserType != "company" && req.UserType != "wholesaler" {
		var existingUser models.User
		err = userCollection.FindOne(ctx, bson.M{"email": req.Email}).Decode(&existingUser)
		if err == nil {
			return c.JSON(http.StatusConflict, models.Response{
				Status:  http.StatusConflict,
				Message: "Email already exists",
			})
		}
	}

	// For companies and wholesalers, validate all emails and phones
	if req.UserType == "company" && req.CompanyData != nil {
		// Sanitize all company emails
		for i, email := range req.CompanyData.Emails {
			sanitizedEmail, err := utils.SanitizeEmail(email)
			if err != nil {
				return c.JSON(http.StatusBadRequest, models.Response{
					Status:  http.StatusBadRequest,
					Message: fmt.Sprintf("Invalid email format: %s", email),
				})
			}
			req.CompanyData.Emails[i] = sanitizedEmail
		}

		// Sanitize all company phones
		for i, phone := range req.CompanyData.Phones {
			sanitizedPhone, err := utils.SanitizePhone(phone)
			if err != nil {
				return c.JSON(http.StatusBadRequest, models.Response{
					Status:  http.StatusBadRequest,
					Message: fmt.Sprintf("Invalid phone format: %s", phone),
				})
			}
			req.CompanyData.Phones[i] = sanitizedPhone
		}

		// Sanitize other company fields
		req.CompanyData.BusinessName = utils.SanitizeInput(req.CompanyData.BusinessName)
		req.CompanyData.Category = utils.SanitizeInput(req.CompanyData.Category)
		req.CompanyData.SubCategory = utils.SanitizeInput(req.CompanyData.SubCategory)
		req.CompanyData.Address.Street = utils.SanitizeInput(req.CompanyData.Address.Street)
		req.CompanyData.Address.City = utils.SanitizeInput(req.CompanyData.Address.City)
		req.CompanyData.Address.Country = utils.SanitizeInput(req.CompanyData.Address.Country)
	}

	if req.UserType == "wholesaler" && req.WholesalerData != nil {
		// Sanitize all wholesaler emails
		for i, email := range req.WholesalerData.Emails {
			sanitizedEmail, err := utils.SanitizeEmail(email)
			if err != nil {
				return c.JSON(http.StatusBadRequest, models.Response{
					Status:  http.StatusBadRequest,
					Message: fmt.Sprintf("Invalid email format: %s", email),
				})
			}
			req.WholesalerData.Emails[i] = sanitizedEmail
		}

		// Sanitize all wholesaler phones
		for i, phone := range req.WholesalerData.Phones {
			sanitizedPhone, err := utils.SanitizePhone(phone)
			if err != nil {
				return c.JSON(http.StatusBadRequest, models.Response{
					Status:  http.StatusBadRequest,
					Message: fmt.Sprintf("Invalid phone format: %s", phone),
				})
			}
			req.WholesalerData.Phones[i] = sanitizedPhone
		}

		// Sanitize other wholesaler fields
		req.WholesalerData.BusinessName = utils.SanitizeInput(req.WholesalerData.BusinessName)
		req.WholesalerData.Category = utils.SanitizeInput(req.WholesalerData.Category)
		req.WholesalerData.SubCategory = utils.SanitizeInput(req.WholesalerData.SubCategory)
	}

	// Generate OTP
	otp := generateAuthOTP()
	ac.logger.Printf("Generated OTP: %s for phone: %s", otp, req.Phone)
	fmt.Printf("🔐 SIGNUP OTP: %s for phone: %s\n", otp, req.Phone)

	// Store OTP and signup data in database
	otpCollection := ac.DB.Database("barrim").Collection("phone_otps")
	otpDoc := models.PhoneOTP{
		Phone:      req.Phone,
		OTP:        otp,
		SignupData: &req,
		ExpiresAt:  time.Now().Add(10 * time.Minute),
		Verified:   false,
	}

	// Delete any existing OTPs for this phone number
	_, err = otpCollection.DeleteMany(ctx, bson.M{"phone": req.Phone})
	if err != nil {
		ac.logger.Printf("Failed to delete existing OTPs: %v", err)
	}

	// Insert new OTP
	_, err = otpCollection.InsertOne(ctx, otpDoc)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to store OTP",
		})
	}

	// Send OTP via SMS using Twilio SMS API
	smsErr := ac.sendOTP(req.Phone, otp)
	if smsErr != nil {
		ac.logger.Printf("SMS OTP failed: %v", smsErr)
		errMsg := "Failed to send OTP"
		if strings.Contains(smsErr.Error(), "auth") {
			errMsg = "Authentication error with SMS provider"
		} else if strings.Contains(smsErr.Error(), "credentials") {
			errMsg = "SMS provider credentials not properly configured"
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: errMsg,
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "OTP sent successfully via SMS. Please verify your phone number.",
		Data: map[string]interface{}{
			"phone":     req.Phone,
			"expiresAt": otpDoc.ExpiresAt,
			"method":    "sms",
		},
	})
}

// Helper function to generate a referral code
func generateReferralCode() string {
	rand.Seed(time.Now().UnixNano())
	const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	result := make([]byte, 8)
	for i := range result {
		result[i] = chars[rand.Intn(len(chars))]
	}
	return string(result)
}

func (ac *AuthController) SignupWithLogo(c echo.Context) error {
	// Parse multipart form
	if err := c.Request().ParseMultipartForm(10 << 20); err != nil { // 10MB max
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Failed to parse form data",
		})
	}

	// Get form values
	email := c.FormValue("email")
	password := c.FormValue("password")
	fullName := c.FormValue("fullName")
	businessName := c.FormValue("businessName")
	category := c.FormValue("category")
	subCategory := c.FormValue("subCategory")
	phone := c.FormValue("phone")
	referralCode := c.FormValue("referralCode") // Added referral code

	// Address fields
	country := c.FormValue("country")
	district := c.FormValue("district")
	city := c.FormValue("city")
	street := c.FormValue("street")
	postalCode := c.FormValue("postalCode")

	// Parse coordinates
	var lat, lng float64 = 0, 0
	if latStr := c.FormValue("lat"); latStr != "" {
		lat, _ = utils.ParseFloat(latStr)
	}
	if lngStr := c.FormValue("lng"); lngStr != "" {
		lng, _ = utils.ParseFloat(lngStr)
	}

	// Get the logo file
	file, err := c.FormFile("logo")
	var logoPath string
	if err == nil && file != nil {
		// Save the logo and get the path
		logoPath, err = saveCompanyLogo(file)
		if err != nil {
			// Log the error but continue without logo
			fmt.Printf("Error saving logo: %v\n", err)
		}
	}

	// Create the signup request
	req := models.SignupRequest{
		Email:    email,
		Password: password,
		FullName: fullName,
		UserType: "company",
		Phone:    phone,
		CompanyData: &models.CompanySignupData{
			BusinessName: businessName,
			Category:     category,
			SubCategory:  subCategory,
			Address: models.Address{
				Country:    country,
				District:   district,
				City:       city,
				Street:     street,
				PostalCode: postalCode,
				Lat:        lat,
				Lng:        lng,
			},
			Logo:         logoPath,
			ReferralCode: referralCode, // Add the referral code from form
		},
	}

	// Bind the request to the context
	c.Set("signupRequest", req)

	// Process the signup using the existing Signup method
	return ac.Signup(c)
}

func (ac *AuthController) SignupWholesalerWithLogo(c echo.Context) error {
	// Parse the multipart form
	err := c.Request().ParseMultipartForm(10 << 20) // 10 MB max
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Failed to parse form data: " + err.Error(),
		})
	}

	// Get form data
	userData := c.FormValue("userData")
	if userData == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "User data is required",
		})
	}

	// Parse JSON data from form
	var signupRequest models.SignupRequest
	if err := json.Unmarshal([]byte(userData), &signupRequest); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid JSON format in userData: " + err.Error(),
		})
	}

	// Validate wholesaler specific data
	if signupRequest.UserType != "wholesaler" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user type for this endpoint",
		})
	}

	// Validate required fields
	if signupRequest.Email == "" || signupRequest.Password == "" || signupRequest.FullName == "" || signupRequest.Phone == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Email, password, full name, and phone are required",
		})
	}

	// Sanitize inputs
	email, err := utils.SanitizeEmail(signupRequest.Email)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid email format",
		})
	}
	signupRequest.Email = email

	phone, err := utils.SanitizePhone(signupRequest.Phone)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid phone number format",
		})
	}
	signupRequest.Phone = phone

	signupRequest.FullName = utils.SanitizeInput(signupRequest.FullName)

	// Check if phone number already exists
	userCollection := ac.DB.Database("barrim").Collection("users")
	ctx2 := context.Background()

	var existingUserWithPhone models.User
	err = userCollection.FindOne(ctx2, bson.M{"phone": signupRequest.Phone}).Decode(&existingUserWithPhone)
	if err == nil {
		return c.JSON(http.StatusConflict, models.Response{
			Status:  http.StatusConflict,
			Message: "Phone number already registered",
		})
	} else if err != mongo.ErrNoDocuments {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Database error while checking phone number",
		})
	}

	// Check if email already exists
	var existingUser models.User
	err = userCollection.FindOne(ctx2, bson.M{"email": signupRequest.Email}).Decode(&existingUser)
	if err == nil {
		return c.JSON(http.StatusConflict, models.Response{
			Status:  http.StatusConflict,
			Message: "Email already exists",
		})
	} else if err != mongo.ErrNoDocuments {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Database error while checking email",
		})
	}

	// Process logo upload if provided
	logoPath := ""
	file, err := c.FormFile("logo")
	if err == nil && file != nil {
		uploadDir := "uploads/wholesaler"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to create upload directory: " + err.Error(),
			})
		}

		ext := filepath.Ext(file.Filename)
		filename := fmt.Sprintf("%s%s", uuid.New().String(), ext)
		filePath := filepath.Join(uploadDir, filename)

		src, err := file.Open()
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to open uploaded file: " + err.Error(),
			})
		}
		defer src.Close()

		dst, err := os.Create(filePath)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to create destination file: " + err.Error(),
			})
		}
		defer dst.Close()

		if _, err = io.Copy(dst, src); err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to save file: " + err.Error(),
			})
		}

		logoPath = filePath
		signupRequest.LogoPath = logoPath
	}

	// Store OTP and signup data in database
	otpCollection := ac.DB.Database("barrim").Collection("phone_otps")
	otp := generateAuthOTP()
	fmt.Printf("🔐 WHOLESALER SIGNUP OTP: %s for phone: %s\n", otp, signupRequest.Phone)
	otpDoc := models.PhoneOTP{
		Phone:      signupRequest.Phone,
		OTP:        otp,
		SignupData: &signupRequest,
		ExpiresAt:  time.Now().Add(10 * time.Minute),
		Verified:   false,
	}

	// Delete any existing OTPs for this phone number
	_, err = otpCollection.DeleteMany(context.Background(), bson.M{"phone": signupRequest.Phone})
	if err != nil {
		ac.logger.Printf("Failed to delete existing OTPs: %v", err)
	}

	// Insert new OTP
	_, err = otpCollection.InsertOne(context.Background(), otpDoc)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to store OTP",
		})
	}

	// Send OTP via SMS using Twilio SMS API
	smsErr := ac.sendOTP(signupRequest.Phone, otp)
	if smsErr != nil {
		ac.logger.Printf("SMS OTP failed: %v", smsErr)
	}

	// Return response indicating OTP sent, no user or token yet
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "OTP sent successfully. Please verify your phone number to complete registration.",
		Data: map[string]interface{}{
			"phone":     signupRequest.Phone,
			"expiresAt": otpDoc.ExpiresAt,
			"method":    "sms",
		},
	})
}

func (ac *AuthController) SignupServiceProviderWithLogo(ctx echo.Context) error {
	// Parse the multipart form
	err := ctx.Request().ParseMultipartForm(10 << 20) // 10 MB max
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Failed to parse form data: " + err.Error(),
		})
	}

	// Get form data
	userData := ctx.FormValue("userData")
	if userData == "" {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "User data is required",
		})
	}

	// Parse JSON data from form
	var signupRequest models.SignupRequest
	if err := json.Unmarshal([]byte(userData), &signupRequest); err != nil {
		// Handle type mismatch for yearsExperience
		if strings.Contains(err.Error(), "yearsExperience") {
			var rawData map[string]interface{}
			if jsonErr := json.Unmarshal([]byte(userData), &rawData); jsonErr == nil {
				if spInfo, ok := rawData["serviceProviderInfo"].(map[string]interface{}); ok {
					if yearsExp, ok := spInfo["yearsExperience"].(string); ok {
						if yearsExpInt, err := strconv.Atoi(yearsExp); err == nil {
							spInfo["yearsExperience"] = yearsExpInt
						}
					}
				}
				fixedData, _ := json.Marshal(rawData)
				if err := json.Unmarshal(fixedData, &signupRequest); err != nil {
					return ctx.JSON(http.StatusBadRequest, models.Response{
						Status:  http.StatusBadRequest,
						Message: "Invalid JSON format in userData after fixing: " + err.Error(),
					})
				}
			} else {
				return ctx.JSON(http.StatusBadRequest, models.Response{
					Status:  http.StatusBadRequest,
					Message: "Invalid JSON format in userData: " + err.Error(),
				})
			}
		} else {
			return ctx.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Invalid JSON format in userData: " + err.Error(),
			})
		}
	}

	// Validate service provider specific data
	if signupRequest.UserType != "serviceProvider" {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user type for this endpoint",
		})
	}

	// Process service provider info
	if signupRequest.ServiceProviderInfo != nil {
		signupRequest.ServiceProviderInfo.NormalizeYearsExperience()

		// Process "apply to all months" functionality
		if signupRequest.ServiceProviderInfo.ApplyToAllMonths && len(signupRequest.ServiceProviderInfo.AvailableDays) > 0 {
			availableWeekdays := make([]string, 0)
			weekdayMap := make(map[string]bool)

			for _, dateStr := range signupRequest.ServiceProviderInfo.AvailableDays {
				t, err := time.Parse("2006-01-02", dateStr)
				if err == nil {
					weekday := t.Weekday().String()
					weekdayMap[weekday] = true
				}
			}

			for weekday := range weekdayMap {
				availableWeekdays = append(availableWeekdays, weekday)
			}

			// Sort weekdays
			sort.Slice(availableWeekdays, func(i, j int) bool {
				weekdays := map[string]int{
					"Sunday": 0, "Monday": 1, "Tuesday": 2, "Wednesday": 3,
					"Thursday": 4, "Friday": 5, "Saturday": 6,
				}
				return weekdays[availableWeekdays[i]] < weekdays[availableWeekdays[j]]
			})

			signupRequest.ServiceProviderInfo.AvailableWeekdays = availableWeekdays
			startDate := time.Now()
			endDate := startDate.AddDate(1, 0, 0)
			signupRequest.ServiceProviderInfo.AvailableDays = signupRequest.ServiceProviderInfo.RegenerateAvailableDaysFromWeekdays(startDate, endDate)
		}
	}

	// Validate required fields
	if signupRequest.Email == "" || signupRequest.Password == "" || signupRequest.FullName == "" || signupRequest.Phone == "" {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Email, password, full name, and phone are required",
		})
	}

	// Sanitize inputs
	email, err := utils.SanitizeEmail(signupRequest.Email)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid email format",
		})
	}
	signupRequest.Email = email

	phone, err := utils.SanitizePhone(signupRequest.Phone)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid phone number format",
		})
	}
	signupRequest.Phone = phone

	signupRequest.FullName = utils.SanitizeInput(signupRequest.FullName)

	// Check if phone number already exists
	userCollection := ac.DB.Database("barrim").Collection("users")
	ctx2 := context.Background()

	var existingUserWithPhone models.User
	err = userCollection.FindOne(ctx2, bson.M{"phone": signupRequest.Phone}).Decode(&existingUserWithPhone)
	if err == nil {
		return ctx.JSON(http.StatusConflict, models.Response{
			Status:  http.StatusConflict,
			Message: "Phone number already registered",
		})
	} else if err != mongo.ErrNoDocuments {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Database error while checking phone number",
		})
	}

	// Check if email already exists
	var existingUser models.User
	err = userCollection.FindOne(ctx2, bson.M{"email": signupRequest.Email}).Decode(&existingUser)
	if err == nil {
		return ctx.JSON(http.StatusConflict, models.Response{
			Status:  http.StatusConflict,
			Message: "Email already exists",
		})
	} else if err != mongo.ErrNoDocuments {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Database error while checking email",
		})
	}

	// Process logo upload if provided
	logoPath := ""
	file, err := ctx.FormFile("logo")
	if err == nil && file != nil {
		uploadDir := "uploads/serviceprovider"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to create upload directory: " + err.Error(),
			})
		}

		ext := filepath.Ext(file.Filename)
		filename := fmt.Sprintf("%s%s", uuid.New().String(), ext)
		filePath := filepath.Join(uploadDir, filename)

		src, err := file.Open()
		if err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to open uploaded file: " + err.Error(),
			})
		}
		defer src.Close()

		dst, err := os.Create(filePath)
		if err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to create destination file: " + err.Error(),
			})
		}
		defer dst.Close()

		if _, err = io.Copy(dst, src); err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to save file: " + err.Error(),
			})
		}

		logoPath = filePath
		signupRequest.LogoPath = logoPath
	}

	// Instead, store OTP and signup data in database (like company/wholesaler)
	otpCollection := ac.DB.Database("barrim").Collection("phone_otps")
	otp := generateAuthOTP()
	fmt.Printf("🔐 SERVICE PROVIDER SIGNUP OTP: %s for phone: %s\n", otp, signupRequest.Phone)
	otpDoc := models.PhoneOTP{
		Phone:      signupRequest.Phone,
		OTP:        otp,
		SignupData: &signupRequest,
		ExpiresAt:  time.Now().Add(10 * time.Minute),
		Verified:   false,
	}

	// Delete any existing OTPs for this phone number
	_, err = otpCollection.DeleteMany(context.Background(), bson.M{"phone": signupRequest.Phone})
	if err != nil {
		ac.logger.Printf("Failed to delete existing OTPs: %v", err)
	}

	// Insert new OTP
	_, err = otpCollection.InsertOne(context.Background(), otpDoc)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to store OTP",
		})
	}

	// Send OTP via SMS using Twilio SMS API
	smsErr := ac.sendOTP(signupRequest.Phone, otp)
	if smsErr != nil {
		ac.logger.Printf("SMS OTP failed: %v", smsErr)
	}

	// Return response indicating OTP sent, no user or token yet
	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "OTP sent successfully. Please verify your phone number to complete registration.",
		Data: map[string]interface{}{
			"phone":     signupRequest.Phone,
			"expiresAt": otpDoc.ExpiresAt,
			"method":    "sms",
		},
	})
}

// Login handler
func (ac *AuthController) Login(c echo.Context) error {
	// Create a context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Get user collection
	collection := config.GetCollection(ac.DB, "users")

	// Parse request body
	var loginReq models.LoginRequest
	if err := c.Bind(&loginReq); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request body",
		})
	}

	identifier := loginReq.Email
	if identifier == "" {
		identifier = loginReq.Phone
	}

	ac.loginAttemptsMu.RLock()
	attempts, exists := ac.loginAttempts[identifier]
	ac.loginAttemptsMu.RUnlock()

	if exists && attempts.count >= 5 && time.Since(attempts.lastAttempt) < 30*time.Minute {
		return c.JSON(http.StatusTooManyRequests, models.Response{
			Status:  http.StatusTooManyRequests,
			Message: "Too many failed login attempts. Please try again later.",
		})
	}

	// Validate that either email or phone is provided
	if loginReq.Email == "" && loginReq.Phone == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Either email or phone number is required",
		})
	}

	// Sanitize inputs
	if loginReq.Email != "" {
		email, err := utils.SanitizeEmail(loginReq.Email)
		if err != nil {
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Invalid email format",
			})
		}
		loginReq.Email = email
	}

	if loginReq.Phone != "" {
		phone, err := utils.SanitizePhone(loginReq.Phone)
		if err != nil {
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Invalid phone number format",
			})
		}
		loginReq.Phone = phone
	}

	// Sanitize password (only basic sanitization, don't modify the actual password)
	loginReq.Password = utils.SanitizeInput(loginReq.Password)

	// Find user by email or phone
	var user models.User
	var err error

	if loginReq.Email != "" {
		err = collection.FindOne(ctx, bson.M{"email": loginReq.Email}).Decode(&user)
	} else {
		err = collection.FindOne(ctx, bson.M{"phone": loginReq.Phone}).Decode(&user)
	}

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusUnauthorized, models.Response{
				Status:  http.StatusUnauthorized,
				Message: "Invalid credentials",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to find user",
		})
	}

	// Check password
	err = utils.CheckPassword(loginReq.Password, user.Password)
	if err != nil {
		// Increment failed attempt counter
		ac.loginAttemptsMu.Lock()
		if !exists {
			ac.loginAttempts[identifier] = struct {
				count       int
				lastAttempt time.Time
			}{count: 1, lastAttempt: time.Now()}
		} else {
			ac.loginAttempts[identifier] = struct {
				count       int
				lastAttempt time.Time
			}{count: attempts.count + 1, lastAttempt: time.Now()}
		}
		ac.loginAttemptsMu.Unlock()

		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid credentials",
		})
	}

	ac.loginAttemptsMu.Lock()
	delete(ac.loginAttempts, identifier)
	ac.loginAttemptsMu.Unlock()

	// Generate JWT token
	token, refreshToken, err := middleware.GenerateJWT(user.ID.Hex(), user.Email, user.UserType)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to generate token",
		})
	}

	// Update user's active status
	filter := bson.M{"_id": user.ID}
	update := bson.M{"$set": bson.M{"isActive": true, "updatedAt": time.Now()}}

	_, err = collection.UpdateOne(ctx, filter, update)
	if err != nil {
		// Log the error but don't fail the login
		ac.logger.Printf("Failed to update user active status: %v", err)
	}

	// Remove sensitive fields before returning the user object
	user.Password = ""
	user.OTPInfo = nil

	// Handle "Remember Me" functionality
	var rememberMeToken string
	if loginReq.RememberMe {
		// Get Redis client
		redisClient := config.GetRedisClient()
		if redisClient != nil {
			// Generate remember me token
			rememberMeToken, err = utils.GenerateRememberMeToken()
			if err == nil {
				// Create remembered credentials
				credentials := utils.RememberedCredentials{
					Email:      user.Email,
					Phone:      user.Phone,
					UserType:   user.UserType,
					UserID:     user.ID.Hex(),
					ExpiresAt:  time.Now().AddDate(0, 1, 0), // 1 month expiration
					DeviceInfo: c.Request().UserAgent(),
				}

				// Store in Redis
				err = utils.StoreRememberedCredentials(redisClient, rememberMeToken, credentials, 30*24*time.Hour) // 30 days
				if err != nil {
					ac.logger.Printf("Failed to store remember me credentials: %v", err)
					// Don't fail login if remember me fails
					rememberMeToken = ""
				}
			}
		}
	}

	// Prepare response data
	responseData := map[string]interface{}{
		"token":        token,
		"refreshToken": refreshToken,
		"user":         user, // Return the full user object (without password and OTP)
	}

	// Add remember me token if available
	if rememberMeToken != "" {
		responseData["rememberMeToken"] = rememberMeToken
	}

	// Return the token and more complete user info
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Login successful",
		Data:    responseData,
	})
}

func (ac *AuthController) Logout(c echo.Context) error {
	// Get user ID from JWT token
	userID := middleware.GetUserIDFromToken(c)

	if userID == "" {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid token",
		})
	}

	// Get the actual token string for blacklisting
	userToken := c.Get("user")
	if userToken == nil {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "No token found",
		})
	}

	token, ok := userToken.(*jwt.Token)
	if !ok {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid token type",
		})
	}

	// Extract token string and claims
	tokenString := token.Raw
	claims, ok := token.Claims.(*middleware.JwtCustomClaims)
	if !ok {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid token claims",
		})
	}

	// Convert string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	// Update user's active status and last logout time
	collection := config.GetCollection(ac.DB, "users")
	ctx := context.Background()

	// Get current time for logout tracking
	now := time.Now()

	// Calculate token expiration time for blacklist
	var tokenExpiry time.Time
	if claims.ExpiresAt > 0 {
		tokenExpiry = time.Unix(claims.ExpiresAt, 0)
	} else {
		// If no expiration, set to 24 hours from now
		tokenExpiry = now.Add(24 * time.Hour)
	}

	// Blacklist the current token
	middleware.BlacklistToken(tokenString, tokenExpiry)

	// Update user record with logout information
	filter := bson.M{"_id": objID}
	update := bson.M{
		"$set": bson.M{
			"isActive":       false,
			"updatedAt":      now,
			"lastLogoutAt":   now,
			"lastActivityAt": now,
		},
		"$inc": bson.M{
			"logoutCount": 1, // Track logout frequency
		},
	}

	_, err = collection.UpdateOne(ctx, filter, update)
	if err != nil {
		ac.logger.Printf("Failed to update user logout status: %v", err)
		// Don't fail the logout if database update fails
		// The token is already blacklisted
	}

	// Log the logout event for security audit
	ac.logger.Printf("User logout - UserID: %s, UserType: %s, Email: %s, IP: %s, UserAgent: %s",
		userID, claims.UserType, claims.Email, c.RealIP(), c.Request().UserAgent())

	// Create audit log entry
	auditLog := bson.M{
		"userId":      userID,
		"userType":    claims.UserType,
		"email":       claims.Email,
		"action":      "logout",
		"ipAddress":   c.RealIP(),
		"userAgent":   c.Request().UserAgent(),
		"timestamp":   now,
		"tokenExpiry": tokenExpiry,
	}

	// Store audit log in database
	auditCollection := ac.DB.Database("barrim").Collection("audit_logs")
	_, err = auditCollection.InsertOne(ctx, auditLog)
	if err != nil {
		ac.logger.Printf("Failed to log audit entry: %v", err)
		// Don't fail the logout if audit logging fails
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Logged out successfully",
		Data: map[string]interface{}{
			"logoutTime": now,
			"message":    "Token has been invalidated and cannot be used again",
		},
	})
}

// ForceLogout logs out user from all devices by invalidating all tokens
func (ac *AuthController) ForceLogout(c echo.Context) error {
	// Get user ID from JWT token
	userID := middleware.GetUserIDFromToken(c)

	if userID == "" {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid token",
		})
	}

	// Convert string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	// Get current time
	now := time.Now()

	// Update user record to invalidate all sessions
	collection := config.GetCollection(ac.DB, "users")
	ctx := context.Background()

	// Generate a new session token to invalidate all previous tokens
	newSessionToken := RandomStringGenerator(32, "alphanumeric")

	filter := bson.M{"_id": objID}
	update := bson.M{
		"$set": bson.M{
			"isActive":           false,
			"updatedAt":          now,
			"lastLogoutAt":       now,
			"lastActivityAt":     now,
			"sessionInvalidated": true,
			"sessionToken":       newSessionToken, // New token to invalidate all previous sessions
		},
		"$inc": bson.M{
			"logoutCount": 1,
		},
	}

	_, err = collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update user status",
		})
	}

	// Get user info for logging
	var user models.User
	err = collection.FindOne(ctx, bson.M{"_id": objID}).Decode(&user)
	if err != nil {
		ac.logger.Printf("Failed to get user info for force logout: %v", err)
	}

	// Log the force logout event
	ac.logger.Printf("Force logout - UserID: %s, UserType: %s, Email: %s, IP: %s, UserAgent: %s",
		userID, user.UserType, user.Email, c.RealIP(), c.Request().UserAgent())

	// Create audit log entry for force logout
	auditLog := bson.M{
		"userId":       userID,
		"userType":     user.UserType,
		"email":        user.Email,
		"action":       "force_logout",
		"ipAddress":    c.RealIP(),
		"userAgent":    c.Request().UserAgent(),
		"timestamp":    now,
		"sessionToken": newSessionToken,
	}

	// Store audit log in database
	auditCollection := ac.DB.Database("barrim").Collection("audit_logs")
	_, err = auditCollection.InsertOne(ctx, auditLog)
	if err != nil {
		ac.logger.Printf("Failed to log force logout audit entry: %v", err)
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Logged out from all devices successfully",
		Data: map[string]interface{}{
			"logoutTime": now,
			"message":    "All sessions have been invalidated",
		},
	})
}

// GetLogoutHistory returns the logout history for a user
func (ac *AuthController) GetLogoutHistory(c echo.Context) error {
	// Get user ID from JWT token
	userID := middleware.GetUserIDFromToken(c)

	if userID == "" {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid token",
		})
	}

	ctx := context.Background()
	auditCollection := ac.DB.Database("barrim").Collection("audit_logs")

	// Get logout history for this user
	filter := bson.M{
		"userId": userID,
		"action": bson.M{"$in": []string{"logout", "force_logout"}},
	}

	opts := options.Find().SetSort(bson.M{"timestamp": -1}).SetLimit(10)

	cursor, err := auditCollection.Find(ctx, filter, opts)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve logout history",
		})
	}
	defer cursor.Close(ctx)

	var logoutHistory []bson.M
	if err = cursor.All(ctx, &logoutHistory); err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to process logout history",
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Logout history retrieved successfully",
		Data:    logoutHistory,
	})
}

// GoogleUser represents the user data received from Google authentication

// GoogleLogin handles Google authentication
func (ac *AuthController) GoogleLogin(c echo.Context) error {
	// Create Google auth service
	googleAuthService := services.NewGoogleAuthService(ac.DB)

	// Parse request body
	var googleUser services.GoogleUser
	if err := c.Bind(&googleUser); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request body",
		})
	}

	// Validate required fields
	if googleUser.Email == "" || googleUser.GoogleID == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Email and Google ID are required",
		})
	}

	// Log the request details for debugging
	ac.logger.Printf("Google login request: email=%s, name=%s",
		googleUser.Email, googleUser.DisplayName)

	// Authenticate with Google
	userData, err := googleAuthService.AuthenticateUser(&googleUser)
	if err != nil {
		ac.logger.Printf("Google authentication error: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Authentication failed: " + err.Error(),
		})
	}

	// Return success response
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Login successful",
		Data:    userData,
	})
}

// ServeImage serves image files from the uploads directory
func ServeImage(c echo.Context) error {
	// Get the image path from URL parameter
	filename := c.Param("filename")

	// Sanitize the filename to prevent directory traversal attacks
	filename = filepath.Base(filename)

	// Construct the full path to the image
	path := filepath.Join("uploads", filename)

	// Check if the file exists
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": "Image not found",
		})
	}

	// Serve the file
	return c.File(path)
}

func isValidE164(phone string) bool {
	return regexp.MustCompile(`^\+[1-9]\d{1,14}$`).MatchString(phone)
}

// VerifyOTP verifies the OTP and completes user registration
func (ac *AuthController) VerifyOTP(c echo.Context) error {
	var req struct {
		Phone string `json:"phone"`
		OTP   string `json:"otp"`
	}

	if err := c.Bind(&req); err != nil {
		ac.logger.Printf("OTP verification bind error: %v", err)
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request",
		})
	}

	// Sanitize inputs
	req.Phone = utils.SanitizeInput(req.Phone)
	req.OTP = utils.SanitizeInput(req.OTP)

	ctx := context.Background()
	otpCollection := ac.DB.Database("barrim").Collection("phone_otps")

	ac.logger.Printf("Verifying OTP for phone: %s", req.Phone)

	// Find the OTP document
	var otpDoc models.PhoneOTP
	err := otpCollection.FindOne(ctx, bson.M{
		"phone": req.Phone,
		"otp":   req.OTP,
	}).Decode(&otpDoc)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			ac.logger.Printf("Invalid OTP for phone: %s", req.Phone)
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Invalid OTP",
			})
		}
		ac.logger.Printf("Database error during OTP verification: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Database error",
		})
	}

	if !strings.HasPrefix(req.Phone, "+") {
		req.Phone = "+" + req.Phone
	}

	// Ensure phone number is in E.164 format
	if !isValidE164(req.Phone) {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid phone number format",
		})
	}

	// Check if OTP is expired
	if time.Now().After(otpDoc.ExpiresAt) {
		ac.logger.Printf("Expired OTP for phone: %s", req.Phone)
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "OTP expired",
		})
	}

	// Create the user account
	signupData := otpDoc.SignupData
	if signupData == nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid signup data",
		})
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(signupData.Password), bcrypt.DefaultCost)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error hashing password",
		})
	}

	// Create user first
	userID := primitive.NewObjectID()

	// Generate referral code for all types
	referralCode := generateReferralCode()

	// If a referral code was provided, use it instead of generating a new one
	if signupData.ReferralCode != "" {
		referralCode = signupData.ReferralCode
	}

	user := models.User{
		ID:              userID,
		Email:           signupData.Email,
		Password:        string(hashedPassword),
		FullName:        signupData.FullName,
		Phone:           signupData.Phone,
		UserType:        signupData.UserType,
		DateOfBirth:     signupData.DateOfBirth,
		Gender:          signupData.Gender,
		ProfilePic:      signupData.ProfilePic, // Optional field
		ReferralCode:    referralCode,
		InterestedDeals: signupData.InterestedDeals,
		Location:        signupData.Location,
		Status:          "pending", // Set to pending until manager approval
		PhoneVerified:   true,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	// If it's a company signup, create company record first
	if signupData.UserType == "company" && signupData.CompanyData != nil {
		// Create the main branch for the company
		branch := models.Branch{
			ID:          primitive.NewObjectID(),
			Name:        signupData.CompanyData.BusinessName,
			Location:    signupData.CompanyData.Address,
			Phone:       signupData.Phone,
			Category:    signupData.CompanyData.Category,
			SubCategory: signupData.CompanyData.SubCategory,
			Images:      []string{},
			Videos:      []string{},
			Status:      "inactive", // Set to inactive until subscription approval
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		}
		if signupData.CompanyData.Logo != "" {
			branch.Images = append(branch.Images, signupData.CompanyData.Logo)
		}

		company := models.Company{
			ID:           primitive.NewObjectID(),
			UserID:       userID,
			BusinessName: signupData.CompanyData.BusinessName,
			Category:     signupData.CompanyData.Category,
			SubCategory:  signupData.CompanyData.SubCategory,
			ReferralCode: referralCode, // Set generated referral code
			ContactInfo: models.ContactInfo{
				Phone:   signupData.Phone,
				Address: signupData.CompanyData.Address,
			},
			AdditionalPhones: signupData.CompanyData.Phones, // Store additional phones
			AdditionalEmails: signupData.CompanyData.Emails, // Store additional emails
			LogoURL:          signupData.CompanyData.Logo,
			Branches:         []models.Branch{branch},
			Points:           0,
			Balance:          0,
			CreatedBy:        userID,
			CreatedAt:        time.Now(),
			UpdatedAt:        time.Now(),
		}

		// Insert company
		_, err = ac.DB.Database("barrim").Collection("companies").InsertOne(ctx, company)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to create company record",
			})
		}

		// Update user with company ID and referral code
		user.CompanyID = &company.ID
		user.ReferralCode = referralCode

		// If it's a company signup and a referral code was provided, handle the referral
		if signupData.CompanyData.ReferralCode != "" {
			companiesCollection := ac.DB.Database("barrim").Collection("companies")
			var referrerCompany models.Company
			err := companiesCollection.FindOne(ctx, bson.M{"referralCode": signupData.CompanyData.ReferralCode}).Decode(&referrerCompany)
			if err == nil && referrerCompany.ID != company.ID {
				// Increment points for the referring company
				update := bson.M{
					"$inc": bson.M{"points": 10}, // or whatever amount of points is appropriate
					"$push": bson.M{
						"referrals": company.ID,
					},
				}
				_, _ = companiesCollection.UpdateOne(ctx, bson.M{"_id": referrerCompany.ID}, update)
			}
		}
	}

	// If it's a wholesaler signup, create wholesaler record first
	if signupData.UserType == "wholesaler" && signupData.WholesalerData != nil {
		wholesalerID := primitive.NewObjectID()

		// Create the main branch for the wholesaler (embedded in wholesaler document)
		branch := models.Branch{
			ID:          primitive.NewObjectID(),
			Name:        signupData.WholesalerData.BusinessName,
			Location:    signupData.WholesalerData.Address,
			Phone:       signupData.Phone,
			Category:    signupData.WholesalerData.Category,
			SubCategory: signupData.WholesalerData.SubCategory,
			Images:      []string{},
			Videos:      []string{},
			Status:      "inactive", // Set to pending until manager approval
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		}

		// Add description and social media info to branch
		if signupData.WholesalerData.ContactInfo != nil && signupData.WholesalerData.ContactInfo.Website != "" {
			branch.Description = signupData.WholesalerData.ContactInfo.Website
		}
		if signupData.WholesalerData.ContactInfo != nil && signupData.WholesalerData.ContactInfo.WhatsApp != "" {
			if branch.Description != "" {
				branch.Description += " | WhatsApp: " + signupData.WholesalerData.ContactInfo.WhatsApp
			} else {
				branch.Description = "WhatsApp: " + signupData.WholesalerData.ContactInfo.WhatsApp
			}
		}
		if signupData.WholesalerData.SocialMedia != nil {
			if signupData.WholesalerData.SocialMedia.Facebook != "" {
				if branch.Description != "" {
					branch.Description += " | Facebook: " + signupData.WholesalerData.SocialMedia.Facebook
				} else {
					branch.Description = "Facebook: " + signupData.WholesalerData.SocialMedia.Facebook
				}
			}
			if signupData.WholesalerData.SocialMedia.Instagram != "" {
				if branch.Description != "" {
					branch.Description += " | Instagram: " + signupData.WholesalerData.SocialMedia.Instagram
				} else {
					branch.Description = "Instagram: " + signupData.WholesalerData.SocialMedia.Instagram
				}
			}
		}
		if signupData.LogoPath != "" {
			branch.Images = append(branch.Images, signupData.LogoPath)
		}

		// Prepare additional emails array - include the main user email
		additionalEmails := []string{signupData.Email}
		if signupData.WholesalerData.Emails != nil {
			additionalEmails = append(additionalEmails, signupData.WholesalerData.Emails...)
		}

		// Prepare additional phones array
		additionalPhones := []string{}
		if signupData.WholesalerData.Phones != nil {
			additionalPhones = append(additionalPhones, signupData.WholesalerData.Phones...)
		}

		// Initialize ContactInfo and SocialMedia with safe defaults
		contactInfo := models.ContactInfo{
			Phone:   signupData.Phone,
			Address: signupData.WholesalerData.Address,
		}
		if signupData.WholesalerData.ContactInfo != nil {
			if signupData.WholesalerData.ContactInfo.WhatsApp != "" {
				contactInfo.WhatsApp = signupData.WholesalerData.ContactInfo.WhatsApp
			}
			if signupData.WholesalerData.ContactInfo.Website != "" {
				contactInfo.Website = signupData.WholesalerData.ContactInfo.Website
			}
		}

		socialMedia := models.SocialMedia{}
		if signupData.WholesalerData.SocialMedia != nil {
			if signupData.WholesalerData.SocialMedia.Facebook != "" {
				socialMedia.Facebook = signupData.WholesalerData.SocialMedia.Facebook
			}
			if signupData.WholesalerData.SocialMedia.Instagram != "" {
				socialMedia.Instagram = signupData.WholesalerData.SocialMedia.Instagram
			}
		}

		wholesaler := models.Wholesaler{
			ID:               wholesalerID,
			UserID:           userID,
			BusinessName:     signupData.WholesalerData.BusinessName,
			Category:         signupData.WholesalerData.Category,
			SubCategory:      signupData.WholesalerData.SubCategory,
			Phone:            signupData.Phone,
			AdditionalPhones: additionalPhones,
			AdditionalEmails: additionalEmails,
			ContactInfo:      contactInfo,
			SocialMedia:      socialMedia,
			ReferralCode:     referralCode,
			Points:           0,
			Referrals:        []primitive.ObjectID{},
			Branches:         []models.Branch{branch},
			ContactPerson:    signupData.FullName, // Set contact person to full name
			Balance:          0,                   // Initialize balance to 0
			CreationRequest:  "pending",           // Set creation request to pending
			Sponsorship:      false,               // Initialize sponsorship to false
			CreatedBy:        userID,              // Set created by to user ID
			CreatedAt:        time.Now(),
			UpdatedAt:        time.Now(),
		}

		// Insert wholesaler (with embedded branch)
		_, err = ac.DB.Database("barrim").Collection("wholesalers").InsertOne(ctx, wholesaler)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to create wholesaler record",
			})
		}

		// Update user with wholesaler ID and referral code
		user.WholesalerID = &wholesalerID
		user.ReferralCode = referralCode

		// If it's a wholesaler signup and a referral code was provided, handle the referral
		if signupData.WholesalerData != nil && signupData.WholesalerData.ReferralCode != "" {
			wholesalersCollection := ac.DB.Database("barrim").Collection("wholesalers")
			var referrerWholesaler models.Wholesaler
			err := wholesalersCollection.FindOne(ctx, bson.M{"referralCode": signupData.WholesalerData.ReferralCode}).Decode(&referrerWholesaler)
			if err == nil && referrerWholesaler.ID != wholesalerID {
				// Increment points for the referring wholesaler
				update := bson.M{
					"$inc": bson.M{"points": 5}, // 5 points for wholesaler referrals
					"$push": bson.M{
						"referrals": wholesalerID,
					},
				}
				_, _ = wholesalersCollection.UpdateOne(ctx, bson.M{"_id": referrerWholesaler.ID}, update)
			}
		}
	}

	// If it's a service provider signup, save data to serviceProviders collection
	if signupData.UserType == "serviceProvider" {
		// Don't set ServiceProviderInfo in user - it will be in serviceProviders collection
		user.LogoPath = signupData.LogoPath
		user.Location = signupData.Location
		user.ReferralCode = referralCode

		// Create a comprehensive ServiceProvider record with all data including ServiceProviderInfo
		serviceProvider := models.ServiceProvider{
			ID:                primitive.NewObjectID(),
			UserID:            userID,
			BusinessName:      user.FullName,
			Category:          "", // Will be set from ServiceProviderInfo if available
			Email:             user.Email,
			Phone:             user.Phone,
			Password:          user.Password,
			ContactPerson:     user.FullName,
			ContactPhone:      user.Phone,
			Country:           "",
			District:          "",
			City:              "",
			Street:            "",
			PostalCode:        "",
			LogoURL:           user.LogoPath,
			ContactInfo:       models.ContactInfo{},
			ReferralCode:      referralCode,
			CommissionPercent: 0,
			Sponsorship:       false,
			CreatedBy:         userID,
			CreatedAt:         time.Now(),
			UpdatedAt:         time.Now(),
			Status:            "pending", // Set to pending until manager approval
			CreationRequest:   "pending",
		}

		// Populate fields from ServiceProviderInfo if available
		if signupData.ServiceProviderInfo != nil {
			serviceProvider.Category = signupData.ServiceProviderInfo.ServiceType
			// Set referral code in ServiceProviderInfo
			signupData.ServiceProviderInfo.ReferralCode = referralCode
			// Save ServiceProviderInfo in the serviceProviders collection
			serviceProvider.ServiceProviderInfo = signupData.ServiceProviderInfo
		}

		// Populate location fields if available
		if user.Location != nil {
			serviceProvider.Country = user.Location.Country
			serviceProvider.District = user.Location.District
			serviceProvider.City = user.Location.City
			serviceProvider.Street = user.Location.Street
			serviceProvider.PostalCode = user.Location.PostalCode

			// Convert Location to Address for ContactInfo
			serviceProvider.ContactInfo = models.ContactInfo{
				Phone: user.Phone,
				Address: models.Address{
					Country:    user.Location.Country,
					District:   user.Location.District,
					City:       user.Location.City,
					Street:     user.Location.Street,
					PostalCode: user.Location.PostalCode,
					Lat:        user.Location.Lat,
					Lng:        user.Location.Lng,
				},
			}
		}

		// Insert the service provider record
		_, err = ac.DB.Database("barrim").Collection("serviceProviders").InsertOne(ctx, serviceProvider)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to create service provider record",
			})
		}

		// Update user with service provider ID (but don't include ServiceProviderInfo)
		user.ServiceProviderID = &serviceProvider.ID
	}

	// If it's a service provider signup and a referral code was provided, increment points for the referring service provider
	if signupData.UserType == "serviceProvider" && signupData.ReferralCode != "" {
		usersCollection := ac.DB.Database("barrim").Collection("users")
		var referrer models.User
		err := usersCollection.FindOne(ctx, bson.M{"referralCode": signupData.ReferralCode, "userType": "serviceProvider"}).Decode(&referrer)
		if err == nil && referrer.ID != userID {
			// Increment points for the referring service provider (prevent self-referral)
			_, _ = usersCollection.UpdateOne(ctx, bson.M{"_id": referrer.ID}, bson.M{"$inc": bson.M{"points": 10}})
		}
	}

	// Insert user
	_, err = ac.DB.Database("barrim").Collection("users").InsertOne(ctx, user)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to create user account",
		})
	}

	// Generate JWT token after all records are created
	token, refreshToken, err := middleware.GenerateJWT(user.ID.Hex(), user.Email, user.UserType)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to generate authentication tokens",
		})
	}

	// Remove password from response
	user.Password = ""

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Phone verified successfully",
		Data: map[string]interface{}{
			"user":         user,
			"token":        token,
			"refreshToken": refreshToken,
		},
	})
}

// ResendOTP resends the OTP to the user's phone
func (ac *AuthController) ResendOTP(c echo.Context) error {
	var req struct {
		Phone string `json:"phone"`
	}

	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request",
		})
	}

	ctx := context.Background()
	otpCollection := ac.DB.Database("barrim").Collection("phone_otps")

	// Find existing signup data
	var otpDoc models.PhoneOTP
	err := otpCollection.FindOne(ctx, bson.M{"phone": req.Phone}).Decode(&otpDoc)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "No pending verification found for this phone number",
		})
	}

	// Generate new OTP - Fix: Call the correctly named function
	newOTP := generateAuthOTP()
	fmt.Printf("🔄 RESEND OTP: %s for phone: %s\n", newOTP, req.Phone)
	expiresAt := time.Now().Add(10 * time.Minute)

	// Update OTP document
	_, err = otpCollection.UpdateOne(
		ctx,
		bson.M{"phone": req.Phone},
		bson.M{
			"$set": bson.M{
				"otp":       newOTP,
				"expiresAt": expiresAt,
			},
		},
	)

	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update OTP",
		})
	}

	// Send new OTP with improved error handling
	err = ac.sendOTP(req.Phone, newOTP)
	if err != nil {
		ac.logger.Printf("Failed to send OTP: %v", err)

		// More descriptive error message
		errMsg := "Failed to send OTP"
		if strings.Contains(err.Error(), "auth") {
			errMsg = "Authentication error with SMS provider"
		} else if strings.Contains(err.Error(), "credentials") {
			errMsg = "SMS provider credentials not properly configured"
		}

		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: errMsg,
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "OTP resent successfully",
		Data: map[string]interface{}{
			"phone":     req.Phone,
			"expiresAt": expiresAt,
		},
	})
}

// cleanupExpiredOTPs deletes all expired OTPs from the database
func (ac *AuthController) cleanupExpiredOTPs() error {
	ctx := context.Background()
	otpCollection := ac.DB.Database("barrim").Collection("phone_otps")

	// Delete all OTPs that have expired
	result, err := otpCollection.DeleteMany(ctx, bson.M{
		"expiresAt": bson.M{"$lt": time.Now()},
	})

	if err != nil {
		ac.logger.Printf("Error cleaning up expired OTPs: %v", err)
		return err
	}

	if result.DeletedCount > 0 {
		ac.logger.Printf("Cleaned up %d expired OTPs", result.DeletedCount)
	}

	return nil
}

// startOTPCleanupRoutine starts a background routine to clean up expired OTPs
func (ac *AuthController) startOTPCleanupRoutine() {
	ticker := time.NewTicker(5 * time.Minute) // Run every 5 minutes
	defer ticker.Stop()

	// Run cleanup immediately on startup
	if err := ac.cleanupExpiredOTPs(); err != nil {
		ac.logger.Printf("Initial OTP cleanup failed: %v", err)
	}

	for range ticker.C {
		if err := ac.cleanupExpiredOTPs(); err != nil {
			ac.logger.Printf("OTP cleanup failed: %v", err)
		}
	}
}

func (ac *AuthController) startLoginAttemptCleanupRoutine() {
	ticker := time.NewTicker(1 * time.Hour)
	defer ticker.Stop()

	for range ticker.C {
		ac.loginAttemptsMu.Lock()
		now := time.Now()
		for identifier, attempts := range ac.loginAttempts {
			if now.Sub(attempts.lastAttempt) > 30*time.Minute {
				delete(ac.loginAttempts, identifier)
			}
		}
		ac.loginAttemptsMu.Unlock()
	}
}

func (ac *AuthController) startRememberMeCleanupRoutine() {
	ticker := time.NewTicker(6 * time.Hour) // Run every 6 hours
	defer ticker.Stop()

	// Run cleanup immediately on startup
	if err := ac.cleanupExpiredRememberMeTokens(); err != nil {
		ac.logger.Printf("Initial remember me cleanup failed: %v", err)
	}

	for range ticker.C {
		if err := ac.cleanupExpiredRememberMeTokens(); err != nil {
			ac.logger.Printf("Remember me cleanup failed: %v", err)
		}
	}
}

func (ac *AuthController) cleanupExpiredRememberMeTokens() error {
	redisClient := config.GetRedisClient()
	if redisClient == nil {
		return fmt.Errorf("Redis client not available")
	}

	return utils.CleanupExpiredRememberMeTokens(redisClient)
}

// CheckEmailOrPhoneExists checks if an email or phone exists in users, companies, wholesalers, or service providers
func (ac *AuthController) CheckEmailOrPhoneExists(c echo.Context) error {
	var req struct {
		Email string `json:"email"`
		Phone string `json:"phone"`
	}
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request",
		})
	}

	ctx := context.Background()
	db := ac.DB.Database("barrim")

	// Check in users
	userFilter := bson.M{}
	if req.Email != "" {
		userFilter["email"] = req.Email
	}
	if req.Phone != "" {
		userFilter["phone"] = req.Phone
	}
	userExists := db.Collection("users").FindOne(ctx, userFilter).Err() == nil

	// Check in companies
	companyFilter := bson.M{}
	if req.Email != "" {
		companyFilter["additionalEmails"] = req.Email
	}
	if req.Phone != "" {
		companyFilter["additionalPhones"] = req.Phone
	}
	companyExists := db.Collection("companies").FindOne(ctx, companyFilter).Err() == nil

	// Check in wholesalers
	wholesalerFilter := bson.M{}
	if req.Email != "" {
		wholesalerFilter["additionalEmails"] = req.Email
	}
	if req.Phone != "" {
		wholesalerFilter["additionalPhones"] = req.Phone
	}
	wholesalerExists := db.Collection("wholesalers").FindOne(ctx, wholesalerFilter).Err() == nil

	// Check in service providers (if you have a collection for them)
	serviceProviderFilter := bson.M{}
	if req.Email != "" {
		serviceProviderFilter["email"] = req.Email
	}
	if req.Phone != "" {
		serviceProviderFilter["phone"] = req.Phone
	}
	serviceProviderExists := db.Collection("users").FindOne(ctx, bson.M{
		"$and": []bson.M{
			{"userType": "serviceProvider"},
			serviceProviderFilter,
		},
	}).Err() == nil

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Check complete",
		Data: map[string]bool{
			"userExists":            userExists,
			"companyExists":         companyExists,
			"wholesalerExists":      wholesalerExists,
			"serviceProviderExists": serviceProviderExists,
			"exists":                userExists || companyExists || wholesalerExists || serviceProviderExists,
		},
	})
}

// ValidateToken validates a JWT token and returns user information if valid
// This endpoint can be used by the frontend to check session validity
func (ac *AuthController) ValidateToken(c echo.Context) error {
	// Get the Authorization header
	authHeader := c.Request().Header.Get("Authorization")

	// Validate the token
	response, err := utils.ValidateTokenFromHeader(authHeader, ac.DB)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error validating token: " + err.Error(),
		})
	}

	if response.Valid {
		return c.JSON(http.StatusOK, models.Response{
			Status:  http.StatusOK,
			Message: response.Message,
			Data: map[string]interface{}{
				"valid":     response.Valid,
				"user":      response.User,
				"expiresAt": response.ExpiresAt,
			},
		})
	} else {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: response.Message,
			Data: map[string]interface{}{
				"valid": response.Valid,
			},
		})
	}
}

// GetRememberedCredentials retrieves stored credentials using a remember me token
func (ac *AuthController) GetRememberedCredentials(c echo.Context) error {
	var req struct {
		RememberMeToken string `json:"rememberMeToken"`
	}

	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request",
		})
	}

	if req.RememberMeToken == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Remember me token is required",
		})
	}

	// Get Redis client
	redisClient := config.GetRedisClient()
	if redisClient == nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Remember me service unavailable",
		})
	}

	// Retrieve credentials from Redis
	credentials, err := utils.RetrieveRememberedCredentials(redisClient, req.RememberMeToken)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid or expired remember me token",
		})
	}

	// Return the remembered credentials (without sensitive data)
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Remembered credentials retrieved successfully",
		Data: map[string]interface{}{
			"email":    credentials.Email,
			"phone":    credentials.Phone,
			"userType": credentials.UserType,
			"userId":   credentials.UserID,
		},
	})
}

// RemoveRememberedCredentials removes stored credentials
func (ac *AuthController) RemoveRememberedCredentials(c echo.Context) error {
	var req struct {
		RememberMeToken string `json:"rememberMeToken"`
	}

	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request",
		})
	}

	if req.RememberMeToken == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Remember me token is required",
		})
	}

	// Get Redis client
	redisClient := config.GetRedisClient()
	if redisClient == nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Remember me service unavailable",
		})
	}

	// Remove credentials from Redis
	err := utils.RemoveRememberedCredentials(redisClient, req.RememberMeToken)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to remove remembered credentials",
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Remembered credentials removed successfully",
	})
}

// RefreshToken refreshes a JWT token if it's still valid
func (ac *AuthController) RefreshToken(c echo.Context) error {
	// Get the Authorization header
	authHeader := c.Request().Header.Get("Authorization")

	// Validate the token first
	response, err := utils.ValidateTokenFromHeader(authHeader, ac.DB)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error validating token: " + err.Error(),
		})
	}

	if !response.Valid {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: response.Message,
		})
	}

	// Generate new tokens
	token, refreshToken, err := middleware.GenerateJWT(response.User.ID.Hex(), response.User.Email, response.User.UserType)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to generate new tokens",
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Token refreshed successfully",
		Data: map[string]interface{}{
			"token":        token,
			"refreshToken": refreshToken,
			"user":         response.User,
		},
	})
}

// FirebaseLogin handles login/signup with Firebase ID token (Apple, Google, etc. via Firebase)
func (ac *AuthController) AppleSignin(c echo.Context) error {
	// Accept Apple identityToken from client
	var req struct {
		IdentityToken string `json:"identityToken"`
	}
	if err := c.Bind(&req); err != nil || req.IdentityToken == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Missing or invalid identityToken",
		})
	}

	// 1. Parse the JWT header to get the kid
	parts := strings.Split(req.IdentityToken, ".")
	if len(parts) < 2 {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid identityToken format",
		})
	}
	headerSegment := parts[0]
	headerBytes, err := base64.RawURLEncoding.DecodeString(headerSegment)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid JWT header",
		})
	}
	var header struct {
		Kid string `json:"kid"`
		Alg string `json:"alg"`
	}
	if err := json.Unmarshal(headerBytes, &header); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid JWT header JSON",
		})
	}

	// 2. Fetch Apple's public keys
	jwkSet, err := jwk.Fetch(context.Background(), "https://appleid.apple.com/auth/keys")
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to fetch Apple public keys",
		})
	}

	key, found := jwkSet.LookupKeyID(header.Kid)
	if !found {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Apple public key not found",
		})
	}

	var pubkey interface{}
	if err := key.Raw(&pubkey); err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to parse Apple public key",
		})
	}

	// 3. Parse and verify the JWT
	parsedToken, err := jwt.Parse(req.IdentityToken, func(token *jwt.Token) (interface{}, error) {
		if token.Method.Alg() != header.Alg {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return pubkey, nil
	})
	if err != nil || !parsedToken.Valid {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid or expired Apple identity token",
		})
	}

	claims, ok := parsedToken.Claims.(jwt.MapClaims)
	if !ok {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to parse token claims",
		})
	}

	// 4. Extract user info
	appleUserID, _ := claims["sub"].(string)
	email, _ := claims["email"].(string)
	emailVerified, _ := claims["email_verified"].(bool)
	if !emailVerified {
		// Apple sometimes returns string "true"
		if s, ok := claims["email_verified"].(string); ok {
			emailVerified = s == "true"
		}
	}
	if appleUserID == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Apple user ID not found in token",
		})
	}

	ctx := context.Background()
	collection := config.GetCollection(ac.DB, "users")
	var user models.User
	err = collection.FindOne(ctx, bson.M{"appleUserID": appleUserID}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Create new user
			now := time.Now()
			user = models.User{
				AppleUserID: appleUserID,
				Email:       email,
				UserType:    "user",
				Points:      0,
				CreatedAt:   now,
				UpdatedAt:   now,
			}
			result, err := collection.InsertOne(ctx, user)
			if err != nil {
				return c.JSON(http.StatusInternalServerError, models.Response{
					Status:  http.StatusInternalServerError,
					Message: "Failed to create user",
				})
			}
			user.ID = result.InsertedID.(primitive.ObjectID)
		} else {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Database error",
			})
		}
	}

	// Issue backend JWT
	tokenStr, refreshToken, err := middleware.GenerateJWT(user.ID.Hex(), user.Email, user.UserType)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to generate token",
		})
	}

	user.Password = ""
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Login successful",
		Data: map[string]interface{}{
			"token":        tokenStr,
			"refreshToken": refreshToken,
			"user":         user,
		},
	})
}

// GoogleAuthWithoutFirebase handles Google authentication without using Firebase
func (ac *AuthController) GoogleAuthWithoutFirebase(c echo.Context) error {
	var req struct {
		IDToken string `json:"idToken"`
	}
	if err := c.Bind(&req); err != nil || req.IDToken == "" {
		ac.logger.Printf("Google auth error: Missing or invalid idToken: %v", err)
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Missing idToken"})
	}

	// Parse JWT header to get kid
	parts := strings.Split(req.IDToken, ".")
	if len(parts) < 2 {
		ac.logger.Printf("Google auth error: Invalid token format, parts: %d", len(parts))
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid token format"})
	}

	headerSegment := parts[0]
	headerBytes, err := base64.RawURLEncoding.DecodeString(headerSegment)
	if err != nil {
		ac.logger.Printf("Google auth error: Failed to decode JWT header: %v", err)
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid JWT header"})
	}

	var header struct {
		Kid string `json:"kid"`
		Alg string `json:"alg"`
	}
	if err := json.Unmarshal(headerBytes, &header); err != nil {
		ac.logger.Printf("Google auth error: Failed to parse JWT header JSON: %v", err)
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid JWT header JSON"})
	}

	// Fetch Google's public keys
	ac.logger.Printf("Google auth: Fetching public keys for kid: %s", header.Kid)
	jwkSet, err := jwk.Fetch(context.Background(), "https://www.googleapis.com/oauth2/v3/certs")
	if err != nil {
		ac.logger.Printf("Google auth error: Failed to fetch Google public keys: %v", err)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to fetch Google public keys"})
	}

	key, found := jwkSet.LookupKeyID(header.Kid)
	if !found {
		ac.logger.Printf("Google auth error: Public key not found for kid: %s", header.Kid)
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Google public key not found"})
	}

	var pubkey interface{}
	if err := key.Raw(&pubkey); err != nil {
		ac.logger.Printf("Google auth error: Failed to parse Google public key: %v", err)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to parse Google public key"})
	}

	// Parse and verify the JWT
	ac.logger.Printf("Google auth: Verifying JWT token")
	parsedToken, err := jwt.Parse(req.IDToken, func(token *jwt.Token) (interface{}, error) {
		if token.Method.Alg() != header.Alg {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return pubkey, nil
	})
	if err != nil || !parsedToken.Valid {
		ac.logger.Printf("Google auth error: Invalid or expired Google token: %v", err)
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Invalid or expired Google token"})
	}

	claims, ok := parsedToken.Claims.(jwt.MapClaims)
	if !ok {
		ac.logger.Printf("Google auth error: Failed to parse token claims")
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to parse token claims"})
	}

	// Extract user info
	email, _ := claims["email"].(string)
	sub, _ := claims["sub"].(string)
	name, _ := claims["name"].(string)
	if email == "" || sub == "" {
		ac.logger.Printf("Google auth error: Missing email or sub in token. Email: %s, Sub: %s", email, sub)
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Missing email or sub in token"})
	}

	ac.logger.Printf("Google auth: Processing user - Email: %s, Sub: %s, Name: %s", email, sub, name)

	// Check if user exists, else create
	ctx := context.Background()
	collection := ac.DB.Database("barrim").Collection("users")
	var user models.User
	err = collection.FindOne(ctx, bson.M{"googleID": sub}).Decode(&user)
	if err == mongo.ErrNoDocuments {
		// Create new user
		ac.logger.Printf("Google auth: Creating new user for Google ID: %s", sub)
		user = models.User{
			ID:        primitive.NewObjectID(),
			Email:     email,
			FullName:  name,
			GoogleID:  sub,
			UserType:  "user",
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}
		_, err := collection.InsertOne(ctx, user)
		if err != nil {
			ac.logger.Printf("Google auth error: Failed to create user in database: %v", err)
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to create user"})
		}
		ac.logger.Printf("Google auth: Successfully created new user with ID: %s", user.ID.Hex())
	} else if err != nil {
		ac.logger.Printf("Google auth error: Database error while finding user: %v", err)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Database error"})
	} else {
		ac.logger.Printf("Google auth: Found existing user with ID: %s", user.ID.Hex())
	}

	// Generate your own JWT here
	ac.logger.Printf("Google auth: Generating JWT tokens for user: %s", user.ID.Hex())
	token, refreshToken, err := middleware.GenerateJWT(user.ID.Hex(), user.Email, user.UserType)
	if err != nil {
		ac.logger.Printf("Google auth error: Failed to generate JWT tokens: %v", err)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to generate token"})
	}

	user.Password = ""
	ac.logger.Printf("Google auth: Successfully authenticated user: %s", user.Email)
	return c.JSON(http.StatusOK, map[string]interface{}{
		"token":        token,
		"refreshToken": refreshToken,
		"user":         user,
	})
}
