package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Voucher represents a voucher that can be purchased with points
type Voucher struct {
	ID          primitive.ObjectID `json:"id,omitempty" bson:"_id,omitempty"`
	Name        string             `json:"name" bson:"name"`
	Description string             `json:"description" bson:"description"`
	Image       string             `json:"image" bson:"image"`
	Points      int                `json:"points" bson:"points"` // Points required to purchase
	IsActive    bool               `json:"isActive" bson:"isActive"`
	CreatedBy   primitive.ObjectID `json:"createdBy" bson:"createdBy"` // Admin who created the voucher
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// VoucherPurchase represents a user's purchase of a voucher
type VoucherPurchase struct {
	ID          primitive.ObjectID `json:"id,omitempty" bson:"_id,omitempty"`
	UserID      primitive.ObjectID `json:"userId" bson:"userId"`
	VoucherID   primitive.ObjectID `json:"voucherId" bson:"voucherId"`
	PointsUsed  int                `json:"pointsUsed" bson:"pointsUsed"`
	PurchasedAt time.Time          `json:"purchasedAt" bson:"purchasedAt"`
	IsUsed      bool               `json:"isUsed" bson:"isUsed"`
	UsedAt      time.Time          `json:"usedAt,omitempty" bson:"usedAt,omitempty"`
}

// VoucherRequest represents the request body for creating/updating vouchers
type VoucherRequest struct {
	Name        string `json:"name" validate:"required"`
	Description string `json:"description" validate:"required"`
	Image       string `json:"image" validate:"required"`
	Points      int    `json:"points" validate:"required,min=1"`
}

// VoucherPurchaseRequest represents the request body for purchasing a voucher
type VoucherPurchaseRequest struct {
	VoucherID string `json:"voucherId" validate:"required"`
}

// VoucherResponse represents the response structure for voucher operations
type VoucherResponse struct {
	Status  int         `json:"status"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// UserVoucher represents a voucher with purchase information for a user
type UserVoucher struct {
	Voucher     Voucher         `json:"voucher"`
	Purchase    VoucherPurchase `json:"purchase"`
	CanPurchase bool            `json:"canPurchase"`
	UserPoints  int             `json:"userPoints"`
}
