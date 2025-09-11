package controllers

import (
	"context"
	"log"
	"net/http"
	"time"

	"github.com/HSouheill/barrim_backend/middleware"
	"github.com/HSouheill/barrim_backend/models"
	"github.com/go-playground/validator/v10"
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

// CreateVoucher creates a new voucher (Admin only)
func (vc *VoucherController) CreateVoucher(c echo.Context) error {
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
		Image:       req.Image,
		Price:       req.Price,
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

// UpdateVoucher updates an existing voucher (Admin only)
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

	// Update voucher
	collection := vc.DB.Collection("vouchers")
	ctx := context.Background()

	update := bson.M{
		"$set": bson.M{
			"name":        req.Name,
			"description": req.Description,
			"image":       req.Image,
			"price":       req.Price,
			"updatedAt":   time.Now(),
		},
	}

	result, err := collection.UpdateByID(ctx, objID, update)
	if err != nil {
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

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Voucher updated successfully",
	})
}

// DeleteVoucher deletes a voucher (Admin only)
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
		canPurchase := user.Points >= voucher.Price
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
		if user.Points < voucher.Price {
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
			PointsUsed:  voucher.Price,
			PurchasedAt: time.Now(),
			IsUsed:      false,
		}

		_, err = purchasesCollection.InsertOne(sc, purchase)
		if err != nil {
			return nil, err
		}

		// Deduct points from user
		_, err = usersCollection.UpdateByID(sc, userID, bson.M{
			"$inc": bson.M{"points": -voucher.Price},
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
