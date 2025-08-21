import 'package:flutter/foundation.dart';

/// Performance configuration for the admin dashboard app
class PerformanceConfig {
  // Session management intervals
  static const Duration sessionCheckInterval = Duration(hours: 1); // Increased for development
  static const Duration activityCheckInterval = Duration(hours: 1); // Increased for development
  static const Duration tokenRefreshThreshold = Duration(hours: 1); // Increased for development
  
  // API timeouts
  static const Duration loginTimeout = Duration(seconds: 15); // Increased for better user experience
  static const Duration apiRequestTimeout = Duration(seconds: 15); // Reduced for faster response
  
  // Web optimizations
  static const bool enableWebOptimizations = true;
  static const bool enableImageCaching = true;
  static const int maxImageCacheSize = 100; // MB
  
  // Web-specific performance settings
  static const bool enableWebLazyLoading = true;
  static const bool enableWebPrecompilation = true;
  static const bool disableWebDebugFeatures = true; // Disable debug features in web for better performance
  
  // Debug settings
  static const bool enablePerformanceLogging = kDebugMode;
  static const bool enableApiResponseLogging = kDebugMode;
  
  // Asset optimization
  static const bool enableLazyLoading = true;
  static const bool enableAssetPreloading = false; // Disabled for better initial load time
  
  // Memory management
  static const bool enableMemoryOptimization = true;
  static const int maxCachedWidgets = 50;
  
  /// Get optimal image dimensions for current platform
  static Map<String, double> getOptimalImageDimensions() {
    if (kIsWeb) {
      return {
        'logo': 170.0,
        'icon': 80.0,
        'thumbnail': 120.0,
      };
    } else {
      return {
        'logo': 170.0,
        'icon': 80.0,
        'thumbnail': 120.0,
      };
    }
  }
  
  /// Check if performance optimizations should be enabled
  static bool shouldEnableOptimizations() {
    return enableWebOptimizations || !kIsWeb;
  }
}
