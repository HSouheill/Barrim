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

type ServiceProviderVoucherController struct {
	DB *mongo.Database
}

func NewServiceProviderVoucherController(db *mongo.Database) *ServiceProviderVoucherController {
	return &ServiceProviderVoucherController{DB: db}
}

// GetAvailableVouchersForServiceProvider retrieves all active vouchers for service providers
func (spvc *ServiceProviderVoucherController) GetAvailableVouchersForServiceProvider(c echo.Context) error {
	collection := spvc.DB.Collection("vouchers")
	ctx := context.Background()

	// Get service provider info to check their points
	claims := middleware.GetUserFromToken(c)
	serviceProviderID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid service provider ID",
		})
	}

	// Get service provider's current points
	serviceProvidersCollection := spvc.DB.Collection("serviceproviders")
	var serviceProvider models.ServiceProvider
	err = serviceProvidersCollection.FindOne(ctx, bson.M{"_id": serviceProviderID}).Decode(&serviceProvider)
	if err != nil {
		log.Printf("Error retrieving service provider: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve service provider information",
			Data:    err.Error(),
		})
	}

	// Get vouchers available for this service provider (either global service provider vouchers or specific to this service provider)
	cursor, err := collection.Find(ctx, bson.M{
		"isActive": true,
		"$or": []bson.M{
			{
				"targetUserType": "serviceProvider",
				"isGlobal":       true,
			},
			{
				"targetUserType": "serviceProvider",
				"targetUserId":   serviceProviderID,
			},
		},
	})
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

	// Create service provider vouchers with purchase capability info
	var serviceProviderVouchers []models.ServiceProviderVoucher
	for _, voucher := range vouchers {
		canPurchase := serviceProvider.Points >= voucher.Points
		serviceProviderVouchers = append(serviceProviderVouchers, models.ServiceProviderVoucher{
			Voucher:               voucher,
			CanPurchase:           canPurchase,
			ServiceProviderPoints: serviceProvider.Points,
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Available vouchers retrieved successfully",
		Data: map[string]interface{}{
			"count":                 len(serviceProviderVouchers),
			"vouchers":              serviceProviderVouchers,
			"serviceProviderPoints": serviceProvider.Points,
		},
	})
}

// PurchaseVoucherForServiceProvider allows a service provider to purchase a voucher with points
func (spvc *ServiceProviderVoucherController) PurchaseVoucherForServiceProvider(c echo.Context) error {
	claims := middleware.GetUserFromToken(c)
	serviceProviderID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid service provider ID",
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
	session, err := spvc.DB.Client().StartSession()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to start transaction",
		})
	}
	defer session.EndSession(ctx)

	_, err = session.WithTransaction(ctx, func(sc mongo.SessionContext) (interface{}, error) {
		// Get the voucher
		vouchersCollection := spvc.DB.Collection("vouchers")
		var voucher models.Voucher
		err := vouchersCollection.FindOne(sc, bson.M{"_id": voucherID, "isActive": true}).Decode(&voucher)
		if err != nil {
			if err == mongo.ErrNoDocuments {
				return nil, echo.NewHTTPError(http.StatusNotFound, "Voucher not found or inactive")
			}
			return nil, err
		}

		// Get service provider's current points
		serviceProvidersCollection := spvc.DB.Collection("serviceproviders")
		var serviceProvider models.ServiceProvider
		err = serviceProvidersCollection.FindOne(sc, bson.M{"_id": serviceProviderID}).Decode(&serviceProvider)
		if err != nil {
			return nil, err
		}

		// Check if service provider has enough points
		if serviceProvider.Points < voucher.Points {
			return nil, echo.NewHTTPError(http.StatusBadRequest, "Insufficient points")
		}

		// Check if service provider already purchased this voucher
		purchasesCollection := spvc.DB.Collection("service_provider_voucher_purchases")
		var existingPurchase models.ServiceProviderVoucherPurchase
		err = purchasesCollection.FindOne(sc, bson.M{
			"serviceProviderId": serviceProviderID,
			"voucherId":         voucherID,
		}).Decode(&existingPurchase)
		if err == nil {
			return nil, echo.NewHTTPError(http.StatusConflict, "You have already purchased this voucher")
		}

		// Create purchase record
		purchase := models.ServiceProviderVoucherPurchase{
			ID:                primitive.NewObjectID(),
			ServiceProviderID: serviceProviderID,
			VoucherID:         voucherID,
			PointsUsed:        voucher.Points,
			PurchasedAt:       time.Now(),
			IsUsed:            false,
		}

		_, err = purchasesCollection.InsertOne(sc, purchase)
		if err != nil {
			return nil, err
		}

		// Deduct points from service provider
		_, err = serviceProvidersCollection.UpdateByID(sc, serviceProviderID, bson.M{
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

// GetServiceProviderVouchers retrieves all vouchers purchased by the current service provider
func (spvc *ServiceProviderVoucherController) GetServiceProviderVouchers(c echo.Context) error {
	claims := middleware.GetUserFromToken(c)
	serviceProviderID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid service provider ID",
		})
	}

	ctx := context.Background()

	// Get service provider's purchased vouchers
	purchasesCollection := spvc.DB.Collection("service_provider_voucher_purchases")
	cursor, err := purchasesCollection.Find(ctx, bson.M{"serviceProviderId": serviceProviderID})
	if err != nil {
		log.Printf("Error retrieving service provider vouchers: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve service provider vouchers",
			Data:    err.Error(),
		})
	}
	defer cursor.Close(ctx)

	var purchases []models.ServiceProviderVoucherPurchase
	if err = cursor.All(ctx, &purchases); err != nil {
		log.Printf("Error decoding purchases: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to decode purchases",
			Data:    err.Error(),
		})
	}

	// Get voucher details for each purchase
	var serviceProviderVouchers []models.ServiceProviderVoucher
	vouchersCollection := spvc.DB.Collection("vouchers")

	for _, purchase := range purchases {
		var voucher models.Voucher
		err := vouchersCollection.FindOne(ctx, bson.M{"_id": purchase.VoucherID}).Decode(&voucher)
		if err != nil {
			log.Printf("Error retrieving voucher %s: %v", purchase.VoucherID.Hex(), err)
			continue
		}

		serviceProviderVouchers = append(serviceProviderVouchers, models.ServiceProviderVoucher{
			Voucher:  voucher,
			Purchase: purchase,
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Service provider vouchers retrieved successfully",
		Data: map[string]interface{}{
			"count":    len(serviceProviderVouchers),
			"vouchers": serviceProviderVouchers,
		},
	})
}

// UseVoucherForServiceProvider marks a voucher as used by a service provider
func (spvc *ServiceProviderVoucherController) UseVoucherForServiceProvider(c echo.Context) error {
	claims := middleware.GetUserFromToken(c)
	serviceProviderID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid service provider ID",
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
	purchasesCollection := spvc.DB.Collection("service_provider_voucher_purchases")

	// Check if the purchase exists and belongs to the service provider
	var purchase models.ServiceProviderVoucherPurchase
	err = purchasesCollection.FindOne(ctx, bson.M{
		"_id":               objID,
		"serviceProviderId": serviceProviderID,
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
