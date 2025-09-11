package routes

import (
	"log"

	"github.com/HSouheill/barrim_backend/controllers"
	"github.com/HSouheill/barrim_backend/middleware"
	"github.com/labstack/echo/v4"
	"go.mongodb.org/mongo-driver/mongo"
)

// RegisterWholesalerRoutes sets up all wholesaler-related routes
func RegisterWholesalerRoutes(e *echo.Echo, db *mongo.Database, wholesalerVoucherController *controllers.WholesalerVoucherController) {
	log.Println("Registering wholesaler routes...")

	// Create controllers - use the same database instance
	wholesalerController := controllers.NewWholesalerController(db.Client())
	subscriptionController := controllers.NewSubscriptionController(db) // Use db directly
	wholesalerSubscriptionController := controllers.NewWholesalerSubscriptionController(db)
	wholesalerBranchSubscriptionController := controllers.NewWholesalerBranchSubscriptionController(db)
	// Wholesaler routes group
	wholesaler := e.Group("/api/wholesaler")
	log.Println("Created wholesaler group at /api/wholesaler")

	// Protected routes (require wholesaler authentication)
	protected := wholesaler.Group("")
	protected.Use(middleware.JWTMiddleware())
	protected.Use(middleware.RequireUserType("wholesaler"))
	protected.Use(middleware.DebugMiddleware())
	log.Println("Added middleware to protected group")

	// Subscription routes
	protected.GET("/subscriptions/plans", subscriptionController.GetWholesalerPlans)
	protected.GET("/subscription-plans", wholesalerSubscriptionController.GetAvailablePlans)
	protected.POST("/subscription", subscriptionController.CreateWholesalerSubscription)
	protected.GET("/subscription/current", subscriptionController.GetCurrentWholesalerSubscription)

	protected.DELETE("/subscription/cancel", subscriptionController.CancelWholesalerSubscription)
	log.Println("Registered subscription endpoints")

	// Wholesaler profile routes
	protected.GET("/data", wholesalerController.GetWholesalerData)
	protected.GET("/full-data", wholesalerController.GetFullWholesalerData)
	protected.PUT("/data", wholesalerController.UpdateWholesalerData)
	protected.PUT("/details", wholesalerController.ChangeWholesalerDetails)

	// Branch management routes
	protected.POST("/branches", wholesalerController.AddBranch)
	protected.PUT("/branches/:id", wholesalerController.EditBranch)
	protected.GET("/branches", wholesalerController.GetBranches)
	protected.GET("/branches/:id", wholesalerController.GetBranch)
	protected.DELETE("/branches/:id", wholesalerController.DeleteBranch)

	log.Println("Finished registering all wholesaler routes")

	wholesalerGroup := wholesaler.Group("")
	wholesalerGroup.Use(middleware.JWTMiddleware())
	wholesalerGroup.Use(middleware.RequireUserType("wholesaler"))
	protected.Use(middleware.DebugMiddleware())
	wholesalerGroup.Use(middleware.DebugMiddleware())

	wholesalerGroup.POST("/subscription/:branchId/request", wholesalerBranchSubscriptionController.CreateBranchSubscriptionRequest)
	wholesalerGroup.GET("/subscription/request/:branchId/status", wholesalerBranchSubscriptionController.GetBranchSubscriptionRequestStatus)
	wholesalerGroup.POST("/subscription/:branchId/cancel", wholesalerBranchSubscriptionController.CancelBranchSubscription)
	wholesalerGroup.GET("/subscription/:branchId/remaining-time", wholesalerBranchSubscriptionController.GetBranchSubscriptionRemainingTime)

	// Sponsorship routes for wholesaler branches
	wholesalerGroup.POST("/sponsorship/:branchId/request", wholesalerBranchSubscriptionController.CreateWholesalerBranchSponsorshipRequest)

	// ============= Voucher Routes =============
	
	// Wholesaler voucher routes
	protected.GET("/vouchers/available", wholesalerVoucherController.GetAvailableVouchersForWholesaler)
	protected.POST("/vouchers/purchase", wholesalerVoucherController.PurchaseVoucherForWholesaler)
	protected.GET("/vouchers/purchased", wholesalerVoucherController.GetWholesalerVouchers)
	protected.PUT("/vouchers/:id/use", wholesalerVoucherController.UseVoucherForWholesaler)

	log.Println("Registered wholesaler voucher endpoints")

}
