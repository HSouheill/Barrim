package controllers

import (
	"context"
	"encoding/base64"
	"fmt"
	"log"
	"net/http"
	"path/filepath"
	"strconv"
	"time"

	"github.com/HSouheill/barrim_backend/models"
	"github.com/HSouheill/barrim_backend/utils"
	"github.com/HSouheill/barrim_backend/websocket"
	"github.com/labstack/echo/v4"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// BookingController handles booking-related API endpoints
type BookingController struct {
	db  *mongo.Client
	hub *websocket.Hub
}

// NewBookingController creates a new booking controller
func NewBookingController(db *mongo.Client, hub *websocket.Hub) *BookingController {
	return &BookingController{db: db, hub: hub}
}

// CreateBooking handles the creation of a new booking
func (c *BookingController) CreateBooking(ctx echo.Context) error {
	// Get user from token
	user, err := utils.GetUserFromToken(ctx, c.db)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Unauthorized",
		})
	}

	// Parse request body
	var request models.BookingRequest
	if err := ctx.Bind(&request); err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request",
		})
	}

	// Handle media upload if present
	var mediaTypes, mediaURLs, thumbnailURLs []string
	if len(request.MediaFiles) > 0 {
		for i := range request.MediaFiles {
			mediaType := "image"
			if len(request.MediaTypes) > i {
				mediaType = request.MediaTypes[i]
			}
			if mediaType != "image" && mediaType != "video" {
				return ctx.JSON(http.StatusBadRequest, models.Response{
					Status:  http.StatusBadRequest,
					Message: "Invalid media type. Must be 'image' or 'video'",
				})
			}

			decodedFile, err := base64.StdEncoding.DecodeString(request.MediaFiles[i])
			if err != nil {
				return ctx.JSON(http.StatusBadRequest, models.Response{
					Status:  http.StatusBadRequest,
					Message: "Invalid media file format",
				})
			}

			timestamp := time.Now().Unix()
			uniqueID := primitive.NewObjectID().Hex()
			fileExt := ".jpg"
			if len(request.MediaFileNames) > i {
				fileExt = filepath.Ext(request.MediaFileNames[i])
			}
			if fileExt == "" {
				if mediaType == "image" {
					fileExt = ".jpg"
				} else {
					fileExt = ".mp4"
				}
			}
			filename := fmt.Sprintf("bookings/%s/%d_%s%s",
				user.ID.Hex(),
				timestamp,
				uniqueID,
				fileExt,
			)

			mediaURL, err := utils.UploadFile(decodedFile, filename, mediaType)
			if err != nil {
				return ctx.JSON(http.StatusInternalServerError, models.Response{
					Status:  http.StatusInternalServerError,
					Message: fmt.Sprintf("Failed to upload media file: %v", err),
				})
			}
			mediaTypes = append(mediaTypes, mediaType)
			mediaURLs = append(mediaURLs, mediaURL)

			if mediaType == "video" {
				thumbnailURL, err := utils.GenerateVideoThumbnail(mediaURL)
				if err != nil {
					log.Printf("Failed to generate video thumbnail: %v", err)
					thumbnailURLs = append(thumbnailURLs, "")
				} else {
					thumbnailURLs = append(thumbnailURLs, thumbnailURL)
				}
			} else {
				thumbnailURLs = append(thumbnailURLs, "")
			}
		}
	}

	// Validate service provider ID
	serviceProviderID, err := primitive.ObjectIDFromHex(request.ServiceProviderID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid service provider ID",
		})
	}

	// Check if service provider exists
	serviceProviderCollection := c.db.Database("barrim").Collection("serviceProviders")
	var serviceProvider models.ServiceProvider
	err = serviceProviderCollection.FindOne(context.Background(), bson.M{
		"_id": serviceProviderID,
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
			Message: "Error finding service provider",
		})
	}

	// Get user data for availability check
	var userData *models.User
	if !serviceProvider.UserID.IsZero() {
		userCollection := c.db.Database("barrim").Collection("users")
		var user models.User
		err = userCollection.FindOne(context.Background(), bson.M{"_id": serviceProvider.UserID}).Decode(&user)
		if err == nil {
			userData = &user
		}
	}

	// Check service provider availability
	if userData == nil || !isProviderAvailable(*userData, request.BookingDate, request.TimeSlot) {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Service provider is not available at this time",
		})
	}

	// Check if the time slot is already booked
	bookingsCollection := c.db.Database("barrim").Collection("bookings")
	bookingDate := time.Date(
		request.BookingDate.Year(),
		request.BookingDate.Month(),
		request.BookingDate.Day(),
		0, 0, 0, 0,
		request.BookingDate.Location(),
	)

	// Check if the time slot is already booked
	var existingBooking models.Booking
	err = bookingsCollection.FindOne(context.Background(), bson.M{
		"serviceProviderId": serviceProviderID,
		"bookingDate":       bookingDate,
		"timeSlot":          request.TimeSlot,
		"status":            bson.M{"$ne": "cancelled"},
	}).Decode(&existingBooking)

	if err == nil {
		// Found an existing booking for this time slot
		return ctx.JSON(http.StatusConflict, models.Response{
			Status:  http.StatusConflict,
			Message: "This time slot is already booked",
		})
	} else if err != mongo.ErrNoDocuments {
		// A database error occurred
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error checking booking availability",
		})
	}

	// Create new booking
	now := time.Now()
	booking := models.Booking{
		ID:                primitive.NewObjectID(),
		UserID:            user.ID,
		ServiceProviderID: serviceProviderID,
		BookingDate:       bookingDate,
		TimeSlot:          request.TimeSlot,
		PhoneNumber:       request.PhoneNumber,
		Details:           request.Details,
		IsEmergency:       request.IsEmergency,
		Status:            "pending",
		MediaTypes:        mediaTypes,
		MediaURLs:         mediaURLs,
		ThumbnailURLs:     thumbnailURLs,
		CreatedAt:         now,
		UpdatedAt:         now,
	}

	// Insert booking into database
	_, err = bookingsCollection.InsertOne(context.Background(), booking)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to create booking",
		})
	}

	if err := c.hub.SendToUser(serviceProviderID, websocket.Notification{
		Type:    "new_booking",
		Message: "You have a new booking request",
		Data:    booking,
	}); err != nil {
		log.Printf("Failed to send WebSocket notification to service provider: %v", err)
		// Optionally, fall back to another notification method (e.g., email or FCM)
	}

	return ctx.JSON(http.StatusCreated, models.BookingResponse{
		Status:  http.StatusCreated,
		Message: "Booking created successfully",
		Data:    &booking,
	})
}

// GetUserBookings retrieves all bookings for the authenticated user
func (c *BookingController) GetUserBookings(ctx echo.Context) error {
	// Get user from token
	user, err := utils.GetUserFromToken(ctx, c.db)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Unauthorized",
		})
	}

	// Retrieve bookings from database
	collection := c.db.Database("barrim").Collection("bookings")
	cursor, err := collection.Find(context.Background(), bson.M{"userId": user.ID})
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error retrieving bookings",
		})
	}
	defer cursor.Close(context.Background())

	// Decode bookings
	var bookings []models.Booking
	if err := cursor.All(context.Background(), &bookings); err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error decoding bookings",
		})
	}

	return ctx.JSON(http.StatusOK, models.BookingsResponse{
		Status:  http.StatusOK,
		Message: "Bookings retrieved successfully",
		Data:    bookings,
	})
}

// GetProviderBookings retrieves all bookings for a service provider
func (c *BookingController) GetProviderBookings(ctx echo.Context) error {
	// Get user from token
	user, err := utils.GetUserFromToken(ctx, c.db)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Unauthorized",
		})
	}

	// Ensure user is a service provider
	if user.UserType != "serviceProvider" {
		return ctx.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Only service providers can access their bookings",
		})
	}

	// Retrieve bookings from database
	collection := c.db.Database("barrim").Collection("bookings")
	cursor, err := collection.Find(context.Background(), bson.M{"serviceProviderId": user.ID})
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error retrieving bookings",
		})
	}
	defer cursor.Close(context.Background())

	// Decode bookings
	var bookings []models.Booking
	if err := cursor.All(context.Background(), &bookings); err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error decoding bookings",
		})
	}

	return ctx.JSON(http.StatusOK, models.BookingsResponse{
		Status:  http.StatusOK,
		Message: "Bookings retrieved successfully",
		Data:    bookings,
	})
}

// GetAvailableTimeSlots returns available time slots for a service provider on a specific date
// GetAvailableTimeSlots returns available time slots for a service provider on a specific date
func (c *BookingController) GetAvailableTimeSlots(ctx echo.Context) error {
	// Extract parameters
	providerID := ctx.Param("id")
	dateStr := ctx.QueryParam("date")

	// Validate service provider ID
	serviceProviderID, err := primitive.ObjectIDFromHex(providerID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid service provider ID",
		})
	}

	// Parse date
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid date format. Use YYYY-MM-DD",
		})
	}

	// Get service provider details from serviceProviders collection
	serviceProviderCollection := c.db.Database("barrim").Collection("serviceProviders")
	var serviceProvider models.ServiceProvider
	err = serviceProviderCollection.FindOne(context.Background(), bson.M{
		"_id": serviceProviderID,
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
			Message: "Error finding service provider",
		})
	}

	// Get additional user data if userId exists
	var userData *models.User
	if !serviceProvider.UserID.IsZero() {
		userCollection := c.db.Database("barrim").Collection("users")
		var user models.User
		err = userCollection.FindOne(context.Background(), bson.M{"_id": serviceProvider.UserID}).Decode(&user)
		if err == nil {
			userData = &user
		}
	}

	// Check if the provider is available on this date (by checking availableDays)
	dateStr = date.Format("2006-01-02")
	isDateAvailable := false

	// First check availableDays from user data
	if userData != nil && userData.ServiceProviderInfo != nil && userData.ServiceProviderInfo.AvailableDays != nil {
		for _, availableDate := range userData.ServiceProviderInfo.AvailableDays {
			if availableDate == dateStr {
				isDateAvailable = true
				break
			}
		}
	}

	// If not directly in availableDays, check if the weekday is available
	if !isDateAvailable && userData != nil && userData.ServiceProviderInfo != nil && userData.ServiceProviderInfo.AvailableWeekdays != nil {
		dayOfWeek := date.Weekday().String()
		for _, weekday := range userData.ServiceProviderInfo.AvailableWeekdays {
			if weekday == dayOfWeek {
				isDateAvailable = true
				break
			}
		}
	}

	if !isDateAvailable {
		return ctx.JSON(http.StatusOK, models.Response{
			Status:  http.StatusOK,
			Message: "No available slots on this day",
			Data:    []string{},
		})
	}

	// Generate time slots based on provider's available hours
	var startHour, endHour time.Time
	var availableSlots []string

	// Get available hours from user data
	if userData != nil && userData.ServiceProviderInfo != nil && len(userData.ServiceProviderInfo.AvailableHours) >= 2 {
		// Parse start and end hours from provider's available hours (format: "09:00", "17:00")
		startTimeStr := userData.ServiceProviderInfo.AvailableHours[0]
		endTimeStr := userData.ServiceProviderInfo.AvailableHours[1]

		// Parse times in 24-hour format
		startHour, err = time.Parse("15:04", startTimeStr)
		if err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Error parsing provider start time",
			})
		}

		endHour, err = time.Parse("15:04", endTimeStr)
		if err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Error parsing provider end time",
			})
		}

		// Generate time slots at 30-minute intervals
		for h := startHour; h.Before(endHour); h = h.Add(30 * time.Minute) {
			// Format time as "3:04 PM" for UI display
			timeSlot := h.Format("3:04 PM")
			availableSlots = append(availableSlots, timeSlot)
		}
	} else {
		// Default time slots if provider hasn't specified hours
		availableSlots = []string{
			"9:00 AM", "9:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM",
			"1:00 PM", "1:30 PM", "2:00 PM", "2:30 PM", "3:00 PM", "3:30 PM",
			"4:00 PM", "4:30 PM", "5:00 PM",
		}
	}

	// Get bookings for this provider on this date to filter out booked slots
	bookingsCollection := c.db.Database("barrim").Collection("bookings")
	bookingDate := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location())

	cursor, err := bookingsCollection.Find(context.Background(), bson.M{
		"serviceProviderId": serviceProviderID,
		"bookingDate":       bookingDate,
		"status":            bson.M{"$ne": "cancelled"},
	})

	if err != nil && err != mongo.ErrNoDocuments {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error retrieving bookings",
		})
	}

	// Get booked time slots
	var bookings []models.Booking
	if err != mongo.ErrNoDocuments {
		defer cursor.Close(context.Background())
		if err := cursor.All(context.Background(), &bookings); err != nil {
			return ctx.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Error decoding bookings",
			})
		}
	}

	// Filter out booked slots
	bookedSlots := make(map[string]bool)
	for _, booking := range bookings {
		bookedSlots[booking.TimeSlot] = true
	}

	var freeSlots []string
	for _, slot := range availableSlots {
		if !bookedSlots[slot] {
			freeSlots = append(freeSlots, slot)
		}
	}

	// Filter out past time slots if the date is today
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

	if bookingDate.Equal(today) {
		var filteredSlots []string
		currentHour := now.Hour()
		currentMinute := now.Minute()

		for _, slot := range freeSlots {
			// Parse time like "9:00 AM" or "1:30 PM"
			timeComponents, err := time.Parse("3:04 PM", slot)
			if err == nil {
				slotHour := timeComponents.Hour()
				slotMinute := timeComponents.Minute()

				// If slot time is after current time, keep it
				if slotHour > currentHour || (slotHour == currentHour && slotMinute > currentMinute) {
					filteredSlots = append(filteredSlots, slot)
				}
			}
		}
		freeSlots = filteredSlots
	}

	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Available time slots retrieved successfully",
		Data:    freeSlots,
	})
}

// UpdateBookingStatus updates the status of a booking
func (c *BookingController) UpdateBookingStatus(ctx echo.Context) error {
	// Get user from token
	user, err := utils.GetUserFromToken(ctx, c.db)
	if err != nil {
		return ctx.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Unauthorized",
		})
	}

	// Extract parameters
	bookingID := ctx.Param("id")
	status := ctx.FormValue("status")

	// Validate booking ID
	objectID, err := primitive.ObjectIDFromHex(bookingID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid booking ID",
		})
	}

	// Validate status
	validStatuses := map[string]bool{
		"pending":   true,
		"confirmed": true,
		"completed": true,
		"cancelled": true,
	}
	if !validStatuses[status] {
		return ctx.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid status. Use 'pending', 'confirmed', 'completed', or 'cancelled'",
		})
	}

	// Get booking
	collection := c.db.Database("barrim").Collection("bookings")
	var booking models.Booking
	err = collection.FindOne(context.Background(), bson.M{"_id": objectID}).Decode(&booking)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return ctx.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Booking not found",
			})
		}
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error finding booking",
		})
	}

	// Check if user has permission to update this booking
	isServiceProvider := user.ID == booking.ServiceProviderID
	isCustomer := user.ID == booking.UserID

	if !(isServiceProvider || isCustomer) {
		return ctx.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "You don't have permission to update this booking",
		})
	}

	// Customers can only cancel bookings
	if isCustomer && status != "cancelled" {
		return ctx.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Customers can only cancel bookings",
		})
	}

	// Update booking status
	_, err = collection.UpdateOne(
		context.Background(),
		bson.M{"_id": objectID},
		bson.M{
			"$set": bson.M{
				"status":    status,
				"updatedAt": time.Now(),
			},
		},
	)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error updating booking status",
		})
	}

	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Booking status updated successfully",
	})
}

// CancelBooking specifically handles booking cancellation
func (c *BookingController) CancelBooking(ctx echo.Context) error {
	ctx.FormValue("status")
	ctx.Request().Form.Set("status", "cancelled")
	return c.UpdateBookingStatus(ctx)
}

// Helper function to check if a service provider is available at a specific time
func isProviderAvailable(provider models.User, bookingDate time.Time, timeSlot string) bool {
	// Format the date for comparison with available days
	formattedDate := bookingDate.Format("2006-01-02")

	if provider.ServiceProviderInfo == nil {
		return false
	}

	// Check if provider works on this specific date
	dateAvailable := false
	if provider.ServiceProviderInfo.AvailableDays != nil {
		for _, day := range provider.ServiceProviderInfo.AvailableDays {
			if day == formattedDate {
				dateAvailable = true
				break
			}
		}
	}

	// If not available on this specific date, check weekdays
	if !dateAvailable && provider.ServiceProviderInfo.AvailableWeekdays != nil {
		dayOfWeek := bookingDate.Weekday().String()
		for _, day := range provider.ServiceProviderInfo.AvailableWeekdays {
			if day == dayOfWeek {
				dateAvailable = true
				break
			}
		}
	}

	if !dateAvailable {
		return false
	}

	// If the provider has available hours, check if the requested time slot is within those hours
	if provider.ServiceProviderInfo.AvailableHours != nil && len(provider.ServiceProviderInfo.AvailableHours) >= 2 {
		// Parse the start and end hours
		startHourStr := provider.ServiceProviderInfo.AvailableHours[0]
		endHourStr := provider.ServiceProviderInfo.AvailableHours[1]

		startHour, err := time.Parse("15:04", startHourStr)
		if err != nil {
			return false
		}

		endHour, err := time.Parse("15:04", endHourStr)
		if err != nil {
			return false
		}

		// Parse the requested time slot (format: "3:04 PM")
		requestedTime, err := time.Parse("3:04 PM", timeSlot)
		if err != nil {
			return false
		}

		// Convert to comparable format (hours and minutes only)
		requestedHour := time.Date(0, 1, 1, requestedTime.Hour(), requestedTime.Minute(), 0, 0, time.UTC)
		startHourNormalized := time.Date(0, 1, 1, startHour.Hour(), startHour.Minute(), 0, 0, time.UTC)
		endHourNormalized := time.Date(0, 1, 1, endHour.Hour(), endHour.Minute(), 0, 0, time.UTC)

		// Check if the requested time is within the provider's working hours
		return (requestedHour.Equal(startHourNormalized) || requestedHour.After(startHourNormalized)) &&
			requestedHour.Before(endHourNormalized)
	}

	// If no specific hours are defined, use default business hours logic
	// This could be improved with more specific default hour ranges if needed
	return true

}

// AcceptBooking allows a service provider to accept a booking request
func (bc *BookingController) AcceptBooking(c echo.Context) error {
	// Get booking ID from URL parameter
	bookingID := c.Param("id")
	if bookingID == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Booking ID is required",
		})
	}

	// Parse request body
	var req models.BookingStatusUpdateRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid request format",
		})
	}

	// Validate the status is either 'accepted' or 'rejected'
	if req.Status != "accepted" && req.Status != "rejected" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Status must be either 'accepted' or 'rejected'",
		})
	}

	// Get current user from token
	user, err := utils.GetUserFromToken(c, bc.db)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Authentication failed: " + err.Error(),
		})
	}

	// Ensure user is a service provider
	if user.UserType != "serviceProvider" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Only service providers can accept or reject bookings",
		})
	}

	// Convert booking ID string to ObjectID
	objID, err := primitive.ObjectIDFromHex(bookingID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid booking ID",
		})
	}

	// Get the booking collection
	bookingCollection := bc.db.Database("barrim").Collection("bookings")

	// Find the booking
	ctx := context.Background()
	var booking models.Booking
	err = bookingCollection.FindOne(ctx, bson.M{
		"_id":               objID,
		"serviceProviderId": user.ID, // Ensure the booking belongs to this service provider
	}).Decode(&booking)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Booking not found or you do not have permission to manage this booking",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to find booking: " + err.Error(),
		})
	}

	// Check if the booking is already accepted, rejected, or cancelled
	if booking.Status != "pending" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Cannot update status: booking is already " + booking.Status,
		})
	}

	// Update the booking status
	update := bson.M{
		"$set": bson.M{
			"status":    req.Status,
			"updatedAt": time.Now(),
		},
	}

	// Add provider response if provided
	if req.ProviderResponse != "" {
		update["$set"].(bson.M)["providerResponse"] = req.ProviderResponse
	}

	// Update the booking in the database
	_, err = bookingCollection.UpdateOne(ctx, bson.M{"_id": objID}, update)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to update booking status: " + err.Error(),
		})
	}

	// Fetch the updated booking
	err = bookingCollection.FindOne(ctx, bson.M{"_id": objID}).Decode(&booking)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to retrieve updated booking: " + err.Error(),
		})
	}

	notification := websocket.Notification{
		Type:    "booking_update",
		Message: "Your booking has been " + req.Status,
		Data:    booking,
	}

	// Save the notification to the database
	err = utils.SaveNotification(bc.db, booking.UserID, "Booking Update", notification.Message, notification.Type, booking)
	if err != nil {
		log.Printf("Failed to save notification: %v", err)
	}

	// Send the notification via WebSocket
	if err := bc.hub.SendToUser(booking.UserID, notification); err != nil {
		log.Printf("Failed to send WebSocket notification to user: %v", err)
		// Optionally, fall back to another notification method (e.g., email or FCM)
	}

	// Return success response
	statusMsg := "accepted"
	if req.Status == "rejected" {
		statusMsg = "rejected"
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Booking " + statusMsg + " successfully",
		Data:    booking,
	})
}

// GetPendingBookings retrieves all pending bookings for a service provider
func (bc *BookingController) GetPendingBookings(c echo.Context) error {
	// Get current user from token
	user, err := utils.GetUserFromToken(c, bc.db)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Authentication failed: " + err.Error(),
		})
	}

	// Ensure user is a service provider
	if user.UserType != "serviceProvider" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Only service providers can access pending bookings",
		})
	}

	// Get the booking collection
	bookingCollection := bc.db.Database("barrim").Collection("bookings")

	// Find all pending bookings for this service provider
	ctx := context.Background()
	cursor, err := bookingCollection.Find(ctx, bson.M{
		"serviceProviderId": user.ID,
		"status":            "pending",
	})

	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to fetch pending bookings: " + err.Error(),
		})
	}
	defer cursor.Close(ctx)

	// Decode bookings
	var bookings []models.Booking
	if err = cursor.All(ctx, &bookings); err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to decode bookings: " + err.Error(),
		})
	}

	// Return the bookings
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Pending bookings retrieved successfully",
		Data:    bookings,
	})
}

// GetAllBookingsForAdmin allows admins to get all bookings with pagination and filtering
func (bc *BookingController) GetAllBookingsForAdmin(c echo.Context) error {
	// Get admin user from JWT token
	adminUser, err := utils.GetUserFromToken(c, bc.db)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Unauthorized",
		})
	}

	// Check if user is admin, super_admin, or manager
	if adminUser.UserType != "admin" && adminUser.UserType != "super_admin" && adminUser.UserType != "manager" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Only admins, super admins, and managers can view all bookings",
		})
	}

	// Get query parameters for pagination and filtering
	pageStr := c.QueryParam("page")
	limitStr := c.QueryParam("limit")
	status := c.QueryParam("status")
	serviceProviderID := c.QueryParam("serviceProviderId")
	userID := c.QueryParam("userId")
	dateStr := c.QueryParam("date")

	// Set default values
	page := 1
	limit := 20
	if pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 && l <= 100 {
			limit = l
		}
	}

	// Build filter
	filter := bson.M{}
	if status != "" {
		filter["status"] = status
	}
	if serviceProviderID != "" {
		if objID, err := primitive.ObjectIDFromHex(serviceProviderID); err == nil {
			filter["serviceProviderId"] = objID
		}
	}
	if userID != "" {
		if objID, err := primitive.ObjectIDFromHex(userID); err == nil {
			filter["userId"] = objID
		}
	}
	if dateStr != "" {
		if date, err := time.Parse("2006-01-02", dateStr); err == nil {
			startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location())
			endOfDay := startOfDay.Add(24 * time.Hour)
			filter["bookingDate"] = bson.M{
				"$gte": startOfDay,
				"$lt":  endOfDay,
			}
		}
	}

	// Create context
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Get total count for pagination
	bookingsCollection := bc.db.Database("barrim").Collection("bookings")
	totalCount, err := bookingsCollection.CountDocuments(ctx, filter)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error counting bookings",
		})
	}

	// Calculate skip value
	skip := (page - 1) * limit

	// Find options for pagination and sorting
	findOptions := options.Find()
	findOptions.SetSkip(int64(skip))
	findOptions.SetLimit(int64(limit))
	findOptions.SetSort(bson.D{{Key: "createdAt", Value: -1}}) // Most recent first

	// Execute query
	cursor, err := bookingsCollection.Find(ctx, filter, findOptions)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error fetching bookings",
		})
	}
	defer cursor.Close(ctx)

	// Parse results
	var bookings []models.Booking
	if err := cursor.All(ctx, &bookings); err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error parsing bookings",
		})
	}

	// Calculate pagination info
	totalPages := int((totalCount + int64(limit) - 1) / int64(limit))
	hasNext := page < totalPages
	hasPrev := page > 1

	// Create response
	response := map[string]interface{}{
		"bookings": bookings,
		"pagination": map[string]interface{}{
			"currentPage": page,
			"totalPages":  totalPages,
			"totalCount":  totalCount,
			"limit":       limit,
			"hasNext":     hasNext,
			"hasPrev":     hasPrev,
		},
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Bookings retrieved successfully",
		Data:    response,
	})
}

// DeleteBookingForAdmin allows admins to delete a booking
func (bc *BookingController) DeleteBookingForAdmin(c echo.Context) error {
	bookingID := c.Param("id")

	// Get admin user from JWT token
	adminUser, err := utils.GetUserFromToken(c, bc.db)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Unauthorized",
		})
	}

	// Check if user is admin, super_admin, or manager
	if adminUser.UserType != "admin" && adminUser.UserType != "super_admin" && adminUser.UserType != "manager" {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "Only admins, super admins, and managers can delete bookings",
		})
	}

	// Validate booking ID
	objID, err := primitive.ObjectIDFromHex(bookingID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid booking ID",
		})
	}

	// Create context
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Find the booking first to get media files for cleanup
	bookingsCollection := bc.db.Database("barrim").Collection("bookings")
	var booking models.Booking
	err = bookingsCollection.FindOne(ctx, bson.M{"_id": objID}).Decode(&booking)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return c.JSON(http.StatusNotFound, models.Response{
				Status:  http.StatusNotFound,
				Message: "Booking not found",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error finding booking",
		})
	}

	// Delete the booking
	result, err := bookingsCollection.DeleteOne(ctx, bson.M{"_id": objID})
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error deleting booking",
		})
	}

	if result.DeletedCount == 0 {
		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Booking not found",
		})
	}

	// If booking had media files, log them for cleanup
	// Note: File deletion from storage would need to be implemented based on your storage solution
	if len(booking.MediaURLs) > 0 {
		log.Printf("Booking deleted - media files should be cleaned up: %v", booking.MediaURLs)
	}

	if len(booking.ThumbnailURLs) > 0 {
		log.Printf("Booking deleted - thumbnail files should be cleaned up: %v", booking.ThumbnailURLs)
	}

	// Send notification to user about booking deletion (optional)
	if err := bc.hub.SendToUser(booking.UserID, websocket.Notification{
		Type:    "booking_deleted",
		Message: "Your booking has been deleted by an administrator",
		Data: map[string]interface{}{
			"bookingId": bookingID,
			"reason":    "Admin deletion",
		},
	}); err != nil {
		log.Printf("Failed to send WebSocket notification to user: %v", err)
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Booking deleted successfully",
		Data: map[string]interface{}{
			"bookingId": bookingID,
			"deletedAt": time.Now(),
		},
	})
}
