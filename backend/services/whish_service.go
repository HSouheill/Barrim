package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/HSouheill/barrim_backend/models"
)

// WhishService handles interactions with the Whish API
type WhishService struct {
	baseURL    string
	channel    string
	secret     string
	websiteURL string
	isTesting  bool
}

// NewWhishService creates a new Whish service instance
func NewWhishService() *WhishService {
	// Try production environment first since testing credentials may not be set up
	isTesting := false // Set to true for sandbox, false for production

	baseURL := "https://whish.money/itel-service/api/"
	if isTesting {
		baseURL = "https://api.sandbox.whish.money/itel-service/api/"
	}

	// channel := os.Getenv("WHISH_CHANNEL")
	// secret := os.Getenv("WHISH_SECRET")
	// websiteURL := os.Getenv("WHISH_WEBSITE_URL")
	channel := "10196975"
	secret := "024709627da343afbcd5278a5ea819e"
	websiteURL := "https://barrim.com"

	// Log configuration for debugging (don't log secret in production)
	fmt.Printf("Whish Service Configuration:\n")
	fmt.Printf("  Environment: %s\n", map[string]string{"true": "testing", "false": "live"}[fmt.Sprintf("%t", isTesting)])
	fmt.Printf("  Base URL: %s\n", baseURL)
	fmt.Printf("  Channel: %s\n", channel)
	fmt.Printf("  Website URL: %s\n", websiteURL)
	fmt.Printf("  Secret: %s\n", func() string {
		if secret == "" {
			return "[NOT SET]"
		}
		return "[SET]"
	}())

	return &WhishService{
		baseURL:    baseURL,
		channel:    channel,
		secret:     secret,
		websiteURL: websiteURL,
		isTesting:  isTesting,
	}
}

// getHeaders returns the standard headers required for Whish API requests
func (s *WhishService) getHeaders() map[string]string {
	return map[string]string{
		"Content-Type": "application/json",
		"channel":      s.channel,
		"secret":       s.secret,
		"websiteurl":   s.websiteURL,
	}
}

// makeRequest performs an HTTP request to the Whish API
func (s *WhishService) makeRequest(method, endpoint string, payload interface{}) (*models.WhishResponse, error) {
	url := s.baseURL + endpoint

	// Create request body
	var body io.Reader
	if payload != nil {
		jsonData, err := json.Marshal(payload)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request: %w", err)
		}
		body = bytes.NewBuffer(jsonData)
	}

	// Create request
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Validate credentials
	if s.channel == "" || s.secret == "" || s.websiteURL == "" {
		return nil, fmt.Errorf("missing Whish credentials. Please set WHISH_CHANNEL, WHISH_SECRET, and WHISH_WEBSITE_URL environment variables")
	}

	// Add headers
	headers := s.getHeaders()
	fmt.Printf("Whish API Request:\n")
	fmt.Printf("  URL: %s\n", url)
	fmt.Printf("  Method: %s\n", method)
	for key, value := range headers {
		if key == "secret" {
			fmt.Printf("  %s: [HIDDEN]\n", key)
		} else {
			fmt.Printf("  %s: %s\n", key, value)
		}
	}

	for key, value := range headers {
		req.Header.Set(key, value)
	}

	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	// Send request
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Read response body
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Log the raw response for debugging
	fmt.Printf("Whish API Response: %s\n", string(respBody))

	// Parse response
	var whishResp models.WhishResponse
	if err := json.Unmarshal(respBody, &whishResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w\nResponse body: %s", err, string(respBody))
	}

	// Check if the request was successful
	if !whishResp.Status {
		code := "unknown"
		if whishResp.Code != nil {
			if codeStr, ok := whishResp.Code.(string); ok {
				code = codeStr
			} else {
				code = fmt.Sprintf("%v", whishResp.Code)
			}
		}
		return &whishResp, fmt.Errorf("whish API error: %s", code)
	}

	return &whishResp, nil
}

// GetBalance retrieves the real balance of the account
func (s *WhishService) GetBalance() (float64, error) {
	resp, err := s.makeRequest("GET", "payment/account/balance", nil)
	if err != nil {
		return 0, err
	}

	// Extract balance from response
	if balanceDetails, ok := resp.Data["balanceDetails"].(map[string]interface{}); ok {
		if balance, ok := balanceDetails["balance"].(float64); ok {
			return balance, nil
		}
	}

	return 0, fmt.Errorf("failed to parse balance from response")
}

// GetRate returns the current rate/fees that will be deducted from the invoice amount
func (s *WhishService) GetRate(amount float64, currency string) (float64, error) {
	payload := models.WhishRequest{
		Amount:   &amount,
		Currency: currency,
	}

	resp, err := s.makeRequest("POST", "payment/whish/rate", payload)
	if err != nil {
		return 0, err
	}

	// Extract rate from response
	if rate, ok := resp.Data["rate"].(float64); ok {
		return rate, nil
	}

	return 0, fmt.Errorf("failed to parse rate from response")
}

// PostPayment creates a payment and returns the collect URL
func (s *WhishService) PostPayment(req models.WhishRequest) (string, error) {
	resp, err := s.makeRequest("POST", "payment/whish", req)
	if err != nil {
		return "", err
	}

	// Extract collect URL from response
	if collectURL, ok := resp.Data["collectUrl"].(string); ok {
		return collectURL, nil
	}

	return "", fmt.Errorf("failed to parse collect URL from response")
}

// GetPaymentStatus returns the status of a payment transaction
func (s *WhishService) GetPaymentStatus(currency string, externalID int64) (string, string, error) {
	payload := models.WhishRequest{
		Currency:   currency,
		ExternalID: &externalID,
	}

	resp, err := s.makeRequest("POST", "payment/collect/status", payload)
	if err != nil {
		return "", "", err
	}

	// Extract status and phone number from response
	var status, phoneNumber string

	if s, ok := resp.Data["collectStatus"].(string); ok {
		status = s
	}

	if pn, ok := resp.Data["payerPhoneNumber"].(string); ok {
		phoneNumber = pn
	}

	return status, phoneNumber, nil
}
