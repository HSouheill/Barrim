


class ApiConstants {
  // Base URL for the API
  static const String baseUrl = 'https://barrim.online'; // Direct reference to avoid circular dependency

  // API endpoints
  static const String login = '/api/admin/login';
  static const String forgotPassword = '/api/admin/forgot-password';
  static const String verifyOtpReset = '/api/admin/verify-otp-reset';
  static const String users = '/api/admin/users';
  static const String allUsers = '/api/admin/users/all';
  static const String salespersons = '/api/admin/salespersons';
  
  // Salesperson management endpoints
  static const String createSalesperson = '/api/admin/salespersons';
  static const String GetAdminSalespersons = '/api/admin/salespersons';
  static const String getAllSalespersons = '/api/admin/salespersons/all';
  static const String getSalesperson = '/api/admin/salespersons/';
  static const String updateSalesperson = '/api/admin/salespersons/';
  static const String deleteSalesperson = '/api/admin/salespersons/';
  
  // New authentication endpoints
  static const String validateToken = '/api/auth/validate-token';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String logout = '/api/auth/logout';
  
  // Login endpoints for different user types
  static const String adminLogin = '/api/admin/login';
  static const String salesManagerLogin = '/api/admin/login';
  static const String managerLogin = '/api/admin/login';
  static const String salespersonLogin = '/api/admin/login';
  
  // User management endpoints
  static const String getActiveUsers = '/api/admin/users';
  static const String getUserStatus = '/api/admin/users/';
  static const String createSalesManager = '/api/admin/sales-managers';
  static const String getAllSalesManagers = '/api/admin/sales-managers';
  static const String getSalesManager = '/api/admin/sales-managers/';
  static const String updateSalesManager = '/api/admin/sales-managers/';
  static const String deleteSalesManager = '/api/admin/sales-managers/';
  
  // Manager management endpoints
  static const String createManager = '/api/admin/Create-managers';
  static const String getManagers = '/api/admin/managers';
  static const String updateManager = '/api/admin/managers/';
  static const String deleteManager = '/api/admin/managers/';
  
  // Approval endpoints
  static const String getPendingCompanies = '/api/admin/manager/pending/companies';
  static const String getPendingServiceProviders = '/api/admin/manager/pending/serviceproviders';
  static const String getPendingWholesalers = '/api/admin/manager/pending/wholesalers';
  static const String approveCompany = '/api/admin/manager/approve/company/';
  static const String approveServiceProvider = '/api/admin/manager/approve/serviceprovider/';
  static const String approveWholesaler = '/api/admin/manager/approve/wholesaler/';
  static const String denyCompany = '/api/admin/manager/deny/company/';
  static const String denyServiceProvider = '/api/admin/manager/deny/serviceprovider/';
  static const String denyWholesaler = '/api/admin/manager/deny/wholesaler/';
  
  // Entity endpoints
  static const String getAllEntities = '/api/admin/all-entities';
  
  // Admin wallet endpoints
  static const String getAdminWallet = '/api/admin/wallet';
  
  // Utility endpoints
  static const String checkEmailOrPhoneExists = '/api/auth/check-exists';
  
  // Review management endpoints
  static const String getAllReviewsForAdmin = '/api/admin/reviews';
  static const String deleteReview = '/api/admin/reviews';
  
  // Booking management endpoints
  static const String getAllBookingsForAdmin = '/api/admin/bookings'; // TODO: Implement this endpoint in backend
  static const String deleteBooking = '/api/admin/bookings'; // TODO: Implement this endpoint in backend
  
  // Sponsorship endpoints
  static const String createServiceProviderSponsorship = '/api/admin/sponsorships/service-provider';
  static const String createCompanyWholesalerSponsorship = '/api/admin/sponsorships/company-wholesaler';
  
  // Sponsorship Subscription Request endpoints
  static const String getPendingSponsorshipSubscriptionRequests = '/api/admin/sponsorship-subscriptions/requests/pending';
  static const String processSponsorshipSubscriptionRequest = '/api/admin/sponsorship-subscriptions/requests';
  static const String getActiveSponsorshipSubscriptions = '/api/admin/sponsorship-subscriptions/active';
  
  // Category endpoints
  static const String getAllCategories = '/api/categories';
  static const String getCategory = '/api/categories';
  static const String createCategory = '/api/admin/categories';
  static const String updateCategory = '/api/admin/categories';
  static const String deleteCategory = '/api/admin/categories';
  static const String uploadCategoryLogo = '/api/admin/categories'; // Will be appended with /:id/logo
  
  // Service Provider Category endpoints
  static const String getAllServiceProviderCategories = '/api/service-provider-categories';
  static const String getServiceProviderCategory = '/api/service-provider-categories';
  static const String createServiceProviderCategory = '/api/admin/service-provider-categories';
  static const String updateServiceProviderCategory = '/api/admin/service-provider-categories';
  static const String deleteServiceProviderCategory = '/api/admin/service-provider-categories';
  
  // Wholesaler Category endpoints
  static const String getAllWholesalerCategories = '/api/wholesaler-categories';
  static const String getWholesalerCategory = '/api/wholesaler-categories';
  static const String createWholesalerCategory = '/api/admin/wholesaler-categories';
  static const String updateWholesalerCategory = '/api/admin/wholesaler-categories';
  static const String deleteWholesalerCategory = '/api/admin/wholesaler-categories';
  
  static const String getSponsorships = '/api/admin/sponsorships';
  static const String getSponsorship = '/api/admin/sponsorships/';
  static const String updateSponsorship = '/api/admin/sponsorships/';
  static const String deleteSponsorship = '/api/admin/sponsorships/';
  
  // Voucher endpoints
  static const String createVoucher = '/api/admin/vouchers';
  static const String createUserTypeVoucher = '/api/admin/vouchers/user-type';
  static const String getAllVouchers = '/api/admin/vouchers';
  static const String updateVoucher = '/api/admin/vouchers';
  static const String deleteVoucher = '/api/admin/vouchers';
  static const String toggleVoucherStatus = '/api/admin/vouchers';
}