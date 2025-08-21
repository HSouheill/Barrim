package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Commission struct {
	ID             primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	SubscriptionID primitive.ObjectID `bson:"subscriptionId" json:"subscriptionId"`
	CompanyID      primitive.ObjectID `bson:"companyId" json:"companyId"`
	PlanID         primitive.ObjectID `bson:"planId" json:"planId"`
	PlanPrice      float64            `bson:"planPrice" json:"planPrice"`

	SalespersonID                primitive.ObjectID `bson:"salespersonId" json:"salespersonId"`
	SalespersonCommission        float64            `bson:"salespersonCommission" json:"salespersonCommission"`
	SalespersonCommissionPercent float64            `bson:"salespersonCommissionPercent" json:"salespersonCommissionPercent"`

	SalesManagerID                primitive.ObjectID `bson:"salesManagerId" json:"salesManagerId"`
	SalesManagerCommission        float64            `bson:"salesManagerCommission" json:"salesManagerCommission"`
	SalesManagerCommissionPercent float64            `bson:"salesManagerCommissionPercent" json:"salesManagerCommissionPercent"`

	CreatedAt time.Time  `bson:"createdAt" json:"createdAt"`
	Paid      bool       `bson:"paid" json:"paid"`
	PaidAt    *time.Time `bson:"paidAt,omitempty" json:"paidAt,omitempty"`
}
