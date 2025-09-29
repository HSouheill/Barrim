// controllers/serviceProviders_controller.go
package controllers

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/HSouheill/barrim_backend/middleware"
	"github.com/HSouheill/barrim_backend/models"
	"github.com/labstack/echo/v4"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type ServiceProviderController struct {
	DB *mongo.Database
}

// ServiceProviderFullData represents the complete service provider data including related entities
type ServiceProviderFullData struct {
	ServiceProvider  models.ServiceProvider                      `json:"serviceProvider"`
	Subscriptions    []models.ServiceProviderSubscription        `json:"subscriptions,omitempty"`
	SubscriptionReqs []models.ServiceProviderSubscriptionRequest `json:"subscriptionRequests,omitempty"`
}

func NewServiceProviderController(client *mongo.Client) *ServiceProviderController {
	return &ServiceProviderController{DB: client.Database("barrim")}
}

// GetFullServiceProviderData retrieves complete service provider data including subscriptions and requests
func (spc *ServiceProviderController) GetFullServiceProviderData(c echo.Context) error {
	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	// Get user information from token
	claims := middleware.GetUserFromToken(c)
	userID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	// Initialize the response structure
	var result ServiceProviderFullData

	// Get service provider data
	err = spc.DB.Collection("serviceProviders").FindOne(ctx, bson.M{
		"$or": []bson.M{
			{"userId": userID},
			{"createdBy": userID},
		},
	}).Decode(&result.ServiceProvider)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve service provider data",
		})
	}

	// Get service provider subscriptions
	subscriptionCursor, err := spc.DB.Collection("serviceProviderSubscriptions").Find(ctx, bson.M{"serviceProviderId": result.ServiceProvider.ID})
	if err != nil && err != mongo.ErrNoDocuments {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve subscriptions",
		})
	}
	if err == nil {
		defer subscriptionCursor.Close(ctx)
		if err = subscriptionCursor.All(ctx, &result.Subscriptions); err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to decode subscriptions",
			})
		}
	}

	// Get subscription requests
	reqCursor, err := spc.DB.Collection("serviceProviderSubscriptionRequests").Find(ctx, bson.M{"serviceProviderId": result.ServiceProvider.ID})
	if err != nil && err != mongo.ErrNoDocuments {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve subscription requests",
		})
	}
	if err == nil {
		defer reqCursor.Close(ctx)
		if err = reqCursor.All(ctx, &result.SubscriptionReqs); err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to decode subscription requests",
			})
		}
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Complete service provider data retrieved successfully",
		Data:    result,
	})
}

func (spc *ServiceProviderController) GetServiceProviderData(c echo.Context) error {
	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	claims := middleware.GetUserFromToken(c)
	userID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	var serviceProvider models.ServiceProvider
	// First try to find by userId (standard approach)
	err = spc.DB.Collection("serviceProviders").FindOne(ctx, bson.M{"userId": userID}).Decode(&serviceProvider)
	if err != nil {
		// If not found by userId, try to find by CreatedBy (salesperson-created service providers)
		err = spc.DB.Collection("serviceProviders").FindOne(ctx, bson.M{"createdBy": userID}).Decode(&serviceProvider)
		if err != nil {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Service provider data retrieved successfully",
		Data:    serviceProvider,
	})
}

func (spc *ServiceProviderController) UpdateServiceProviderData(c echo.Context) error {
	claims := middleware.GetUserFromToken(c)
	userID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	var updateData models.ServiceProvider
	if err := c.Bind(&updateData); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request data",
		})
	}

	updateData.UpdatedAt = time.Now()
	result, err := spc.DB.Collection("serviceProviders").UpdateOne(
		context.Background(),
		bson.M{"userId": userID},
		bson.M{"$set": updateData},
	)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update service provider data",
		})
	}

	if result.MatchedCount == 0 {
		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Service provider not found",
		})
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Service provider data updated successfully",
	})
}

func (spc *ServiceProviderController) UploadLogo(c echo.Context) error {
	// TODO: Implement logo upload functionality
	return c.JSON(http.StatusNotImplemented, models.Response{
		Status:  http.StatusNotImplemented,
		Message: "Logo upload not implemented yet",
	})
}

// ToggleEntityStatus allows service providers to toggle their own status or admins/managers to toggle any service provider status
func (spc *ServiceProviderController) ToggleEntityStatus(c echo.Context) error {
	claims := middleware.GetUserFromToken(c)

	// Get the service provider ID from URL parameter
	serviceProviderID := c.Param("id")
	if serviceProviderID == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Service provider ID is required",
		})
	}

	objID, err := primitive.ObjectIDFromHex(serviceProviderID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid service provider ID format",
		})
	}

	// Check if the user is trying to toggle their own status or if they have admin/manager privileges
	userID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	// If user is a service provider, they can only toggle their own status
	if claims.UserType == "serviceProvider" {
		// Check if the service provider is trying to toggle their own status
		var serviceProvider models.ServiceProvider
		err = spc.DB.Collection("serviceProviders").FindOne(context.Background(), bson.M{"_id": objID}).Decode(&serviceProvider)
		if err != nil {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}

		if serviceProvider.UserID != userID {
			return c.JSON(http.StatusForbidden, models.Response{
				Status:  http.StatusForbidden,
				Message: "Service providers can only toggle their own status",
			})
		}
	} else if claims.UserType == "admin" {
		// Admin can toggle any service provider status
	} else if claims.UserType == "manager" {
		// Check if manager has business_management role
		var manager models.Manager
		err := spc.DB.Collection("managers").FindOne(context.Background(), bson.M{"_id": userID}).Decode(&manager)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to fetch manager",
			})
		}

		// Check if manager has business_management role
		hasBusinessManagement := false
		for _, role := range manager.RolesAccess {
			if role == "business_management" {
				hasBusinessManagement = true
				break
			}
		}

		if !hasBusinessManagement {
			return c.JSON(http.StatusForbidden, models.Response{
				Status:  http.StatusForbidden,
				Message: "Manager does not have business_management role",
			})
		}
	} else if claims.UserType == "sales_manager" {
		// Check if sales manager has business_management role
		var salesManager models.SalesManager
		err := spc.DB.Collection("sales_managers").FindOne(context.Background(), bson.M{"_id": userID}).Decode(&salesManager)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to fetch sales manager",
			})
		}

		// Check if sales manager has business_management role
		hasBusinessManagement := false
		for _, role := range salesManager.RolesAccess {
			if role == "business_management" {
				hasBusinessManagement = true
				break
			}
		}

		if !hasBusinessManagement {
			return c.JSON(http.StatusForbidden, models.Response{
				Status:  http.StatusForbidden,
				Message: "Sales manager does not have business_management role",
			})
		}
	} else {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Only service providers, admins, managers, or sales managers can toggle service provider status",
		})
	}

	// Parse request body
	var req struct {
		Status string `json:"status"`
	}
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request body",
		})
	}

	// Validate status
	if req.Status != "active" && req.Status != "inactive" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Status must be 'active' or 'inactive'",
		})
	}

	// Update the service provider status
	update := bson.M{"$set": bson.M{"status": req.Status, "updatedAt": time.Now()}}
	result, err := spc.DB.Collection("serviceProviders").UpdateOne(
		context.Background(),
		bson.M{"_id": objID},
		update,
	)
	if err != nil {
		log.Printf("Failed to update service provider status: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update service provider status",
		})
	}

	if result.MatchedCount == 0 {
		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Service provider not found",
		})
	}

	// Log the action
	log.Printf("Service provider status updated: ID=%s, Status=%s, UpdatedBy=%s",
		serviceProviderID, req.Status, claims.UserID)

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: fmt.Sprintf("Service provider status updated to '%s' successfully", req.Status),
	})
}

// UpdateServiceProviderDescription allows service providers to update their description
func (spc *ServiceProviderController) UpdateServiceProviderDescription(c echo.Context) error {
	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Get user information from token
	claims := middleware.GetUserFromToken(c)
	userID, err := primitive.ObjectIDFromHex(claims.UserID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid user ID",
		})
	}

	// Parse request body
	var req struct {
		Description string `json:"description"`
	}
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request body",
		})
	}

	// Validate description length (optional validation)
	if len(req.Description) > 1000 {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Description must be less than 1000 characters",
		})
	}

	// Find the service provider first to ensure it exists
	var serviceProvider models.ServiceProvider
	err = spc.DB.Collection("serviceProviders").FindOne(ctx, bson.M{
		"$or": []bson.M{
			{"userId": userID},
			{"createdBy": userID},
		},
	}).Decode(&serviceProvider)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Service provider not found",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to find service provider",
		})
	}

	// Update the description in the serviceProviderInfo field
	update := bson.M{
		"$set": bson.M{
			"serviceProviderInfo.description": req.Description,
			"updatedAt":                       time.Now(),
		},
	}

	result, err := spc.DB.Collection("serviceProviders").UpdateOne(
		ctx,
		bson.M{"_id": serviceProvider.ID},
		update,
	)

	if err != nil {
		log.Printf("Failed to update service provider description: %v", err)
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update service provider description",
		})
	}

	if result.MatchedCount == 0 {
		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Service provider not found",
		})
	}

	// Log the action
	log.Printf("Service provider description updated: ID=%s, UpdatedBy=%s",
		serviceProvider.ID.Hex(), claims.UserID)

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Service provider description updated successfully",
	})
}
