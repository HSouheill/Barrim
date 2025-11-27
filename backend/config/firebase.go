package config

import (
	"context"
	"encoding/base64"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"google.golang.org/api/option"
)

var FirebaseApp *firebase.App

func getFirebaseProjectID() string {
	if projectID := os.Getenv("FIREBASE_PROJECT_ID"); projectID != "" {
		return projectID
	}
	// Default to the mobile app project (barrimapp-abd32)
	return "barrimapp-abd32"
}

// InitFirebase initializes the Firebase Admin SDK
func InitFirebase() {
	ctx := context.Background()
	projectID := getFirebaseProjectID()

	// Check for base64 encoded credentials first
	if base64Creds := os.Getenv("FIREBASE_CREDENTIALS_BASE64"); base64Creds != "" {
		log.Printf("Using Firebase credentials from base64 environment variable")
		decoded, err := base64.StdEncoding.DecodeString(base64Creds)
		if err != nil {
			log.Fatalf("Error decoding base64 credentials: %v", err)
		}

		opt := option.WithCredentialsJSON(decoded)
		config := &firebase.Config{
			ProjectID: projectID,
		}

		app, err := firebase.NewApp(ctx, config, opt)
		if err != nil {
			log.Fatalf("error initializing firebase app: %v\n", err)
		}
		FirebaseApp = app
		return
	}

	// Fallback to file-based credentials
	credFile := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
	if credFile == "" {
		// Try multiple possible locations
		possiblePaths := []string{
			"barrimapp-abd32-firebase-adminsdk-fbsvc-8b71de8fde.json",
			"../barrimapp-abd32-firebase-adminsdk-fbsvc-8b71de8fde.json",
			"./barrimapp-abd32-firebase-adminsdk-fbsvc-8b71de8fde.json",
			// fallbacks for legacy credentials

		}

		for _, path := range possiblePaths {
			if _, err := os.Stat(path); err == nil {
				credFile = path
				break
			}
		}

		if credFile == "" {
			log.Fatalf("Firebase service account file not found. Please set GOOGLE_APPLICATION_CREDENTIALS environment variable, FIREBASE_CREDENTIALS_BASE64, or place the file in one of these locations: %v", possiblePaths)
		}
	}

	log.Printf("Using Firebase credentials file: %s", credFile)
	opt := option.WithCredentialsFile(credFile)

	// Create Firebase config with project ID
	config := &firebase.Config{
		ProjectID: projectID,
	}

	app, err := firebase.NewApp(ctx, config, opt)
	if err != nil {
		log.Fatalf("error initializing firebase app: %v\n", err)
	}
	FirebaseApp = app
}
