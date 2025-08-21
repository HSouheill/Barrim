package utils

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/HSouheill/barrim_backend/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"gopkg.in/gomail.v2"
)

// SaveNotification saves a notification to the database
func SaveNotification(db *mongo.Client, userID primitive.ObjectID, title, message, notifType string, data interface{}) error {
	collection := db.Database("barrim").Collection("notifications")

	notification := models.Notification{
		ID:        primitive.NewObjectID(),
		UserID:    userID,
		Title:     title,
		Message:   message,
		Type:      notifType,
		Data:      data,
		IsRead:    false,
		CreatedAt: time.Now(),
	}

	_, err := collection.InsertOne(context.Background(), notification)
	return err
}

// NotifySalesManagerOfRequest notifies the sales manager by email and in-app notification
func NotifySalesManagerOfRequest(db *mongo.Client, salesPersonID primitive.ObjectID, entityType, entityName string) error {
	// Find salesperson
	var salesperson models.Salesperson
	err := db.Database("barrim").Collection("salespersons").FindOne(context.Background(), bson.M{"_id": salesPersonID}).Decode(&salesperson)
	if err != nil {
		return fmt.Errorf("failed to find salesperson: %w", err)
	}
	// Find sales manager
	var salesManager models.SalesManager
	err = db.Database("barrim").Collection("sales_managers").FindOne(context.Background(), bson.M{"_id": salesperson.SalesManagerID}).Decode(&salesManager)
	if err != nil {
		return fmt.Errorf("failed to find sales manager: %w", err)
	}
	// Compose email
	subject := fmt.Sprintf("New %s Created", entityType)
	body := fmt.Sprintf("Dear %s,\n\nSalesperson %s has successfully created a new %s: %s.\nThe %s has been automatically approved and is now active in the system.\n\nBest regards,\nYour System", salesManager.FullName, salesperson.FullName, entityType, entityName, entityType)
	// Send email using gomail
	smtpHost := os.Getenv("SMTP_HOST")
	smtpUser := os.Getenv("SMTP_USER")
	smtpPass := os.Getenv("SMTP_PASS")
	smtpPort := 2525
	if portStr := os.Getenv("SMTP_PORT"); portStr != "" {
		fmt.Sscanf(portStr, "%d", &smtpPort)
	}
	m := gomail.NewMessage()
	m.SetHeader("From", smtpUser)
	m.SetHeader("To", salesManager.Email)
	m.SetHeader("Subject", subject)
	m.SetBody("text/plain", body)
	d := gomail.NewDialer(smtpHost, smtpPort, smtpUser, smtpPass)
	if err := d.DialAndSend(m); err != nil {
		log.Printf("Failed to send email to sales manager: %v", err)
	}
	// Save in-app notification
	notifTitle := fmt.Sprintf("New %s Created", entityType)
	notifMsg := fmt.Sprintf("Salesperson %s has created a new %s: %s.", salesperson.FullName, entityType, entityName)
	_ = SaveNotification(db, salesManager.ID, notifTitle, notifMsg, "entity_created", map[string]interface{}{
		"entityType":    entityType,
		"entityName":    entityName,
		"salesPersonId": salesPersonID.Hex(),
	})
	return nil
}

// NotifySalesManagerOfCreatedEntity notifies the sales manager about a newly created entity (no approval needed)
func NotifySalesManagerOfCreatedEntity(db *mongo.Client, salesPersonID primitive.ObjectID, entityType, entityName string) error {
	// Find salesperson
	var salesperson models.Salesperson
	err := db.Database("barrim").Collection("salespersons").FindOne(context.Background(), bson.M{"_id": salesPersonID}).Decode(&salesperson)
	if err != nil {
		return fmt.Errorf("failed to find salesperson: %w", err)
	}
	// Find sales manager
	var salesManager models.SalesManager
	err = db.Database("barrim").Collection("sales_managers").FindOne(context.Background(), bson.M{"_id": salesperson.SalesManagerID}).Decode(&salesManager)
	if err != nil {
		return fmt.Errorf("failed to find sales manager: %w", err)
	}
	// Compose email
	subject := fmt.Sprintf("New %s Created Successfully", entityType)
	body := fmt.Sprintf("Dear %s,\n\nSalesperson %s has successfully created a new %s: %s.\nThe %s has been automatically approved and is now active in the system.\n\nBest regards,\nYour System", salesManager.FullName, salesperson.FullName, entityType, entityName, entityType)
	// Send email using gomail
	smtpHost := os.Getenv("SMTP_HOST")
	smtpUser := os.Getenv("SMTP_USER")
	smtpPass := os.Getenv("SMTP_PASS")
	smtpPort := 2525
	if portStr := os.Getenv("SMTP_PORT"); portStr != "" {
		fmt.Sscanf(portStr, "%d", &smtpPort)
	}
	m := gomail.NewMessage()
	m.SetHeader("From", smtpUser)
	m.SetHeader("To", salesManager.Email)
	m.SetHeader("Subject", subject)
	m.SetBody("text/plain", body)
	d := gomail.NewDialer(smtpHost, smtpPort, smtpUser, smtpPass)
	if err := d.DialAndSend(m); err != nil {
		log.Printf("Failed to send email to sales manager: %v", err)
	}
	// Save in-app notification
	notifTitle := fmt.Sprintf("New %s Created Successfully", entityType)
	notifMsg := fmt.Sprintf("Salesperson %s has successfully created a new %s: %s.", salesperson.FullName, entityType, entityName)
	_ = SaveNotification(db, salesManager.ID, notifTitle, notifMsg, "entity_created", map[string]interface{}{
		"entityType":    entityType,
		"entityName":    entityName,
		"salesPersonId": salesPersonID.Hex(),
	})
	return nil
}
