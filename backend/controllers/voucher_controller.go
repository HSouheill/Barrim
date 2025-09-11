package controllers

import (
	"context"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/HSouheill/barrim_backend/middleware"
	"github.com/HSouheill/barrim_backend/models"
	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type VoucherController struct {
	DB *mongo.Database
}

func NewVoucherController(db *mongo.Database) *VoucherController {
	return &VoucherController{DB: db}
}

// CreateVoucher creates a new voucher with image upload (Admin only)
func (vc *VoucherController) CreateVoucher(c echo.Context) error {
	// Check if user is admin
	claims := middleware.GetUserFromToken(c)
	if claims.UserType != "admin" && claims.UserType != "super_admin" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Access denied. Admin privileges required.",
		})
	}

	// Parse multipart form
	if err := c.Request().ParseMultipartForm(10 << 20); err != nil { // 10MB max
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Failed to parse form data",
			Data:    err.Error(),
		})
	}

	form, err := c.MultipartForm()
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Failed to get multipart form",
			Data:    err.Error(),
		})
	}

	// Get form data
	name := c.FormValue("name")
	description := c.FormValue("description")
	pointsStr := c.FormValue("points")

	if name == "" || description == "" || pointsStr == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Name, description, and points are required",
		})
	}

	// Convert points to int
	points, err := strconv.Atoi(pointsStr)
	if err != nil || points <= 0 {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Points must be a positive integer",
		})
	}

	// Handle image upload
	var imagePath string
	if files := form.File["image"]; len(files) > 0 {
		imagePath, err = vc.saveVoucherImage(files[0])
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to save image",
				Data:    err.Error(),
			})
		}
	} else {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Image is required",
		})
	}

	// Convert UserID to ObjectID
	createdByID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	// Create voucher
	voucher := models.Voucher{
		ID:          primitive.NewObjectID(),
		Name:        name,
		Description: description,
		Image:       imagePath,
		Points:      points,
		IsActive:    true,
		CreatedBy:   createdByID,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	// Insert into database
	collection := vc.DB.Collection("vouchers")
	ctx := context.Background()

	_, err = collection.InsertOne(ctx, voucher)
	if err != nil {
		// If database insert fails, delete the uploaded image
		if imagePath != "" {
			os.Remove(strings.TrimPrefix(imagePath, "/uploads/"))
		}
		log.Printf("Error creating voucher: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to create voucher",
			Data:    err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, models.Response{
		Status:  http.StatusCreated,
		Message: "Voucher created successfully",
		Data:    voucher,
	})
}

// CreateVoucherJSON creates a new voucher without image upload (Admin only)
func (vc *VoucherController) CreateVoucherJSON(c echo.Context) error {
	// Check if user is admin
	claims := middleware.GetUserFromToken(c)
	if claims.UserType != "admin" && claims.UserType != "super_admin" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Access denied. Admin privileges required.",
		})
	}

	var req models.VoucherRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request body",
			Data:    err.Error(),
		})
	}

	// Validate request
	validate := validator.New()
	if err := validate.Struct(req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Validation failed",
			Data:    err.Error(),
		})
	}

	// Convert UserID to ObjectID
	createdByID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	// Create voucher
	voucher := models.Voucher{
		ID:          primitive.NewObjectID(),
		Name:        req.Name,
		Description: req.Description,
		Image:       req.Image, // Use provided image URL
		Points:      req.Points,
		IsActive:    true,
		CreatedBy:   createdByID,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	// Insert into database
	collection := vc.DB.Collection("vouchers")
	ctx := context.Background()

	_, err = collection.InsertOne(ctx, voucher)
	if err != nil {
		log.Printf("Error creating voucher: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to create voucher",
			Data:    err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, models.Response{
		Status:  http.StatusCreated,
		Message: "Voucher created successfully",
		Data:    voucher,
	})
}

// GetAllVouchers retrieves all vouchers (Admin only)
func (vc *VoucherController) GetAllVouchers(c echo.Context) error {
	// Check if user is admin
	claims := middleware.GetUserFromToken(c)
	if claims.UserType != "admin" && claims.UserType != "super_admin" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Access denied. Admin privileges required.",
		})
	}

	collection := vc.DB.Collection("vouchers")
	ctx := context.Background()

	cursor, err := collection.Find(ctx, bson.M{})
	if err != nil {
		log.Printf("Error retrieving vouchers: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve vouchers",
			Data:    err.Error(),
		})
	}
	defer cursor.Close(ctx)

	var vouchers []models.Voucher
	if err = cursor.All(ctx, &vouchers); err != nil {
		log.Printf("Error decoding vouchers: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to decode vouchers",
			Data:    err.Error(),
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Vouchers retrieved successfully",
		Data: map[string]interface{}{
			"count":    len(vouchers),
			"vouchers": vouchers,
		},
	})
}

// UpdateVoucher updates an existing voucher with optional image upload (Admin only)
func (vc *VoucherController) UpdateVoucher(c echo.Context) error {
	// Check if user is admin
	claims := middleware.GetUserFromToken(c)
	if claims.UserType != "admin" && claims.UserType != "super_admin" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Access denied. Admin privileges required.",
		})
	}

	voucherID := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(voucherID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid voucher ID",
		})
	}

	// Parse multipart form
	if err := c.Request().ParseMultipartForm(10 << 20); err != nil { // 10MB max
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Failed to parse form data",
			Data:    err.Error(),
		})
	}

	form, err := c.MultipartForm()
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Failed to get multipart form",
			Data:    err.Error(),
		})
	}

	// Get form data
	name := c.FormValue("name")
	description := c.FormValue("description")
	pointsStr := c.FormValue("points")

	if name == "" || description == "" || pointsStr == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Name, description, and points are required",
		})
	}

	// Convert points to int
	points, err := strconv.Atoi(pointsStr)
	if err != nil || points <= 0 {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Points must be a positive integer",
		})
	}

	// Get current voucher to check if we need to delete old image
	collection := vc.DB.Collection("vouchers")
	ctx := context.Background()

	var currentVoucher models.Voucher
	err = collection.FindOne(ctx, bson.M{"_id": objID}).Decode(&currentVoucher)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Voucher not found",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve voucher",
			Data:    err.Error(),
		})
	}

	// Handle image upload (optional)
	var imagePath string
	var oldImagePath string
	if files := form.File["image"]; len(files) > 0 {
		// Save new image
		imagePath, err = vc.saveVoucherImage(files[0])
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to save image",
				Data:    err.Error(),
			})
		}
		oldImagePath = currentVoucher.Image
	} else {
		// Keep existing image
		imagePath = currentVoucher.Image
	}

	// Update voucher
	update := bson.M{
		"$set": bson.M{
			"name":        name,
			"description": description,
			"image":       imagePath,
			"points":      points,
			"updatedAt":   time.Now(),
		},
	}

	result, err := collection.UpdateByID(ctx, objID, update)
	if err != nil {
		// If database update fails and we uploaded a new image, delete it
		if files := form.File["image"]; len(files) > 0 && imagePath != currentVoucher.Image {
			os.Remove(strings.TrimPrefix(imagePath, "/uploads/"))
		}
		log.Printf("Error updating voucher: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update voucher",
			Data:    err.Error(),
		})
	}

	if result.MatchedCount == 0 {
		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Voucher not found",
		})
	}

	// Delete old image if we uploaded a new one
	if oldImagePath != "" && oldImagePath != imagePath {
		os.Remove(strings.TrimPrefix(oldImagePath, "/uploads/"))
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Voucher updated successfully",
	})
}

// DeleteVoucher deletes a voucher and its associated image (Admin only)
func (vc *VoucherController) DeleteVoucher(c echo.Context) error {
	// Check if user is admin
	claims := middleware.GetUserFromToken(c)
	if claims.UserType != "admin" && claims.UserType != "super_admin" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Access denied. Admin privileges required.",
		})
	}

	voucherID := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(voucherID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid voucher ID",
		})
	}

	collection := vc.DB.Collection("vouchers")
	ctx := context.Background()

	// First get the voucher to get the image path
	var voucher models.Voucher
	err = collection.FindOne(ctx, bson.M{"_id": objID}).Decode(&voucher)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Voucher not found",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve voucher",
			Data:    err.Error(),
		})
	}

	// Delete the voucher from database
	result, err := collection.DeleteOne(ctx, bson.M{"_id": objID})
	if err != nil {
		log.Printf("Error deleting voucher: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to delete voucher",
			Data:    err.Error(),
		})
	}

	if result.DeletedCount == 0 {
		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Voucher not found",
		})
	}

	// Delete the associated image file
	if voucher.Image != "" {
		imagePath := strings.TrimPrefix(voucher.Image, "/uploads/")
		if err := os.Remove(imagePath); err != nil {
			log.Printf("Warning: Failed to delete image file %s: %v", imagePath, err)
			// Don't return error here as the voucher was already deleted from database
		}
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Voucher deleted successfully",
	})
}

// ToggleVoucherStatus toggles the active status of a voucher (Admin only)
func (vc *VoucherController) ToggleVoucherStatus(c echo.Context) error {
	// Check if user is admin
	claims := middleware.GetUserFromToken(c)
	if claims.UserType != "admin" && claims.UserType != "super_admin" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Access denied. Admin privileges required.",
		})
	}

	voucherID := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(voucherID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid voucher ID",
		})
	}

	collection := vc.DB.Collection("vouchers")
	ctx := context.Background()

	// First, get the current status
	var voucher models.Voucher
	err = collection.FindOne(ctx, bson.M{"_id": objID}).Decode(&voucher)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Voucher not found",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve voucher",
			Data:    err.Error(),
		})
	}

	// Toggle the status
	newStatus := !voucher.IsActive
	update := bson.M{
		"$set": bson.M{
			"isActive":  newStatus,
			"updatedAt": time.Now(),
		},
	}

	_, err = collection.UpdateByID(ctx, objID, update)
	if err != nil {
		log.Printf("Error toggling voucher status: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to toggle voucher status",
			Data:    err.Error(),
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Voucher status updated successfully",
		Data: map[string]interface{}{
			"isActive": newStatus,
		},
	})
}

// GetAvailableVouchers retrieves all active vouchers for users
func (vc *VoucherController) GetAvailableVouchers(c echo.Context) error {
	collection := vc.DB.Collection("vouchers")
	ctx := context.Background()

	// Get user info to check their points
	claims := middleware.GetUserFromToken(c)
	userID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	// Get user's current points
	usersCollection := vc.DB.Collection("users")
	var user models.User
	err = usersCollection.FindOne(ctx, bson.M{"_id": userID}).Decode(&user)
	if err != nil {
		log.Printf("Error retrieving user: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve user information",
			Data:    err.Error(),
		})
	}

	// Get all active vouchers
	cursor, err := collection.Find(ctx, bson.M{"isActive": true})
	if err != nil {
		log.Printf("Error retrieving vouchers: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve vouchers",
			Data:    err.Error(),
		})
	}
	defer cursor.Close(ctx)

	var vouchers []models.Voucher
	if err = cursor.All(ctx, &vouchers); err != nil {
		log.Printf("Error decoding vouchers: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to decode vouchers",
			Data:    err.Error(),
		})
	}

	// Create user vouchers with purchase capability info
	var userVouchers []models.UserVoucher
	for _, voucher := range vouchers {
		canPurchase := user.Points >= voucher.Points
		userVouchers = append(userVouchers, models.UserVoucher{
			Voucher:     voucher,
			CanPurchase: canPurchase,
			UserPoints:  user.Points,
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Available vouchers retrieved successfully",
		Data: map[string]interface{}{
			"count":      len(userVouchers),
			"vouchers":   userVouchers,
			"userPoints": user.Points,
		},
	})
}

// PurchaseVoucher allows a user to purchase a voucher with points
func (vc *VoucherController) PurchaseVoucher(c echo.Context) error {
	claims := middleware.GetUserFromToken(c)
	userID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	var req models.VoucherPurchaseRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request body",
			Data:    err.Error(),
		})
	}

	// Validate request
	validate := validator.New()
	if err := validate.Struct(req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Validation failed",
			Data:    err.Error(),
		})
	}

	voucherID, err := primitive.ObjectIDFromHex(req.VoucherID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid voucher ID",
		})
	}

	ctx := context.Background()

	// Start a transaction
	session, err := vc.DB.Client().StartSession()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to start transaction",
		})
	}
	defer session.EndSession(ctx)

	_, err = session.WithTransaction(ctx, func(sc mongo.SessionContext) (interface{}, error) {
		// Get the voucher
		vouchersCollection := vc.DB.Collection("vouchers")
		var voucher models.Voucher
		err := vouchersCollection.FindOne(sc, bson.M{"_id": voucherID, "isActive": true}).Decode(&voucher)
		if err != nil {
			if err == mongo.ErrNoDocuments {
				return nil, echo.NewHTTPError(http.StatusNotFound, "Voucher not found or inactive")
			}
			return nil, err
		}

		// Get user's current points
		usersCollection := vc.DB.Collection("users")
		var user models.User
		err = usersCollection.FindOne(sc, bson.M{"_id": userID}).Decode(&user)
		if err != nil {
			return nil, err
		}

		// Check if user has enough points
		if user.Points < voucher.Points {
			return nil, echo.NewHTTPError(http.StatusBadRequest, "Insufficient points")
		}

		// Check if user already purchased this voucher
		purchasesCollection := vc.DB.Collection("voucher_purchases")
		var existingPurchase models.VoucherPurchase
		err = purchasesCollection.FindOne(sc, bson.M{
			"userId":    userID,
			"voucherId": voucherID,
		}).Decode(&existingPurchase)
		if err == nil {
			return nil, echo.NewHTTPError(http.StatusConflict, "You have already purchased this voucher")
		}

		// Create purchase record
		purchase := models.VoucherPurchase{
			ID:          primitive.NewObjectID(),
			UserID:      userID,
			VoucherID:   voucherID,
			PointsUsed:  voucher.Points,
			PurchasedAt: time.Now(),
			IsUsed:      false,
		}

		_, err = purchasesCollection.InsertOne(sc, purchase)
		if err != nil {
			return nil, err
		}

		// Deduct points from user
		_, err = usersCollection.UpdateByID(sc, userID, bson.M{
			"$inc": bson.M{"points": -voucher.Points},
		})
		if err != nil {
			return nil, err
		}

		return purchase, nil
	})

	if err != nil {
		if httpErr, ok := err.(*echo.HTTPError); ok {
			return c.JSON(httpErr.Code, models.Response{
				Status:  httpErr.Code,
				Message: httpErr.Message.(string),
			})
		}
		log.Printf("Error purchasing voucher: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to purchase voucher",
			Data:    err.Error(),
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Voucher purchased successfully",
	})
}

// GetUserVouchers retrieves all vouchers purchased by the current user
func (vc *VoucherController) GetUserVouchers(c echo.Context) error {
	claims := middleware.GetUserFromToken(c)
	userID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	ctx := context.Background()

	// Get user's purchased vouchers
	purchasesCollection := vc.DB.Collection("voucher_purchases")
	cursor, err := purchasesCollection.Find(ctx, bson.M{"userId": userID})
	if err != nil {
		log.Printf("Error retrieving user vouchers: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve user vouchers",
			Data:    err.Error(),
		})
	}
	defer cursor.Close(ctx)

	var purchases []models.VoucherPurchase
	if err = cursor.All(ctx, &purchases); err != nil {
		log.Printf("Error decoding purchases: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to decode purchases",
			Data:    err.Error(),
		})
	}

	// Get voucher details for each purchase
	var userVouchers []models.UserVoucher
	vouchersCollection := vc.DB.Collection("vouchers")

	for _, purchase := range purchases {
		var voucher models.Voucher
		err := vouchersCollection.FindOne(ctx, bson.M{"_id": purchase.VoucherID}).Decode(&voucher)
		if err != nil {
			log.Printf("Error retrieving voucher %s: %v", purchase.VoucherID.Hex(), err)
			continue
		}

		userVouchers = append(userVouchers, models.UserVoucher{
			Voucher:  voucher,
			Purchase: purchase,
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "User vouchers retrieved successfully",
		Data: map[string]interface{}{
			"count":    len(userVouchers),
			"vouchers": userVouchers,
		},
	})
}

// UseVoucher marks a voucher as used
func (vc *VoucherController) UseVoucher(c echo.Context) error {
	claims := middleware.GetUserFromToken(c)
	userID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	purchaseID := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(purchaseID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid purchase ID",
		})
	}

	ctx := context.Background()
	purchasesCollection := vc.DB.Collection("voucher_purchases")

	// Check if the purchase exists and belongs to the user
	var purchase models.VoucherPurchase
	err = purchasesCollection.FindOne(ctx, bson.M{
		"_id":    objID,
		"userId": userID,
	}).Decode(&purchase)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Voucher purchase not found",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve voucher purchase",
			Data:    err.Error(),
		})
	}

	// Check if already used
	if purchase.IsUsed {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Voucher has already been used",
		})
	}

	// Mark as used
	update := bson.M{
		"$set": bson.M{
			"isUsed": true,
			"usedAt": time.Now(),
		},
	}

	_, err = purchasesCollection.UpdateByID(ctx, objID, update)
	if err != nil {
		log.Printf("Error using voucher: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to use voucher",
			Data:    err.Error(),
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Voucher used successfully",
	})
}

// saveVoucherImage saves an uploaded voucher image and returns the file path
func (vc *VoucherController) saveVoucherImage(file *multipart.FileHeader) (string, error) {
	// Validate file size (max 5MB)
	if file.Size > 5*1024*1024 {
		return "", fmt.Errorf("file size exceeds 5MB limit")
	}

	// Validate file type
	src, err := file.Open()
	if err != nil {
		return "", fmt.Errorf("error opening file: %v", err)
	}
	defer src.Close()

	// Read first 512 bytes for mime type detection
	buffer := make([]byte, 512)
	_, err = src.Read(buffer)
	if err != nil {
		return "", fmt.Errorf("error reading file: %v", err)
	}

	// Detect mime type
	mimeType := http.DetectContentType(buffer)
	allowedMimeTypes := map[string]bool{
		"image/jpeg": true,
		"image/png":  true,
		"image/gif":  true,
		"image/webp": true,
	}

	if !allowedMimeTypes[mimeType] {
		return "", fmt.Errorf("invalid file type. Only JPEG, PNG, GIF and WebP images are allowed")
	}

	// Generate unique filename
	ext := filepath.Ext(file.Filename)
	uniqueFilename := fmt.Sprintf("voucher_%s%s", uuid.New().String(), ext)

	// Create uploads/vouchers directory if it doesn't exist
	uploadDir := "uploads/vouchers"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		return "", fmt.Errorf("error creating upload directory: %v", err)
	}

	// Create destination file
	dst, err := os.Create(filepath.Join(uploadDir, uniqueFilename))
	if err != nil {
		return "", fmt.Errorf("error creating file: %v", err)
	}
	defer dst.Close()

	// Reset file reader to beginning
	src.Seek(0, 0)

	// Copy file content
	if _, err = io.Copy(dst, src); err != nil {
		return "", fmt.Errorf("error copying file: %v", err)
	}

	// Return the relative path for storage in database
	return fmt.Sprintf("/uploads/vouchers/%s", uniqueFilename), nil
}
