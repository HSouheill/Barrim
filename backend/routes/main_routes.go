package routes

import (
	"github.com/labstack/echo/v4"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/HSouheill/barrim_backend/controllers"
	"github.com/HSouheill/barrim_backend/websocket"
)

// SetupRoutes configures all API routes by calling individual route registration functions
func SetupRoutes(e *echo.Echo, db *mongo.Client, hub *websocket.Hub, authController *controllers.AuthController, userController *controllers.UserController) {
	// Initialize WebSocket hub
	wsHub := websocket.NewHub()
	go wsHub.Run()

	// Register all route groups
	RegisterAuthRoutes(e, db, authController, userController)
	RegisterUserRoutes(e, db, userController, hub)
	RegisterSalesRoutes(e, db)
	RegisterSubscriptionRoutes(e, db)
	RegisterFileRoutes(e)
	RegisterCategoryRoutes(e, db.Database("barrim"))
	RegisterServiceProviderCategoryRoutes(e, db.Database("barrim"))
	RegisterWholesalerCategoryRoutes(e, db.Database("barrim"))

	// Register existing route files
	RegisterAdminRoutes(e, db.Database("barrim"))
	RegisterServiceProviderRoutes(e, db.Database("barrim"))
	RegisterWholesalerRoutes(e, db.Database("barrim"))
	// Note: Company routes and Wholesaler referral routes are registered in main.go
}
