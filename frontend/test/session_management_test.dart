import 'package:flutter_test/flutter_test.dart';
import 'package:admin_dashboard/src/utils/session_manager.dart';
import 'package:admin_dashboard/src/services/api_services.dart';

void main() {
  group('Session Management Tests', () {
    test('SessionManager singleton pattern', () {
      final instance1 = SessionManager();
      final instance2 = SessionManager();
      expect(identical(instance1, instance2), true);
    });

    test('Session timeout configuration', () {
      final sessionManager = SessionManager();
      expect(sessionManager.sessionTimeout.inHours, 24);
    });

    test('Token refresh retry mechanism', () async {
      final sessionManager = SessionManager();
      // This test verifies the retry mechanism exists
      expect(sessionManager.attemptTokenRefreshWithRetry, isA<Function>());
    });

    test('Session statistics', () async {
      final sessionManager = SessionManager();
      final stats = sessionManager.getSessionStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('isValid'), true);
      expect(stats.containsKey('isUserActive'), true);
    });
  });

  group('API Service Tests', () {
    test('Logout method exists', () {
      expect(ApiService.logout, isA<Function>());
    });

    test('Validate token method exists', () {
      expect(ApiService.validateToken, isA<Function>());
    });

    test('Refresh token method exists', () {
      expect(ApiService.refreshToken, isA<Function>());
    });
  });
}
