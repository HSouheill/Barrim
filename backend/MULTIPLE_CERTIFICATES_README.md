# Multiple Certificates Feature

This document describes the implementation of multiple certificates support for service providers in the Barrim backend.

## Overview

Service providers can now upload and manage multiple certificates instead of being limited to a single certificate. This allows them to showcase various qualifications, licenses, and certifications.

## Changes Made

### 1. Model Updates (`models/user.go`)

- Changed `CertificateImage` field from `string` to `CertificateImages []string` in `ServiceProviderInfo` struct
- Updated `UpdateServiceProviderRequest` to use `CertificateImages []string`

### 2. Controller Updates (`controllers/serviceProvider_referral_controller.go`)

- Updated `ServiceProviderWithUserData` struct to use `CertificateImages []string`
- Modified `UploadCertificateImage` function to append new certificates to the array using `$push`
- Added new functions:
  - `GetCertificates()` - Retrieve all certificates for a service provider
  - `DeleteCertificate()` - Remove a specific certificate
  - `GetCertificateDetails()` - Get detailed information about a specific certificate

### 3. Route Updates (`routes/user_routes.go`)

Added new endpoints:
- `GET /api/service-provider/certificates` - Get all certificates
- `DELETE /api/service-provider/certificate` - Delete a specific certificate
- `GET /api/service-provider/certificate/details` - Get certificate details

## API Endpoints

### Upload Certificate
```
POST /api/service-provider/certificate
Content-Type: multipart/form-data

Form data:
- certificate: file (image)
```

**Response:**
```json
{
  "status": 200,
  "message": "Certificate image uploaded successfully",
  "data": {
    "certificateImage": "uploads/certificates/certificate_123_20231201123456.jpg",
    "message": "Certificate added to your collection"
  }
}
```

### Get All Certificates
```
GET /api/service-provider/certificates
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": 200,
  "message": "Certificates retrieved successfully",
  "data": {
    "certificates": [
      "uploads/certificates/certificate_123_20231201123456.jpg",
      "uploads/certificates/certificate_123_20231202123456.png"
    ],
    "count": 2
  }
}
```

### Delete Certificate
```
DELETE /api/service-provider/certificate
Authorization: Bearer <token>
Content-Type: application/json

{
  "certificatePath": "uploads/certificates/certificate_123_20231201123456.jpg"
}
```

**Response:**
```json
{
  "status": 200,
  "message": "Certificate deleted successfully",
  "data": {
    "deletedPath": "uploads/certificates/certificate_123_20231201123456.jpg"
  }
}
```

### Get Certificate Details
```
GET /api/service-provider/certificate/details?path=uploads/certificates/certificate_123_20231201123456.jpg
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": 200,
  "message": "Certificate details retrieved successfully",
  "data": {
    "filename": "certificate_123_20231201123456.jpg",
    "path": "uploads/certificates/certificate_123_20231201123456.jpg",
    "size": 1024000,
    "uploadedAt": "2023-12-01T12:34:56Z",
    "isReadable": true
  }
}
```

## Migration

A migration script (`migrate_certificates.js`) is provided to convert existing single certificate data to the new multiple certificates format.

### Running the Migration

1. Ensure MongoDB is running
2. Install dependencies: `npm install mongodb`
3. Run the migration: `node migrate_certificates.js`

The migration will:
- Find all service providers with the old `certificateImage` field
- Convert the single certificate to an array format
- Remove the old field
- Log the migration progress

## Database Schema Changes

### Before
```json
{
  "serviceProviderInfo": {
    "certificateImage": "uploads/certificates/certificate.jpg"
  }
}
```

### After
```json
{
  "serviceProviderInfo": {
    "certificateImages": [
      "uploads/certificates/certificate1.jpg",
      "uploads/certificates/certificate2.png"
    ]
  }
}
```

## File Storage

Certificates are stored in the `uploads/certificates/` directory with the following naming convention:
```
certificate_{userID}_{timestamp}{extension}
```

Example: `certificate_507f1f77bcf86cd799439011_20231201123456.jpg`

## Security Considerations

- Only authenticated service providers can access certificate endpoints
- File validation ensures only image files are accepted
- Physical files are deleted when certificates are removed from the database
- File paths are validated to prevent directory traversal attacks

## Error Handling

The system handles various error scenarios:
- Invalid file types
- Missing authentication tokens
- Non-existent certificates
- File system errors
- Database connection issues

## Future Enhancements

Potential improvements for the future:
- Certificate categories/tags
- Certificate expiration dates
- Certificate verification status
- Bulk upload functionality
- Certificate preview thumbnails
- Certificate sharing between service providers
