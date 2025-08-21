import 'package:flutter/material.dart';
import '../utils/session_manager.dart';
import '../services/api_services.dart';
import '../screens/forget_password/forgot_password.dart';

class SessionWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSessionExpired;

  const SessionWrapper({
    super.key,
    required this.child,
    this.onSessionExpired,
  });

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> {
  final SessionManager _sessionManager = SessionManager();
  bool _isSessionValid = true;
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _listenToSessionEvents();
  }

  Future<void> _initializeSession() async {
    try {
      // Initialize session manager asynchronously without blocking UI
      _sessionManager.initialize().then((_) async {
        final isValid = await _sessionManager.isSessionValid();
        if (mounted) {
          setState(() {
            _isSessionValid = isValid;
            _sessionError = isValid ? null : 'Session validation failed';
          });
        }
      });
      
      // Set initial state to allow login page to show immediately
      setState(() {
        _isSessionValid = false; // Will be updated after async initialization
        _sessionError = null;
      });
    } catch (e) {
      debugPrint('Error initializing session: $e');
      setState(() {
        _isSessionValid = false;
        _sessionError = 'Failed to initialize session: ${e.toString()}';
      });
    }
  }

  void _listenToSessionEvents() {
    _sessionManager.sessionStatusStream.listen((isValid) {
      setState(() {
        _isSessionValid = isValid;
      });
      
      if (!isValid) {
        _handleSessionExpired();
      }
    });

    _sessionManager.sessionErrorStream.listen((error) {
      setState(() {
        _sessionError = error;
      });
      
      if (error.contains('expired') || error.contains('invalid')) {
        _handleSessionExpired();
      }
    });
  }

  void _handleSessionExpired() {
    // Clear session data
    ApiService.clearAuthData();
    
    // Show session expired dialog
    _showSessionExpiredDialog();
    
    // Call callback if provided
    widget.onSessionExpired?.call();
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Session Expired'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your session has expired. This can happen due to:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text('• Inactivity for 30 minutes', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('• Token expiration', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('• Security requirements', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 8),
              Text(
                'Please log in again to continue.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2079C2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Login Again'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLogin() {
    // Clear the session and show login page
    _sessionManager.clearSession();
    setState(() {
      _isSessionValid = false;
      _sessionError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If session is not valid, check if we should show login page or session expired
    if (!_isSessionValid) {
      // Check if there's a stored token - if not, show login page
      return FutureBuilder<bool>(
        future: _sessionManager.hasStoredToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final hasStoredToken = snapshot.data ?? false;
          
          // If no stored token, show login page; otherwise show session expired
          if (!hasStoredToken) {
            return widget.child; // Show login page
          } else {
            return _buildSessionExpiredScreen();
          }
        },
      );
    }

    return widget.child;
  }

  Widget _buildSessionExpiredScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Session Expired',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _sessionError ?? 'Please log in again to continue.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToLogin,
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sessionManager.dispose();
    super.dispose();
  }
}
