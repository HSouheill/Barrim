package utils

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// SMSService handles SMS sending using BestSMSBulk API
type SMSService struct {
	Username string
	Password string
	SenderID string
	APIPath  string
	Client   *http.Client
}

// SMSResponse represents the response from BestSMSBulk API
type SMSResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
	Data    struct {
		MessageID string `json:"message_id"`
		Cost      string `json:"cost"`
	} `json:"data"`
}

// NewSMSService creates a new SMS service instance
func NewSMSService() *SMSService {
	return &SMSService{
		Username: "barrim",
		Password: "9Z9ZBarrim@&$",
		SenderID: "Barrim",
		APIPath:  "https://www.bestsmsbulk.com/bestsmsbulkapi/common/sendSmsWpAPI.php",
		Client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// SendOTP sends an OTP via SMS using BestSMSBulk API
func (s *SMSService) SendOTP(phoneNumber, otp string) error {
	// Keep the + sign for phone number (API accepts it)
	destination := phoneNumber

	// Build query parameters
	params := url.Values{}
	params.Set("username", s.Username)
	params.Set("password", s.Password)
	params.Set("senderid", s.SenderID)
	params.Set("destination", destination)
	params.Set("message", otp)
	params.Set("route", "wp")     // wp = WhatsApp route
	params.Set("template", "otp") // Required for OTP messages

	// Build full URL with query parameters
	fullURL := fmt.Sprintf("%s?%s", s.APIPath, params.Encode())

	// Log the request for debugging
	fmt.Printf("📤 Sending OTP via WhatsApp to: %s | Route: wp\n", phoneNumber)
	fmt.Printf("🔗 Full API URL: %s\n", fullURL)
	fmt.Printf("💬 Message Preview: %s\n", otp)

	// Create HTTP GET request
	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		fmt.Printf("❌ Failed to create HTTP request: %v\n", err)
		return fmt.Errorf("failed to create HTTP request: %w", err)
	}

	// Set headers
	req.Header.Set("User-Agent", "Barrim-OTP-Service/1.0")

	// Send the request
	resp, err := s.Client.Do(req)
	if err != nil {
		fmt.Printf("❌ WhatsApp Request Error: %v\n", err)
		return fmt.Errorf("failed to send WhatsApp request: %w", err)
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("❌ Failed to read response: %v\n", err)
		return fmt.Errorf("failed to read response body: %w", err)
	}

	// Log the response for debugging
	fmt.Printf("📥 WhatsApp API Response Status: %d\n", resp.StatusCode)
	fmt.Printf("📥 WhatsApp API Response Body: %s\n", string(body))

	// Check HTTP status
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("WhatsApp API returned status %d: %s", resp.StatusCode, string(body))
	}

	// Parse response - BestSMSBulk returns format like: "1690020280;96170477357;1 <br/>"
	// Format: messageID;phone;status (status 1 = success)
	responseStr := strings.TrimSpace(string(body))
	responseStr = strings.ReplaceAll(responseStr, "<br/>", "")
	responseStr = strings.ReplaceAll(responseStr, "<br>", "")
	responseStr = strings.TrimSpace(responseStr)

	// Check if response is in the expected format (messageID;phone;status)
	parts := strings.Split(responseStr, ";")
	if len(parts) >= 3 {
		messageID := parts[0]
		status := parts[2]

		// Status "1" means success
		if status == "1" {
			fmt.Printf("✅ WhatsApp OTP sent successfully to %s | Message ID: %s\n", phoneNumber, messageID)
			return nil
		} else {
			fmt.Printf("❌ WhatsApp OTP failed with status: %s | Response: %s\n", status, responseStr)
			return fmt.Errorf("WhatsApp OTP failed with status %s: %s", status, responseStr)
		}
	}

	// Try JSON parsing as fallback
	var smsResp SMSResponse
	if err := json.Unmarshal(body, &smsResp); err == nil {
		if smsResp.Status == "success" || smsResp.Status == "sent" {
			fmt.Printf("✅ WhatsApp OTP sent successfully to %s | Message ID: %s\n", phoneNumber, smsResp.Data.MessageID)
			return nil
		}
		return fmt.Errorf("WhatsApp OTP failed: %s", smsResp.Message)
	}

	// If we get here, check for common success indicators
	if strings.Contains(strings.ToLower(responseStr), "success") ||
		strings.Contains(strings.ToLower(responseStr), "sent") ||
		resp.StatusCode == http.StatusOK {
		fmt.Printf("✅ WhatsApp OTP sent successfully to %s (unknown format): %s\n", phoneNumber, responseStr)
		return nil
	}

	return fmt.Errorf("failed to parse WhatsApp API response: %s", responseStr)
}

// SendOTPViaSMS sends a 6-digit OTP via SMS using BestSMSBulk API
// This function maintains compatibility with the existing codebase
func SendOTPViaSMS(phone string, otp string) error {
	// Ensure phone number has proper format
	if !strings.HasPrefix(phone, "+") {
		phone = "+" + phone
	}

	// Send just the OTP code (the template=otp parameter handles the formatting)
	// Do NOT format the message - the API template handles it
	smsService := NewSMSService()
	return smsService.SendOTP(phone, otp)
}

// SendOTPViaSMSWithMessage sends an OTP with a custom message
func SendOTPViaSMSWithMessage(phone string, otp string, customMessage string) error {
	// Ensure phone number has proper format
	if !strings.HasPrefix(phone, "+") {
		phone = "+" + phone
	}

	// Use custom message if provided, otherwise use default
	message := customMessage
	if message == "" {
		message = fmt.Sprintf("Your Barrim verification code is: %s. This code will expire in 10 minutes.", otp)
	}

	// Create SMS service and send OTP
	smsService := NewSMSService()
	return smsService.SendOTP(phone, message)
}
