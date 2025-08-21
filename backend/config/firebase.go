package config

import (
	"context"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"google.golang.org/api/option"
)

var FirebaseApp *firebase.App

// InitFirebase initializes the Firebase Admin SDK
func InitFirebase() {
	ctx := context.Background()
	credFile := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
	if credFile == "" {
		credFile = "barrim-3b45a-firebase-adminsdk-fbsvc-44cc12116d.json" // fallback to default if not set
	}
	opt := option.WithCredentialsFile(credFile)
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Fatalf("error initializing firebase app: %v\n", err)
	}
	FirebaseApp = app
}
