# Admin Reviews and Bookings Management

This document describes the new admin functionality for managing reviews and bookings in the Barrim admin dashboard.

## Features

### Reviews Management
- View all reviews with pagination
- Filter reviews by:
  - Service Provider ID
  - Rating (1-5 stars)
  - Verification status (verified/unverified)
- Delete reviews with confirmation dialog
- Display review details including:
  - Star rating visualization
  - User and service provider information
  - Review comment and timestamp
  - Verification status

### Bookings Management
- View all bookings with pagination
- Filter bookings by:
  - Service Provider ID
  - User ID
  - Status (pending, confirmed, completed, cancelled)
- Delete bookings with confirmation dialog
- Display booking details including:
  - Status with color-coded badges
  - Booking date and amount
  - User and service provider information
  - Notes and timestamps

## Files Created/Modified

### New Files
- `lib/src/models/review_model.dart` - Review data model
- `lib/src/models/booking_model.dart` - Booking data model
- `lib/src/services/admin_review_service.dart` - Review management service
- `lib/src/services/admin_booking_service.dart` - Booking management service
- `lib/src/screens/bookings_and_reviews.dart` - Main admin interface

### Modified Files
- `lib/src/services/api_constant.dart` - Added review endpoints
- `lib/src/components/sidebar.dart` - Added navigation menu item

## API Integration

### Reviews Endpoints
- `GET /api/admin/reviews` - Get all reviews with pagination and filtering
- `DELETE /api/admin/reviews/:id` - Delete a specific review

### Bookings Endpoints
- Currently using placeholder/mock data
- Ready for integration when backend endpoints are available

## Usage

1. **Access**: Navigate to "Bookings & Reviews" from the admin sidebar
2. **Switch Tabs**: Use the tab bar to switch between Reviews and Bookings
3. **Filter Data**: Click the "Filters" button to apply search criteria
4. **Refresh**: Use the "Refresh" button to reload data
5. **Delete**: Click the delete icon on any item to remove it
6. **Navigate**: Use pagination controls at the bottom for large datasets

## Security

- All endpoints require admin authentication
- Only users with admin, super_admin, or manager roles can access
- Delete operations require confirmation before execution

## Future Enhancements

- Add bulk delete operations
- Implement review/booking editing
- Add export functionality
- Enhanced search and filtering
- Real-time updates
- Audit logging for deletions

## Dependencies

- Flutter Material Design
- HTTP package for API calls
- Intl package for date formatting
- Secure storage for authentication

## Notes

- The booking service currently returns mock data
- Review service is fully integrated with the backend
- All delete operations are permanent and cannot be undone
- The interface is responsive and works on both mobile and web platforms
