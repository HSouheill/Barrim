// utils/otp.go
package utils

import (
	"context"
	"crypto/rand"
	"encoding/base32"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/twilio/twilio-go"
	api "github.com/twilio/twilio-go/rest/api/v2010"
)

func GenerateSecureOTP() (string, error) {
	// Generate 6 random bytes
	bytes := make([]byte, 6)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}

	// Convert to base32 string
	return base32.StdEncoding.EncodeToString(bytes)[:6], nil
}

func ValidateOTPAttempts(userID string, redis *redis.Client) error {
	key := "otp_attempts:" + userID
	attempts, err := redis.Incr(context.Background(), key).Result()
	if err != nil {
		return err
	}

	// Set expiry if first attempt
	if attempts == 1 {
		redis.Expire(context.Background(), key, 1*time.Hour)
	}

	// Limit to 5 attempts per hour
	if attempts > 5 {
		return errors.New("too many OTP attempts")
	}

	return nil
}

// SendOTPViaSMS sends a 6-digit OTP via SMS using Twilio SMS API
func SendOTPViaSMS(phone string, otp string) error {
	accountSid := os.Getenv("TWILIO_ACCOUNT_SID")
	authToken := os.Getenv("TWILIO_AUTH_TOKEN")
	twilioPhoneNumber := os.Getenv("TWILIO_PHONE_NUMBER")

	if accountSid == "" || authToken == "" || twilioPhoneNumber == "" {
		return fmt.Errorf("missing Twilio configuration: check TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER")
	}

	client := twilio.NewRestClientWithParams(twilio.ClientParams{
		Username: accountSid,
		Password: authToken,
	})

	params := &api.CreateMessageParams{}
	params.SetTo(phone)
	params.SetFrom(twilioPhoneNumber)
	params.SetBody(fmt.Sprintf("Your Barrim verification code is: %s. This code will expire in 10 minutes.", otp))

	resp, err := client.Api.CreateMessage(params)
	if err != nil {
		return fmt.Errorf("failed to send OTP via SMS: %w", err)
	}

	if resp.Sid != nil {
		fmt.Printf("OTP sent to %s, SID: %s\n", phone, *resp.Sid)
	} else {
		fmt.Printf("OTP sent to %s, but no SID returned\n", phone)
	}
	return nil
}
