// controllers/serviceProvider_controller.go
package controllers

import (
	"bytes"
	"context"
	"image/png"
	"io"
	"log"
	"math/rand"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"time"

	"github.com/HSouheill/barrim_backend/config"
	"github.com/HSouheill/barrim_backend/middleware"
	"github.com/HSouheill/barrim_backend/models"
	"github.com/HSouheill/barrim_backend/utils"
	"github.com/boombuler/barcode"
	"github.com/boombuler/barcode/qr"
	"github.com/labstack/echo/v4"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// UserController contains user management logic
type ServiceProviderReferralController struct {
	DB *mongo.Client
}

func NewServiceProviderReferralController(db *mongo.Client) *ServiceProviderReferralController {
	return &ServiceProviderReferralController{DB: db}
}

// GetServiceProviderDetails retrieves detailed information about a specific service provider
func (c *ServiceProviderReferralController) GetServiceProviderDetails(ctx echo.Context) error {
	// Extract user ID from token
	userID, err := middleware.ExtractUserID(ctx)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid authentication token",
		})
	}

	// Convert string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID format",
		})
	}

	// Get user collection
	userCollection := c.DB.Database("barrim").Collection("users")

	// Define filter for service provider
	filter := bson.M{
		"_id":      objID,
		"userType": "serviceProvider",
	}

	// Find the service provider
	var serviceProvider models.User
	err = userCollection.FindOne(context.Background(), filter).Decode(&serviceProvider)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return ctx.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to fetch service provider data: " + err.Error(),
		})
	}

	// Retrieve category information from the serviceProviders collection
	var category string
	if serviceProvider.ServiceProviderID != nil {
		// Get service providers collection
		serviceProviderCollection := c.DB.Database("barrim").Collection("serviceProviders")

		// Find the service provider document by ID
		var spDoc models.ServiceProvider
		err = serviceProviderCollection.FindOne(context.Background(), bson.M{
			"_id": serviceProvider.ServiceProviderID,
		}).Decode(&spDoc)

		if err == nil {
			// Category found
			category = spDoc.Category
		} else if err != mongo.ErrNoDocuments {
			log.Printf("Failed to fetch service provider category: %v", err)
		}
	}

	// Update status based on current availability
	isAvailable := c.isServiceProviderAvailable(&serviceProvider, time.Now())
	status := "not_available"
	if isAvailable {
		status = "available"
	}

	// Update status in database
	_, err = userCollection.UpdateOne(
		context.Background(),
		bson.M{"_id": serviceProvider.ID},
		bson.M{
			"$set": bson.M{
				"serviceProviderInfo.status": status,
				"updatedAt":                  time.Now(),
			},
		},
	)

	if err != nil {
		log.Printf("Failed to update service provider status: %v", err)
	}

	// Remove sensitive information
	serviceProvider.Password = ""
	serviceProvider.OTPInfo = nil
	serviceProvider.ResetPasswordToken = ""

	// Update status in the response
	if serviceProvider.ServiceProviderInfo != nil {
		serviceProvider.ServiceProviderInfo.Status = status
	}

	// Create response data with category information and explicit id/userid fields
	responseData := map[string]interface{}{
		"serviceProvider": serviceProvider,
		"category":        category,
		"id":              serviceProvider.ID.Hex(),
		"userid":          serviceProvider.ID.Hex(), // Since this is the user document, the ID is the userid
	}

	// Return the service provider data with category information
	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Service provider details retrieved successfully",
		Data:    responseData,
	})
}

// ServiceProviderWithUserData represents service provider data combined with user information
type ServiceProviderWithUserData struct {
	models.ServiceProvider `bson:",inline"`
	Description            string      `json:"description,omitempty"`
	Rating                 float64     `json:"rating,omitempty"`
	ProfilePhoto           string      `json:"profilePhoto,omitempty"`
	CertificateImages      []string    `json:"certificateImages,omitempty"`
	ServiceType            string      `json:"serviceType,omitempty"`
	CustomServiceType      string      `json:"customServiceType,omitempty"`
	YearsExperience        interface{} `json:"yearsExperience,omitempty"`
	AvailableHours         []string    `json:"availableHours,omitempty"`
	AvailableDays          []string    `json:"availableDays,omitempty"`
	AvailableWeekdays      []string    `json:"availableWeekdays,omitempty"`
	AvailabilityStatus     string      `json:"availabilityStatus,omitempty"`
}

// GetAllServiceProviders retrieves all service providers with complete data including description and rating
func (c *ServiceProviderReferralController) GetAllServiceProviders(ctx echo.Context) error {
	// Get collections
	serviceProviderCollection := c.DB.Database("barrim").Collection("serviceProviders")
	userCollection := c.DB.Database("barrim").Collection("users")

	// Define filter for active service providers (include all statuses for now to see what's available)
	filter := bson.M{}

	// Find all service providers
	cursor, err := serviceProviderCollection.Find(context.Background(), filter)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to fetch service providers: " + err.Error(),
		})
	}
	defer cursor.Close(context.Background())

	// Decode the results
	var serviceProviders []models.ServiceProvider
	if err = cursor.All(context.Background(), &serviceProviders); err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to decode service providers: " + err.Error(),
		})
	}

	// Create enhanced service providers with user data
	var enhancedServiceProviders []ServiceProviderWithUserData

	for _, sp := range serviceProviders {
		// Remove sensitive information
		sp.Password = ""

		enhancedSP := ServiceProviderWithUserData{
			ServiceProvider: sp,
		}

		// If service provider has a userId, fetch additional user data
		if !sp.UserID.IsZero() {
			var user models.User
			err := userCollection.FindOne(context.Background(), bson.M{"_id": sp.UserID}).Decode(&user)
			if err == nil && user.ServiceProviderInfo != nil {
				// Populate additional fields from ServiceProviderInfo
				enhancedSP.Description = user.ServiceProviderInfo.Description
				enhancedSP.Rating = user.ServiceProviderInfo.Rating
				enhancedSP.ProfilePhoto = user.ServiceProviderInfo.ProfilePhoto
				enhancedSP.CertificateImages = user.ServiceProviderInfo.CertificateImages
				enhancedSP.ServiceType = user.ServiceProviderInfo.ServiceType
				enhancedSP.CustomServiceType = user.ServiceProviderInfo.CustomServiceType
				enhancedSP.YearsExperience = user.ServiceProviderInfo.YearsExperience
				enhancedSP.AvailableHours = user.ServiceProviderInfo.AvailableHours
				enhancedSP.AvailableDays = user.ServiceProviderInfo.AvailableDays
				enhancedSP.AvailableWeekdays = user.ServiceProviderInfo.AvailableWeekdays
				// Only override status if the service provider's status is empty
				if enhancedSP.Status == "" {
					enhancedSP.Status = user.ServiceProviderInfo.Status
				}
			}
		}

		enhancedServiceProviders = append(enhancedServiceProviders, enhancedSP)
	}

	// Return the enhanced service providers data
	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Service providers retrieved successfully",
		Data:    enhancedServiceProviders,
	})
}

// GetServiceProviderByID retrieves a specific service provider by ID with complete data
func (c *ServiceProviderReferralController) GetServiceProviderByID(ctx echo.Context) error {
	// Get provider ID from request parameter
	providerID := ctx.Param("id")

	// Validate ID format
	objID, err := primitive.ObjectIDFromHex(providerID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid service provider ID format",
		})
	}

	// Get collections
	serviceProviderCollection := c.DB.Database("barrim").Collection("serviceProviders")
	userCollection := c.DB.Database("barrim").Collection("users")

	// Define filter for service provider
	filter := bson.M{
		"_id": objID,
	}

	// Find the service provider
	var serviceProvider models.ServiceProvider
	err = serviceProviderCollection.FindOne(context.Background(), filter).Decode(&serviceProvider)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return ctx.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to fetch service provider: " + err.Error(),
		})
	}

	// Remove sensitive information
	serviceProvider.Password = ""

	// Create enhanced service provider with user data
	enhancedSP := ServiceProviderWithUserData{
		ServiceProvider: serviceProvider,
	}

	// If service provider has a userId, fetch additional user data
	if !serviceProvider.UserID.IsZero() {
		var user models.User
		err := userCollection.FindOne(context.Background(), bson.M{"_id": serviceProvider.UserID}).Decode(&user)
		if err == nil && user.ServiceProviderInfo != nil {
			// Only populate fields that are not already present in ServiceProvider model
			// to avoid duplication
			if enhancedSP.Description == "" {
				enhancedSP.Description = user.ServiceProviderInfo.Description
			}
			if enhancedSP.Rating == 0 {
				enhancedSP.Rating = user.ServiceProviderInfo.Rating
			}
			if enhancedSP.ProfilePhoto == "" {
				enhancedSP.ProfilePhoto = user.ServiceProviderInfo.ProfilePhoto
			}
			// Only add certificate images if not already present
			if len(enhancedSP.CertificateImages) == 0 && len(user.ServiceProviderInfo.CertificateImages) > 0 {
				enhancedSP.CertificateImages = user.ServiceProviderInfo.CertificateImages
			}
			// Only add service type if not already present
			if enhancedSP.ServiceType == "" {
				enhancedSP.ServiceType = user.ServiceProviderInfo.ServiceType
			}
			enhancedSP.CustomServiceType = user.ServiceProviderInfo.CustomServiceType
			// Only add years experience if not already present
			if enhancedSP.YearsExperience == nil {
				enhancedSP.YearsExperience = user.ServiceProviderInfo.YearsExperience
			}
			// Only add available hours if not already present
			if len(enhancedSP.AvailableHours) == 0 && len(user.ServiceProviderInfo.AvailableHours) > 0 {
				enhancedSP.AvailableHours = user.ServiceProviderInfo.AvailableHours
			}
			// Only add available days if not already present
			if len(enhancedSP.AvailableDays) == 0 && len(user.ServiceProviderInfo.AvailableDays) > 0 {
				enhancedSP.AvailableDays = user.ServiceProviderInfo.AvailableDays
			}
			enhancedSP.AvailableWeekdays = user.ServiceProviderInfo.AvailableWeekdays
			enhancedSP.AvailabilityStatus = user.ServiceProviderInfo.Status
		}
	}

	// Return the enhanced service provider data
	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Service provider retrieved successfully",
		Data:    enhancedSP,
	})
}

// GetServiceProviderLogo retrieves the logo path of a service provider
func (uc *ServiceProviderReferralController) GetServiceProviderLogo(c echo.Context) error {
	// Create a context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Get service provider ID from URL parameter
	spID := c.Param("id")
	if spID == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Service provider ID is required",
		})
	}

	// Convert string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(spID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid service provider ID format",
		})
	}

	// Get user collection
	collection := config.GetCollection(uc.DB, "users")

	// Query for service provider
	filter := bson.M{
		"_id":      objID,
		"userType": "serviceProvider",
	}

	// Find the service provider
	var serviceProvider models.User
	err = collection.FindOne(ctx, filter).Decode(&serviceProvider)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to fetch service provider data",
		})
	}

	// Check if service provider has a profile photo
	dbLogoPath := ""
	if serviceProvider.ServiceProviderInfo != nil && serviceProvider.ServiceProviderInfo.ProfilePhoto != "" {
		dbLogoPath = serviceProvider.ServiceProviderInfo.ProfilePhoto
	} else if serviceProvider.LogoPath != "" {
		dbLogoPath = serviceProvider.LogoPath
	} else {
		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Logo not found for this service provider",
		})
	}

	// Extract the filename from the database path
	filename := filepath.Base(dbLogoPath)

	// Define possible file locations to check
	possibleLocations := []string{
		filepath.Join("uploads", "serviceprovider", filename),
		filepath.Join("uploads", "profiles", filename),
		filepath.Join("uploads", "logos", filename),
		filepath.Join("uploads", filename),
	}

	// Check if file exists in any of the possible locations
	var foundFilePath string
	for _, location := range possibleLocations {
		if _, err := os.Stat(location); !os.IsNotExist(err) {
			foundFilePath = location
			break
		}
	}

	// If file not found in any location
	if foundFilePath == "" {
		// Log error for debugging
		log.Printf("File not found for service provider %s. Database path: %s", spID, dbLogoPath)

		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Logo file not found on server",
		})
	}

	// Construct the correct URL path for the browser
	// The browser URL should match how your ServeImage function expects the path
	// Typically, this would be something like "/uploads/filename.jpg"
	urlPath := "/" + strings.TrimPrefix(foundFilePath, "./")
	if !strings.HasPrefix(urlPath, "/") {
		urlPath = "/" + urlPath
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Service provider logo retrieved successfully",
		Data: map[string]string{
			"logoPath": urlPath,
		},
	})
}

// HandleServiceProviderReferral processes a referral between service providers
func (rc *ServiceProviderReferralController) HandleServiceProviderReferral(c echo.Context) error {
	var req models.ReferralRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request body",
		})
	}

	// Validate referral code
	if req.ReferralCode == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Referral code is required",
		})
	}

	// Get current user's ID from token
	user, err := utils.GetUserFromToken(c, rc.DB)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Authentication failed: " + err.Error(),
		})
	}

	// Check if the user is a service provider
	if user.UserType != "serviceProvider" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Only service providers can use this endpoint",
		})
	}

	// Find the referrer by referral code
	ctx := context.Background()
	usersCollection := rc.DB.Database("barrim").Collection("users")

	var referrer models.User
	err = usersCollection.FindOne(ctx, bson.M{
		"userType":                         "serviceProvider",
		"serviceProviderInfo.referralCode": req.ReferralCode,
	}).Decode(&referrer)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Invalid referral code",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Database error: " + err.Error(),
		})
	}

	// Make sure the user isn't trying to refer themselves
	if user.ID == referrer.ID {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "You cannot refer yourself",
		})
	}

	// Check if this user has already used a referral code
	if user.ServiceProviderInfo != nil && user.ServiceProviderInfo.Points > 0 {
		return c.JSON(http.StatusConflict, models.Response{
			Status:  http.StatusConflict,
			Message: "You have already used a referral code",
		})
	}

	// Update the referrer's points and add this user to their referred list
	_, err = usersCollection.UpdateOne(
		ctx,
		bson.M{"_id": referrer.ID},
		bson.M{
			"$inc":  bson.M{"serviceProviderInfo.points": 5},
			"$push": bson.M{"serviceProviderInfo.referredServiceProviders": user.ID},
		},
	)

	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update referrer's points: " + err.Error(),
		})
	}

	// Update the referred user's points
	_, err = usersCollection.UpdateOne(
		ctx,
		bson.M{"_id": user.ID},
		bson.M{
			"$inc": bson.M{"serviceProviderInfo.points": 1},
		},
	)

	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update your points: " + err.Error(),
		})
	}

	// Return success response
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Referral processed successfully",
		Data: map[string]interface{}{
			"pointsAdded": 1,
			"referrer": map[string]interface{}{
				"id":       referrer.ID.Hex(),
				"fullName": referrer.FullName,
				"points":   referrer.ServiceProviderInfo.Points + 5, // Updated points
			},
		},
	})
}

// GetServiceProviderReferralData returns referral information for a service provider
func (rc *ServiceProviderReferralController) GetServiceProviderReferralData(c echo.Context) error {
	// Get current user's ID from token
	user, err := utils.GetUserFromToken(c, rc.DB)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Authentication failed: " + err.Error(),
		})
	}

	// Check if the user is a service provider
	if user.UserType != "serviceProvider" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Only service providers can use this endpoint",
		})
	}

	// Resolve ServiceProviderInfo from user document or fallback to serviceProviders collection
	info := user.ServiceProviderInfo
	ctx := context.Background()

	if info == nil || (info.ReferralCode == "" && info.Points == 0 && (info.ReferredServiceProviders == nil || len(info.ReferredServiceProviders) == 0)) {
		// Try to fetch from serviceProviders collection using ServiceProviderID
		if user.ServiceProviderID != nil {
			serviceProvidersCollection := rc.DB.Database("barrim").Collection("serviceProviders")
			var sp models.ServiceProvider
			err := serviceProvidersCollection.FindOne(ctx, bson.M{"_id": user.ServiceProviderID}).Decode(&sp)
			if err == nil && sp.ServiceProviderInfo != nil {
				info = sp.ServiceProviderInfo
			}
		}
	}

	// If still nil, return empty defaults but 200 OK
	if info == nil {
		info = &models.ServiceProviderInfo{}
	}

	// Prepare referred users list from info
	usersCollection := rc.DB.Database("barrim").Collection("users")
	var referredUsers []models.User
	if info.ReferredServiceProviders != nil && len(info.ReferredServiceProviders) > 0 {
		cursor, err := usersCollection.Find(ctx, bson.M{
			"_id": bson.M{"$in": info.ReferredServiceProviders},
		})
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to retrieve referred users: " + err.Error(),
			})
		}
		defer cursor.Close(ctx)
		if err = cursor.All(ctx, &referredUsers); err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to parse referred users: " + err.Error(),
			})
		}
		for i := range referredUsers {
			referredUsers[i].Password = ""
			referredUsers[i].OTPInfo = nil
			referredUsers[i].ResetPasswordToken = ""
		}
	}

	// Create QR code URL if referral code exists. Fallback to user.ReferralCode if needed
	referralCode := info.ReferralCode
	if referralCode == "" {
		referralCode = user.ReferralCode
	}
	var qrCodeURL string
	if referralCode != "" {
		qrCodeURL = "/api/qrcode/referral/" + referralCode
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Referral data retrieved successfully",
		Data: map[string]interface{}{
			"referralCode":  referralCode,
			"points":        info.Points,
			"referredCount": len(info.ReferredServiceProviders),
			"referredUsers": referredUsers,
			"qrCodeURL":     qrCodeURL,
		},
	})
}

// GenerateReferralCode creates a unique referral code
func GenerateReferralCode() string {
	rand.Seed(time.Now().UnixNano())
	const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	result := make([]byte, 8)
	for i := range result {
		result[i] = chars[rand.Intn(len(chars))]
	}
	return string(result)
}

// GenerateReferralQRCode generates a QR code for a referral code
func (qc *ServiceProviderReferralController) GenerateReferralQRCode(c echo.Context) error {
	// Get referral code from URL parameter
	referralCode := c.Param("code")
	if referralCode == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Referral code is required",
		})
	}

	// Create content string for QR code
	// You could include app URL or other information as needed
	content := "barrim://referral/" + referralCode

	// Generate QR code
	qrCode, err := qr.Encode(content, qr.M, qr.Auto)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to generate QR code: " + err.Error(),
		})
	}

	// Scale the QR code to a reasonable size
	qrCode, err = barcode.Scale(qrCode, 200, 200)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to scale QR code: " + err.Error(),
		})
	}

	// Create a buffer to store the image
	buffer := new(bytes.Buffer)

	// Encode the QR code as PNG
	if err := png.Encode(buffer, qrCode); err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to encode QR code as PNG: " + err.Error(),
		})
	}

	// Set appropriate headers
	c.Response().Header().Set("Content-Type", "image/png")
	c.Response().Header().Set("Content-Disposition", "inline; filename=referral-"+referralCode+".png")

	// Write the image to the response
	return c.Blob(http.StatusOK, "image/png", buffer.Bytes())
}

// GenerateReferralQRCodeAsBase64 generates a QR code for a referral code and returns as base64
func (qc *ServiceProviderReferralController) GenerateReferralQRCodeAsBase64(c echo.Context) error {
	// Get referral code from URL parameter
	referralCode := c.Param("code")
	if referralCode == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Referral code is required",
		})
	}

	// Create content string for QR code
	content := "barrim://referral/" + referralCode

	// Generate QR code
	qrCode, err := qr.Encode(content, qr.M, qr.Auto)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to generate QR code: " + err.Error(),
		})
	}

	// Scale the QR code to a reasonable size
	qrCode, err = barcode.Scale(qrCode, 200, 200)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to scale QR code: " + err.Error(),
		})
	}

	// Create a buffer to store the image
	buffer := new(bytes.Buffer)

	// Encode the QR code as PNG
	if err := png.Encode(buffer, qrCode); err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to encode QR code as PNG: " + err.Error(),
		})
	}

	// Return the Base64 encoded image
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "QR code generated successfully",
		Data: map[string]interface{}{
			"qrCodeBase64": "data:image/png;base64," + buffer.String(),
			"referralCode": referralCode,
		},
	})
}

// UpdateServiceProviderSocialLinks updates the social media links for a service provider
func (c *ServiceProviderReferralController) UpdateServiceProviderSocialLinks(ctx echo.Context) error {
	// Extract user ID from token
	userID, err := middleware.ExtractUserID(ctx)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid authentication token",
		})
	}

	// Convert string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID format",
		})
	}

	// Parse request body
	var req models.UpdateSocialLinksRequest
	if err := ctx.Bind(&req); err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request body: " + err.Error(),
		})
	}

	// Validate URLs if they're not empty
	if req.SocialLinks.Website != "" && !isValidURL(req.SocialLinks.Website) {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid website URL format",
		})
	}

	if req.SocialLinks.Facebook != "" && !isValidURL(req.SocialLinks.Facebook) {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid Facebook URL format",
		})
	}

	if req.SocialLinks.Instagram != "" && !isValidURL(req.SocialLinks.Instagram) {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid Instagram URL format",
		})
	}

	// Get user collection
	userCollection := c.DB.Database("barrim").Collection("users")

	// Check if user exists and is a service provider
	var user models.User
	err = userCollection.FindOne(context.Background(), bson.M{
		"_id":      objID,
		"userType": "serviceProvider",
	}).Decode(&user)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return ctx.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to fetch service provider data: " + err.Error(),
		})
	}

	// Update the social links
	update := bson.M{
		"$set": bson.M{
			"serviceProviderInfo.socialLinks": req.SocialLinks,
			"updatedAt":                       time.Now(),
		},
	}

	_, err = userCollection.UpdateOne(
		context.Background(),
		bson.M{"_id": objID},
		update,
	)

	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update social links: " + err.Error(),
		})
	}

	// Return success response
	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Social links updated successfully",
		Data:    req.SocialLinks,
	})
}

// Helper function to validate URLs
func isValidURL(urlStr string) bool {
	// Add http:// prefix if missing
	if !strings.HasPrefix(urlStr, "http://") && !strings.HasPrefix(urlStr, "https://") {
		urlStr = "https://" + urlStr
	}

	u, err := url.Parse(urlStr)
	return err == nil && u.Scheme != "" && u.Host != ""
}

// UpdateServiceProviderData updates the service provider's information
func (c *ServiceProviderReferralController) UpdateServiceProviderData(ctx echo.Context) error {
	// Extract user ID from token
	userID, err := middleware.ExtractUserID(ctx)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid authentication token",
		})
	}

	// Convert string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID format",
		})
	}

	// Parse multipart form
	form, err := ctx.MultipartForm()
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid form data",
		})
	}

	// Get form values
	fullName := form.Value["fullName"]
	email := form.Value["email"]
	password := form.Value["password"]
	category := form.Value["category"]
	yearsExperience := form.Value["yearsExperience"]
	description := form.Value["description"]
	serviceType := form.Value["serviceType"]
	customServiceType := form.Value["customServiceType"]

	// Location fields
	country := form.Value["country"]
	district := form.Value["district"]
	city := form.Value["city"]
	street := form.Value["street"]
	postalCode := form.Value["postalCode"]
	lat := form.Value["lat"]
	lng := form.Value["lng"]

	// Availability fields
	availableDays := form.Value["availableDays"]
	availableHours := form.Value["availableHours"]
	availableWeekdays := form.Value["availableWeekdays"]
	applyToAllMonths := form.Value["applyToAllMonths"]

	// Prepare update fields
	updateFields := bson.M{
		"updatedAt": time.Now(),
	}

	// Declare variables at function level
	var uploadPath string
	var hashedPassword string

	// Handle logo file if present
	logoFiles := form.File["logo"]
	if len(logoFiles) > 0 {
		logoFile := logoFiles[0]

		// Validate file
		if !utils.IsValidImageFile(logoFile) {
			return ctx.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Invalid logo file type",
			})
		}

		// Save logo file
		filename := "logo_" + userID + "_" + time.Now().Format("20060102150405") + filepath.Ext(logoFile.Filename)
		uploadPath = filepath.Join("uploads", "logos", filename)

		// Ensure directory exists
		os.MkdirAll(filepath.Join("uploads", "logos"), 0755)

		// Save the file
		src, err := logoFile.Open()
		if err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to open logo file",
			})
		}
		defer src.Close()

		dst, err := os.Create(uploadPath)
		if err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to save logo file",
			})
		}
		defer dst.Close()

		if _, err = io.Copy(dst, src); err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to copy logo file",
			})
		}

		updateFields["logoPath"] = uploadPath
	}

	// Handle certificate files if present
	certificateFiles := form.File["certificates"]
	var certificatePaths []string
	if len(certificateFiles) > 0 {
		// Ensure directory exists
		os.MkdirAll(filepath.Join("uploads", "certificates"), 0755)

		for i, certFile := range certificateFiles {
			// Validate file
			if !utils.IsValidImageFile(certFile) {
				return ctx.JSON(http.StatusBadRequest, models.Response{
					Status:  http.StatusBadRequest,
					Message: "Invalid certificate file type",
				})
			}

			// Save certificate file
			filename := "certificate_" + userID + "_" + time.Now().Format("20060102150405") + "_" + strconv.Itoa(i) + filepath.Ext(certFile.Filename)
			uploadPath := filepath.Join("uploads", "certificates", filename)

			// Save the file
			src, err := certFile.Open()
			if err != nil {
				return ctx.JSON(http.StatusInternalServerError, models.Response{
					Status:  http.StatusInternalServerError,
					Message: "Failed to open certificate file",
				})
			}
			defer src.Close()

			dst, err := os.Create(uploadPath)
			if err != nil {
				return ctx.JSON(http.StatusInternalServerError, models.Response{
					Status:  http.StatusInternalServerError,
					Message: "Failed to save certificate file",
				})
			}
			defer dst.Close()

			if _, err = io.Copy(dst, src); err != nil {
				return ctx.JSON(http.StatusInternalServerError, models.Response{
					Status:  http.StatusInternalServerError,
					Message: "Failed to copy certificate file",
				})
			}

			certificatePaths = append(certificatePaths, uploadPath)
		}
	}

	// Prepare password hashing if needed
	if len(password) > 0 && password[0] != "" {
		hashedPassword, err = utils.HashPassword(password[0])
		if err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to hash password",
			})
		}
	}

	// Prepare ServiceProviderInfo update
	serviceProviderInfo := bson.M{}

	// Update years of experience
	if len(yearsExperience) > 0 && yearsExperience[0] != "" {
		// Try to convert to int if it's a string
		if years, err := strconv.Atoi(yearsExperience[0]); err == nil {
			serviceProviderInfo["yearsExperience"] = years
		} else {
			serviceProviderInfo["yearsExperience"] = yearsExperience[0]
		}
	}

	// Update description
	if len(description) > 0 && description[0] != "" {
		serviceProviderInfo["description"] = description[0]
	}

	// Update service type
	if len(serviceType) > 0 && serviceType[0] != "" {
		serviceProviderInfo["serviceType"] = serviceType[0]
	}

	// Update custom service type
	if len(customServiceType) > 0 && customServiceType[0] != "" {
		serviceProviderInfo["customServiceType"] = customServiceType[0]
	}

	// Update certificate images
	if len(certificatePaths) > 0 {
		serviceProviderInfo["certificateImages"] = certificatePaths
	}

	// Update availability days
	if len(availableDays) > 0 {
		serviceProviderInfo["availableDays"] = availableDays
	}

	// Update availability hours
	if len(availableHours) > 0 {
		serviceProviderInfo["availableHours"] = availableHours
	}

	// Update availability weekdays
	if len(availableWeekdays) > 0 {
		serviceProviderInfo["availableWeekdays"] = availableWeekdays
	}

	// Update apply to all months
	if len(applyToAllMonths) > 0 {
		applyToAllMonthsBool := applyToAllMonths[0] == "true"
		serviceProviderInfo["applyToAllMonths"] = applyToAllMonthsBool
	}

	// Prepare location update
	location := bson.M{}
	locationUpdated := false

	if len(country) > 0 && country[0] != "" {
		location["country"] = country[0]
		locationUpdated = true
	}

	if len(district) > 0 && district[0] != "" {
		location["district"] = district[0]
		locationUpdated = true
	}

	if len(city) > 0 && city[0] != "" {
		location["city"] = city[0]
		locationUpdated = true
	}

	if len(street) > 0 && street[0] != "" {
		location["street"] = street[0]
		locationUpdated = true
	}

	if len(postalCode) > 0 && postalCode[0] != "" {
		location["postalCode"] = postalCode[0]
		locationUpdated = true
	}

	if len(lat) > 0 && lat[0] != "" {
		if latFloat, err := strconv.ParseFloat(lat[0], 64); err == nil {
			location["lat"] = latFloat
			locationUpdated = true
		}
	}

	if len(lng) > 0 && lng[0] != "" {
		if lngFloat, err := strconv.ParseFloat(lng[0], 64); err == nil {
			location["lng"] = lngFloat
			locationUpdated = true
		}
	}

	// Set allowed to true by default for location
	if locationUpdated {
		location["allowed"] = true
		serviceProviderInfo["location"] = location
	}

	// Perform the update - Update both users and serviceProviders collections
	// To avoid duplication, we'll update users collection with basic user fields only
	// and serviceProviders collection with all service provider specific data

	// First, update the users collection for basic user info only
	userCollection := c.DB.Database("barrim").Collection("users")
	userUpdateFields := bson.M{
		"updatedAt": time.Now(),
	}

	// Add only basic user fields to user update (no service provider specific data)
	if len(fullName) > 0 && fullName[0] != "" {
		userUpdateFields["fullName"] = fullName[0]
	}
	if len(email) > 0 && email[0] != "" {
		userUpdateFields["email"] = email[0]
	}
	if len(password) > 0 && password[0] != "" {
		userUpdateFields["password"] = hashedPassword
	}
	if len(logoFiles) > 0 {
		userUpdateFields["logoPath"] = uploadPath
	}

	_, err = userCollection.UpdateOne(
		context.Background(),
		bson.M{"_id": objID},
		bson.M{"$set": userUpdateFields},
	)

	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update user data",
		})
	}

	// Then, update the serviceProviders collection with ALL service provider data
	serviceProviderCollection := c.DB.Database("barrim").Collection("serviceProviders")

	// Build service provider update document with all fields
	serviceProviderUpdateFields := bson.M{
		"updatedAt": time.Now(),
	}

	// Add category to service provider update (root level)
	if len(category) > 0 && category[0] != "" {
		serviceProviderUpdateFields["category"] = category[0]
	}

	// Note: phone, contactPerson, contactPhone are not available in this form
	// They would need to be added to the form parsing section if needed

	// Add location fields (root level)
	if len(country) > 0 && country[0] != "" {
		serviceProviderUpdateFields["country"] = country[0]
	}
	if len(district) > 0 && district[0] != "" {
		serviceProviderUpdateFields["district"] = district[0]
	}
	if len(city) > 0 && city[0] != "" {
		serviceProviderUpdateFields["city"] = city[0]
	}
	if len(street) > 0 && street[0] != "" {
		serviceProviderUpdateFields["street"] = street[0]
	}
	if len(postalCode) > 0 && postalCode[0] != "" {
		serviceProviderUpdateFields["postalCode"] = postalCode[0]
	}

	// Add logo path
	if len(logoFiles) > 0 {
		serviceProviderUpdateFields["logoPath"] = uploadPath
	}

	// Add serviceProviderInfo fields using dot notation
	if len(serviceProviderInfo) > 0 {
		for key, value := range serviceProviderInfo {
			serviceProviderUpdateFields["serviceProviderInfo."+key] = value
		}
	}

	// Update service provider document using userId as reference
	_, err = serviceProviderCollection.UpdateOne(
		context.Background(),
		bson.M{"userId": objID},
		bson.M{"$set": serviceProviderUpdateFields},
	)

	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update service provider data",
		})
	}

	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Service provider data updated successfully",
		Data:    serviceProviderUpdateFields,
	})
}

// UploadCertificateImage handles the upload of a service provider's certificate
func (c *ServiceProviderReferralController) UploadCertificateImage(ctx echo.Context) error {
	// Extract user ID from token
	userID, err := middleware.ExtractUserID(ctx)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid authentication token",
		})
	}

	// Get the file from the request
	file, err := ctx.FormFile("certificate")
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "No file uploaded",
		})
	}

	// Validate file type and size
	if !utils.IsValidImageFile(file) {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid file type. Only images are allowed",
		})
	}

	// Generate unique filename
	filename := "certificate_" + userID + "_" + time.Now().Format("20060102150405") + filepath.Ext(file.Filename)
	uploadPath := filepath.Join("uploads", "certificates", filename)

	// Ensure directory exists
	os.MkdirAll(filepath.Join("uploads", "certificates"), 0755)

	// Save the file
	src, err := file.Open()
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to open uploaded file",
		})
	}
	defer src.Close()

	dst, err := os.Create(uploadPath)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to create destination file",
		})
	}
	defer dst.Close()

	if _, err = io.Copy(dst, src); err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to save file",
		})
	}

	// Update the user's certificate images array in the database
	userCollection := c.DB.Database("barrim").Collection("users")
	objID, _ := primitive.ObjectIDFromHex(userID)

	update := bson.M{
		"$push": bson.M{
			"serviceProviderInfo.certificateImages": uploadPath,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	_, err = userCollection.UpdateOne(context.Background(), bson.M{"_id": objID}, update)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update certificate images",
		})
	}

	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Certificate image uploaded successfully",
		Data: map[string]interface{}{
			"certificateImage": uploadPath,
			"message":          "Certificate added to your collection",
		},
	})
}

// GetCertificates retrieves all certificates for a service provider
func (c *ServiceProviderReferralController) GetCertificates(ctx echo.Context) error {
	// Extract user ID from token
	userID, err := middleware.ExtractUserID(ctx)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid authentication token",
		})
	}

	// Convert string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID format",
		})
	}

	// Get user collection
	userCollection := c.DB.Database("barrim").Collection("users")

	// Find the service provider
	var user models.User
	err = userCollection.FindOne(context.Background(), bson.M{
		"_id":      objID,
		"userType": "serviceProvider",
	}).Decode(&user)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return ctx.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to fetch service provider data: " + err.Error(),
		})
	}

	// Get certificates
	var certificates []string
	if user.ServiceProviderInfo != nil {
		certificates = user.ServiceProviderInfo.CertificateImages
	}

	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Certificates retrieved successfully",
		Data: map[string]interface{}{
			"certificates": certificates,
			"count":        len(certificates),
		},
	})
}

// DeleteCertificate removes a specific certificate from a service provider
func (c *ServiceProviderReferralController) DeleteCertificate(ctx echo.Context) error {
	// Extract user ID from token
	userID, err := middleware.ExtractUserID(ctx)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid authentication token",
		})
	}

	// Convert string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID format",
		})
	}

	// Get certificate path from request
	var req struct {
		CertificatePath string `json:"certificatePath"`
	}
	if err := ctx.Bind(&req); err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request body",
		})
	}

	if req.CertificatePath == "" {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Certificate path is required",
		})
	}

	// Get user collection
	userCollection := c.DB.Database("barrim").Collection("users")

	// Remove the certificate from the array
	update := bson.M{
		"$pull": bson.M{
			"serviceProviderInfo.certificateImages": req.CertificatePath,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	result, err := userCollection.UpdateOne(context.Background(), bson.M{"_id": objID}, update)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to delete certificate: " + err.Error(),
		})
	}

	if result.ModifiedCount == 0 {
		return ctx.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Certificate not found",
		})
	}

	// Try to delete the physical file
	filePath := req.CertificatePath
	if _, err := os.Stat(filePath); err == nil {
		os.Remove(filePath)
	}

	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Certificate deleted successfully",
		Data: map[string]interface{}{
			"deletedPath": req.CertificatePath,
		},
	})
}

// GetCertificateDetails retrieves detailed information about a specific certificate
func (c *ServiceProviderReferralController) GetCertificateDetails(ctx echo.Context) error {
	// Extract user ID from token
	userID, err := middleware.ExtractUserID(ctx)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid authentication token",
		})
	}

	// Convert string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID format",
		})
	}

	// Get certificate path from URL parameter
	certificatePath := ctx.QueryParam("path")
	if certificatePath == "" {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Certificate path is required",
		})
	}

	// Get user collection
	userCollection := c.DB.Database("barrim").Collection("users")

	// Find the service provider
	var user models.User
	err = userCollection.FindOne(context.Background(), bson.M{
		"_id":      objID,
		"userType": "serviceProvider",
	}).Decode(&user)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return ctx.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to fetch service provider data: " + err.Error(),
		})
	}

	// Check if certificate exists in user's certificates
	certificateExists := false
	if user.ServiceProviderInfo != nil {
		for _, cert := range user.ServiceProviderInfo.CertificateImages {
			if cert == certificatePath {
				certificateExists = true
				break
			}
		}
	}

	if !certificateExists {
		return ctx.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Certificate not found",
		})
	}

	// Get file information
	fileInfo, err := os.Stat(certificatePath)
	if err != nil {
		return ctx.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Certificate file not found",
		})
	}

	// Extract filename from path
	filename := filepath.Base(certificatePath)

	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Certificate details retrieved successfully",
		Data: map[string]interface{}{
			"filename":   filename,
			"path":       certificatePath,
			"size":       fileInfo.Size(),
			"uploadedAt": fileInfo.ModTime(),
			"isReadable": true,
		},
	})
}

// Helper function to check if a service provider is available at a given time
func (c *ServiceProviderReferralController) isServiceProviderAvailable(sp *models.User, checkTime time.Time) bool {
	if sp.ServiceProviderInfo == nil {
		return false
	}

	// Get current weekday
	currentWeekday := checkTime.Weekday().String()

	// Check if the current weekday is in available weekdays
	isWeekdayAvailable := false
	for _, weekday := range sp.ServiceProviderInfo.AvailableWeekdays {
		if weekday == currentWeekday {
			isWeekdayAvailable = true
			break
		}
	}

	if !isWeekdayAvailable {
		return false
	}

	// Get current time in HH:MM format
	currentTime := checkTime.Format("15:04")

	// Check if current time is within available hours
	isTimeAvailable := false
	for _, hourRange := range sp.ServiceProviderInfo.AvailableHours {
		// Split the range into start and end times
		times := strings.Split(hourRange, "-")
		if len(times) != 2 {
			continue
		}
		startTime := strings.TrimSpace(times[0])
		endTime := strings.TrimSpace(times[1])

		if currentTime >= startTime && currentTime <= endTime {
			isTimeAvailable = true
			break
		}
	}

	return isTimeAvailable
}

// UpdateServiceProviderStatus updates the availability status of a service provider
func (c *ServiceProviderReferralController) UpdateServiceProviderStatus(ctx echo.Context) error {
	// Extract user ID from token
	userID, err := middleware.ExtractUserID(ctx)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Invalid authentication token",
		})
	}

	// Convert string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID format",
		})
	}

	// Get user collection
	userCollection := c.DB.Database("barrim").Collection("users")

	// Get current service provider
	var serviceProvider models.User
	err = userCollection.FindOne(context.Background(), bson.M{
		"_id":      objID,
		"userType": "serviceProvider",
	}).Decode(&serviceProvider)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return ctx.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to fetch service provider data: " + err.Error(),
		})
	}

	// Check availability
	isAvailable := c.isServiceProviderAvailable(&serviceProvider, time.Now())
	status := "not_available"
	if isAvailable {
		status = "available"
	}

	// Update status in database
	_, err = userCollection.UpdateOne(
		context.Background(),
		bson.M{"_id": objID},
		bson.M{
			"$set": bson.M{
				"serviceProviderInfo.status": status,
				"updatedAt":                  time.Now(),
			},
		},
	)

	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update service provider status: " + err.Error(),
		})
	}

	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Service provider status updated successfully",
		Data: map[string]string{
			"status": status,
		},
	})
}
