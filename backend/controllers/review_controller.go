// controllers/review_controller.go
package controllers

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"path/filepath"
	"strconv"
	"time"

	"github.com/HSouheill/barrim_backend/models"
	"github.com/HSouheill/barrim_backend/utils"
	"github.com/labstack/echo/v4"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type ReviewController struct {
	db *mongo.Client
}

func NewReviewController(db *mongo.Client) *ReviewController {
	return &ReviewController{db: db}
}

// GetReviewsByProviderID retrieves all reviews for a specific service provider
func (rc *ReviewController) GetReviewsByProviderID(c echo.Context) error {
	providerID := c.Param("id")

	// Validate provider ID
	objectID, err := primitive.ObjectIDFromHex(providerID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid provider ID",
		})
	}

	// Create context
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Find reviews for this provider
	reviewsCollection := rc.db.Database("barrim").Collection("reviews")

	// Get reviews sorted by most recent first
	findOptions := options.Find()
	findOptions.SetSort(bson.D{{Key: "createdAt", Value: -1}})

	cursor, err := reviewsCollection.Find(ctx, bson.M{"serviceProviderId": objectID}, findOptions)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error fetching reviews",
		})
	}
	defer cursor.Close(ctx)

	var reviews []models.Review
	if err := cursor.All(ctx, &reviews); err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error parsing reviews",
		})
	}

	return c.JSON(http.StatusOK, models.ReviewsResponse{
		Status:  http.StatusOK,
		Message: "Reviews retrieved successfully",
		Data:    reviews,
	})
}

// CreateReview adds a new review for a service provider
func (rc *ReviewController) CreateReview(c echo.Context) error {
	// Get user from JWT token
	user, err := utils.GetUserFromToken(c, rc.db)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Unauthorized",
		})
	}

	// Parse multipart form data
	if err := c.Request().ParseMultipartForm(10 << 20); err != nil { // 10 MB max
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Failed to parse form data",
		})
	}

	// Get form values
	serviceProviderID := c.FormValue("serviceProviderId")
	ratingStr := c.FormValue("rating")
	comment := c.FormValue("comment")
	mediaType := c.FormValue("mediaType") // "image" or "video"

	// Validate required fields
	if serviceProviderID == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Service provider ID is required",
		})
	}

	// Parse rating
	rating, err := strconv.Atoi(ratingStr)
	if err != nil || rating < 1 || rating > 5 {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Rating must be between 1 and 5",
		})
	}

	// Validate provider ID
	providerID, err := primitive.ObjectIDFromHex(serviceProviderID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid provider ID",
		})
	}

	// Handle media upload if present
	var mediaURL, thumbnailURL string
	if mediaType != "" {
		// Validate media type
		if mediaType != "image" && mediaType != "video" {
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Invalid media type. Must be 'image' or 'video'",
			})
		}

		// Get media file
		file, err := c.FormFile("mediaFile")
		if err != nil {
			return c.JSON(http.StatusBadRequest, models.Response{
				Status:  http.StatusBadRequest,
				Message: "Media file is required when mediaType is specified",
			})
		}

		// Read file data
		src, err := file.Open()
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to read uploaded file",
			})
		}
		defer src.Close()

		// Read file into byte slice
		fileData := make([]byte, file.Size)
		_, err = src.Read(fileData)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: "Failed to read file data",
			})
		}

		// Generate unique filename
		timestamp := time.Now().Unix()
		uniqueID := primitive.NewObjectID().Hex()
		fileExt := filepath.Ext(file.Filename)
		if fileExt == "" {
			if mediaType == "image" {
				fileExt = ".jpg"
			} else {
				fileExt = ".mp4"
			}
		}
		filename := fmt.Sprintf("reviews/%s/%d_%s%s",
			user.ID.Hex(),
			timestamp,
			uniqueID,
			fileExt,
		)

		// Upload file
		mediaURL, err = utils.UploadFile(fileData, filename, mediaType)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, models.Response{
				Status:  http.StatusInternalServerError,
				Message: fmt.Sprintf("Failed to upload media file: %v", err),
			})
		}

		// Generate thumbnail for videos
		if mediaType == "video" {
			thumbnailURL, err = utils.GenerateVideoThumbnail(mediaURL)
			if err != nil {
				log.Printf("Failed to generate video thumbnail: %v", err)
				thumbnailURL = ""
			}
		}
	}

	// Create review
	now := time.Now()
	newReview := models.Review{
		ID:                primitive.NewObjectID(),
		ServiceProviderID: providerID,
		UserID:            user.ID,
		Username:          user.FullName,
		UserProfilePic:    user.ProfilePic,
		Rating:            rating,
		Comment:           comment,
		MediaType:         mediaType,
		MediaURL:          mediaURL,
		ThumbnailURL:      thumbnailURL,
		IsVerified:        false, // Default to false, can be updated by admin
		CreatedAt:         now,
		UpdatedAt:         now,
	}

	// Insert review into database
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	reviewsCollection := rc.db.Database("barrim").Collection("reviews")
	_, err = reviewsCollection.InsertOne(ctx, newReview)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Error creating review",
		})
	}

	// Update service provider average rating
	go rc.updateProviderRating(providerID)

	return c.JSON(http.StatusCreated, models.ReviewResponse{
		Status:  http.StatusCreated,
		Message: "Review created successfully",
		Data:    &newReview,
	})
}

// updateProviderRating calculates and updates the average rating for a service provider
func (rc *ReviewController) updateProviderRating(providerID primitive.ObjectID) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Calculate average rating
	reviewsCollection := rc.db.Database("barrim").Collection("reviews")

	// Pipeline to calculate average rating
	pipeline := []bson.M{
		{"$match": bson.M{"serviceProviderId": providerID}},
		{"$group": bson.M{
			"_id":           nil,
			"averageRating": bson.M{"$avg": "$rating"},
			"count":         bson.M{"$sum": 1},
		}},
	}

	cursor, err := reviewsCollection.Aggregate(ctx, pipeline)
	if err != nil {
		return
	}
	defer cursor.Close(ctx)

	// Get aggregation result
	var results []bson.M
	if err := cursor.All(ctx, &results); err != nil || len(results) == 0 {
		return
	}

	// Extract average rating
	avgRating := results[0]["averageRating"].(float64)

	// Update service provider info
	usersCollection := rc.db.Database("barrim").Collection("users")
	_, err = usersCollection.UpdateOne(
		ctx,
		bson.M{"_id": providerID},
		bson.M{
			"$set": bson.M{
				"serviceProviderInfo.rating": avgRating,
				"updatedAt":                  time.Now(),
			},
		},
	)
}

func (rc *ReviewController) PostReviewReply(c echo.Context) error {
	reviewID := c.Param("id")
	spUser, err := utils.GetUserFromToken(c, rc.db)
	if err != nil || spUser.UserType != "serviceProvider" {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Only service providers can reply to reviews",
		})
	}

	// Parse reply body
	type ReplyRequest struct {
		ReplyText string `json:"replyText"`
	}
	var req ReplyRequest
	if err := c.Bind(&req); err != nil || req.ReplyText == "" {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Reply text is required",
		})
	}

	// Find the review
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	reviewsCollection := rc.db.Database("barrim").Collection("reviews")
	objID, err := primitive.ObjectIDFromHex(reviewID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid review ID",
		})
	}
	var review models.Review
	err = reviewsCollection.FindOne(ctx, bson.M{"_id": objID}).Decode(&review)
	if err != nil {
		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Review not found",
		})
	}
	if review.ServiceProviderID != spUser.ID {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "You can only reply to reviews for your own service provider account",
		})
	}
	if review.Reply != nil {
		return c.JSON(http.StatusConflict, models.Response{
			Status:  http.StatusConflict,
			Message: "This review already has a reply",
		})
	}

	reply := &models.ReviewReply{
		ServiceProviderID: spUser.ID,
		ReplyText:         req.ReplyText,
		CreatedAt:         time.Now(),
	}
	_, err = reviewsCollection.UpdateOne(ctx, bson.M{"_id": objID}, bson.M{"$set": bson.M{"reply": reply, "updatedAt": time.Now()}})
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.Response{
			Status:  http.StatusInternalServerError,
			Message: "Failed to save reply",
		})
	}
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Reply posted successfully",
		Data:    reply,
	})
}

// GetReviewReply allows the review's user or the service provider to get the reply
func (rc *ReviewController) GetReviewReply(c echo.Context) error {
	reviewID := c.Param("id")
	user, err := utils.GetUserFromToken(c, rc.db)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, models.Response{
			Status:  http.StatusUnauthorized,
			Message: "Unauthorized",
		})
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	reviewsCollection := rc.db.Database("barrim").Collection("reviews")
	objID, err := primitive.ObjectIDFromHex(reviewID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.Response{
			Status:  http.StatusBadRequest,
			Message: "Invalid review ID",
		})
	}
	var review models.Review
	err = reviewsCollection.FindOne(ctx, bson.M{"_id": objID}).Decode(&review)
	if err != nil {
		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "Review not found",
		})
	}
	if user.ID != review.UserID && user.ID != review.ServiceProviderID {
		return c.JSON(http.StatusForbidden, models.Response{
			Status:  http.StatusForbidden,
			Message: "You are not allowed to view this reply",
		})
	}
	if review.Reply == nil {
		return c.JSON(http.StatusNotFound, models.Response{
			Status:  http.StatusNotFound,
			Message: "No reply for this review",
		})
	}
	return c.JSON(http.StatusOK, models.Response{
		Status:  http.StatusOK,
		Message: "Reply retrieved successfully",
		Data:    review.Reply,
	})
}
