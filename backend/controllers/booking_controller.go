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

	// Check service provider availability using ServiceProviderInfo from serviceProviders collection
	if !isServiceProviderAvailable(serviceProvider, request.BookingDate, request.TimeSlot) {
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

	// Retrieve bookings from database using unified ID approach
	collection := c.db.Database("barrim").Collection("bookings")

	// Build filter with unified ID support
	filter := bson.M{
		"$or": []bson.M{
			{"serviceProviderId": user.ID},                // New unified approach
			{"serviceProviderId": user.ServiceProviderID}, // Legacy approach
		},
	}

	// Remove the $or clause if ServiceProviderID is nil
	if user.ServiceProviderID == nil {
		filter = bson.M{"serviceProviderId": user.ID}
	}

	cursor, err := collection.Find(context.Background(), filter)
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

	// Enrich bookings with user information
	var enrichedBookings []map[string]interface{}
	for _, booking := range bookings {
		// Get user information
		var bookingUser models.User
		err := c.db.Database("barrim").Collection("users").FindOne(context.Background(), bson.M{"_id": booking.UserID}).Decode(&bookingUser)
		if err != nil {
			log.Printf("Error fetching user info for booking %s: %v", booking.ID.Hex(), err)
		}

		enrichedBooking := map[string]interface{}{
			"booking": booking,
			"user": map[string]interface{}{
				"id":         bookingUser.ID,
				"fullName":   bookingUser.FullName,
				"email":      bookingUser.Email,
				"phone":      bookingUser.Phone,
				"profilePic": bookingUser.ProfilePic,
				"userType":   bookingUser.UserType,
			},
		}

		enrichedBookings = append(enrichedBookings, enrichedBooking)
	}

	return ctx.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Bookings retrieved successfully",
		Data:    enrichedBookings,
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

	// Check if the provider is available on this date (by checking availableDays)
	dateStr = date.Format("2006-01-02")
	isDateAvailable := false

	// Check availableDays from serviceProvider data
	if serviceProvider.ServiceProviderInfo != nil && serviceProvider.ServiceProviderInfo.AvailableDays != nil {
		for _, availableDate := range serviceProvider.ServiceProviderInfo.AvailableDays {
			if availableDate == dateStr {
				isDateAvailable = true
				break
			}
		}
	}

	// If not directly in availableDays, check if the weekday is available
	if !isDateAvailable && serviceProvider.ServiceProviderInfo != nil && serviceProvider.ServiceProviderInfo.AvailableWeekdays != nil {
		dayOfWeek := date.Weekday().String()
		for _, weekday := range serviceProvider.ServiceProviderInfo.AvailableWeekdays {
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

	// Get available hours from serviceProvider data
	if serviceProvider.ServiceProviderInfo != nil && len(serviceProvider.ServiceProviderInfo.AvailableHours) >= 2 {
		// Parse start and end hours from provider's available hours (format: "09:00", "17:00")
		startTimeStr := serviceProvider.ServiceProviderInfo.AvailableHours[0]
		endTimeStr := serviceProvider.ServiceProviderInfo.AvailableHours[1]

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

// Helper function to check if a service provider is available at a specific time using ServiceProviderInfo from serviceProviders collection
func isServiceProviderAvailable(serviceProvider models.ServiceProvider, bookingDate time.Time, timeSlot string) bool {
	// Format the date for comparison with available days
	formattedDate := bookingDate.Format("2006-01-02")

	if serviceProvider.ServiceProviderInfo == nil {
		return false
	}

	// Check if provider works on this specific date
	dateAvailable := false
	if serviceProvider.ServiceProviderInfo.AvailableDays != nil {
		for _, day := range serviceProvider.ServiceProviderInfo.AvailableDays {
			if day == formattedDate {
				dateAvailable = true
				break
			}
		}
	}

	// If not available on this specific date, check weekdays
	if !dateAvailable && serviceProvider.ServiceProviderInfo.AvailableWeekdays != nil {
		dayOfWeek := bookingDate.Weekday().String()
		for _, day := range serviceProvider.ServiceProviderInfo.AvailableWeekdays {
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
	if serviceProvider.ServiceProviderInfo.AvailableHours != nil && len(serviceProvider.ServiceProviderInfo.AvailableHours) >= 2 {
		// Parse the start and end hours
		startHourStr := serviceProvider.ServiceProviderInfo.AvailableHours[0]
		endHourStr := serviceProvider.ServiceProviderInfo.AvailableHours[1]

		startHour, err := time.Parse("15:04", startHourStr)
		if err != nil {
			return false
		}

		endHour, err := time.Parse("15:04", endHourStr)
		if err != nil {
			return false
		}

		// Parse the requested time slot (format: "11:00" - 24-hour format)
		requestedTime, err := time.Parse("15:04", timeSlot)
		if err != nil {
			// Try parsing as 12-hour format ("3:04 PM")
			requestedTime, err = time.Parse("3:04 PM", timeSlot)
			if err != nil {
				return false
			}
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

	// Find the booking using unified ID approach
	ctx := context.Background()
	var booking models.Booking

	// Build filter with unified ID support
	filter := bson.M{
		"_id": objID,
		"$or": []bson.M{
			{"serviceProviderId": user.ID},                // New unified approach
			{"serviceProviderId": user.ServiceProviderID}, // Legacy approach
		},
	}

	// Remove the $or clause if ServiceProviderID is nil
	if user.ServiceProviderID == nil {
		filter = bson.M{
			"_id":               objID,
			"serviceProviderId": user.ID,
		}
	}

	err = bookingCollection.FindOne(ctx, filter).Decode(&booking)

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
	// Use unified ID approach to handle both new and legacy booking data
	ctx := context.Background()

	// Build filter with unified ID support
	filter := bson.M{
		"status": "pending",
		"$or": []bson.M{
			{"serviceProviderId": user.ID},                // New unified approach
			{"serviceProviderId": user.ServiceProviderID}, // Legacy approach
		},
	}

	// Remove the $or clause if ServiceProviderID is nil
	if user.ServiceProviderID == nil {
		filter = bson.M{
			"serviceProviderId": user.ID,
			"status":            "pending",
		}
	}

	cursor, err := bookingCollection.Find(ctx, filter)

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

	// Enrich bookings with user information
	var enrichedBookings []map[string]interface{}
	for _, booking := range bookings {
		// Get user information
		var bookingUser models.User
		err := bc.db.Database("barrim").Collection("users").FindOne(ctx, bson.M{"_id": booking.UserID}).Decode(&bookingUser)
		if err != nil {
			log.Printf("Error fetching user info for booking %s: %v", booking.ID.Hex(), err)
		}

		enrichedBooking := map[string]interface{}{
			"booking": booking,
			"user": map[string]interface{}{
				"id":         bookingUser.ID,
				"fullName":   bookingUser.FullName,
				"email":      bookingUser.Email,
				"phone":      bookingUser.Phone,
				"profilePic": bookingUser.ProfilePic,
				"userType":   bookingUser.UserType,
			},
		}

		enrichedBookings = append(enrichedBookings, enrichedBooking)
	}

	// Return the enriched bookings
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Pending bookings retrieved successfully",
		Data:    enrichedBookings,
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
	isEmergency := c.QueryParam("isEmergency") // "true", "false", or empty for all
	dateRangeStart := c.QueryParam("dateRangeStart")
	dateRangeEnd := c.QueryParam("dateRangeEnd")

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
	if isEmergency == "true" {
		filter["isEmergency"] = true
	} else if isEmergency == "false" {
		filter["isEmergency"] = false
	}

	// Handle date filtering
	if dateStr != "" {
		if date, err := time.Parse("2006-01-02", dateStr); err == nil {
			startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location())
			endOfDay := startOfDay.Add(24 * time.Hour)
			filter["bookingDate"] = bson.M{
				"$gte": startOfDay,
				"$lt":  endOfDay,
			}
		}
	} else if dateRangeStart != "" && dateRangeEnd != "" {
		startDate, err1 := time.Parse("2006-01-02", dateRangeStart)
		endDate, err2 := time.Parse("2006-01-02", dateRangeEnd)
		if err1 == nil && err2 == nil {
			startOfDay := time.Date(startDate.Year(), startDate.Month(), startDate.Day(), 0, 0, 0, 0, startDate.Location())
			endOfDay := time.Date(endDate.Year(), endDate.Month(), endDate.Day(), 23, 59, 59, 999999999, endDate.Location())
			filter["bookingDate"] = bson.M{
				"$gte": startOfDay,
				"$lte": endOfDay,
			}
		}
	}

	// Create context
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
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

	// Enrich bookings with user and service provider information
	var enrichedBookings []map[string]interface{}
	for _, booking := range bookings {
		// Get user information
		var user models.User
		err := bc.db.Database("barrim").Collection("users").FindOne(ctx, bson.M{"_id": booking.UserID}).Decode(&user)
		if err != nil {
			log.Printf("Error fetching user info for booking %s: %v", booking.ID.Hex(), err)
		}

		// Get service provider information
		var serviceProvider models.User
		err = bc.db.Database("barrim").Collection("users").FindOne(ctx, bson.M{"_id": booking.ServiceProviderID}).Decode(&serviceProvider)
		if err != nil {
			log.Printf("Error fetching service provider info for booking %s: %v", booking.ID.Hex(), err)
		}

		enrichedBooking := map[string]interface{}{
			"booking": booking,
			"user": map[string]interface{}{
				"id":       user.ID,
				"fullName": user.FullName,
				"email":    user.Email,
				"phone":    user.Phone,
				"userType": user.UserType,
			},
			"serviceProvider": map[string]interface{}{
				"id":       serviceProvider.ID,
				"fullName": serviceProvider.FullName,
				"email":    serviceProvider.Email,
				"phone":    serviceProvider.Phone,
				"userType": serviceProvider.UserType,
			},
		}

		enrichedBookings = append(enrichedBookings, enrichedBooking)
	}

	// Calculate statistics
	stats, err := bc.getBookingStatistics(ctx, filter)
	if err != nil {
		log.Printf("Error calculating booking statistics: %v", err)
		stats = map[string]interface{}{
			"totalBookings":     0,
			"pendingBookings":   0,
			"confirmedBookings": 0,
			"completedBookings": 0,
			"cancelledBookings": 0,
			"emergencyBookings": 0,
		}
	}

	// Calculate pagination info
	totalPages := int((totalCount + int64(limit) - 1) / int64(limit))
	hasNext := page < totalPages
	hasPrev := page > 1

	// Create response
	response := map[string]interface{}{
		"bookings": enrichedBookings,
		"pagination": map[string]interface{}{
			"currentPage": page,
			"totalPages":  totalPages,
			"totalCount":  totalCount,
			"limit":       limit,
			"hasNext":     hasNext,
			"hasPrev":     hasPrev,
		},
		"statistics": stats,
		"filters": map[string]interface{}{
			"status":            status,
			"serviceProviderId": serviceProviderID,
			"userId":            userID,
			"date":              dateStr,
			"isEmergency":       isEmergency,
			"dateRangeStart":    dateRangeStart,
			"dateRangeEnd":      dateRangeEnd,
		},
	}

	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Bookings retrieved successfully",
		Data:    response,
	})
}

// getBookingStatistics calculates statistics for bookings
func (bc *BookingController) getBookingStatistics(ctx context.Context, filter bson.M) (map[string]interface{}, error) {
	bookingsCollection := bc.db.Database("barrim").Collection("bookings")

	// Get total bookings count
	totalBookings, err := bookingsCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, err
	}

	// Count bookings by status
	statusPipeline := []bson.M{
		{"$match": filter},
		{"$group": bson.M{
			"_id":   "$status",
			"count": bson.M{"$sum": 1},
		}},
	}

	cursor, err := bookingsCollection.Aggregate(ctx, statusPipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var statusResults []bson.M
	if err := cursor.All(ctx, &statusResults); err != nil {
		return nil, err
	}

	// Initialize status counts
	statusCounts := map[string]int64{
		"pending":   0,
		"accepted":  0,
		"rejected":  0,
		"confirmed": 0,
		"completed": 0,
		"cancelled": 0,
	}

	// Populate status counts from aggregation results
	for _, result := range statusResults {
		if status, exists := result["_id"].(string); exists {
			if count, exists := result["count"].(int64); exists {
				statusCounts[status] = count
			}
		}
	}

	// Count emergency bookings
	emergencyFilter := bson.M{}
	for key, value := range filter {
		emergencyFilter[key] = value
	}
	emergencyFilter["isEmergency"] = true
	emergencyBookings, err := bookingsCollection.CountDocuments(ctx, emergencyFilter)
	if err != nil {
		return nil, err
	}

	// Calculate average booking duration (time between creation and completion)
	durationPipeline := []bson.M{
		{"$match": bson.M{
			"status": "completed",
		}},
		{"$project": bson.M{
			"duration": bson.M{
				"$subtract": []string{"$updatedAt", "$createdAt"},
			},
		}},
		{"$group": bson.M{
			"_id":         nil,
			"avgDuration": bson.M{"$avg": "$duration"},
		}},
	}

	durationCursor, err := bookingsCollection.Aggregate(ctx, durationPipeline)
	if err != nil {
		return nil, err
	}
	defer durationCursor.Close(ctx)

	var durationResults []bson.M
	if err := durationCursor.All(ctx, &durationResults); err != nil {
		return nil, err
	}

	var avgDuration float64
	if len(durationResults) > 0 {
		if avg, exists := durationResults[0]["avgDuration"]; exists && avg != nil {
			avgDuration = avg.(float64)
		}
	}

	return map[string]interface{}{
		"totalBookings":     totalBookings,
		"pendingBookings":   statusCounts["pending"],
		"acceptedBookings":  statusCounts["accepted"],
		"rejectedBookings":  statusCounts["rejected"],
		"confirmedBookings": statusCounts["confirmed"],
		"completedBookings": statusCounts["completed"],
		"cancelledBookings": statusCounts["cancelled"],
		"emergencyBookings": emergencyBookings,
		"avgCompletionTime": avgDuration, // in milliseconds
	}, nil
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
