import 'package:flutter/material.dart';
import '../utils/session_manager.dart';
import '../services/api_services.dart';

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
  bool _isRetrying = false;

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
        final hasToken = await _sessionManager.hasStoredToken();
        if (!mounted) return;
        if (hasToken) {
          setState(() {
            _isSessionValid = true; // treat as valid on reload if token exists
            _sessionError = null;
          });
        } else {
          final isValid = await _sessionManager.isSessionValid();
          if (mounted) {
            setState(() {
              _isSessionValid = isValid;
              _sessionError = isValid ? null : 'Session validation failed';
            });
          }
        }
      }).catchError((error) {
        debugPrint('Error during session initialization: $error');
        if (mounted) {
          setState(() {
            _isSessionValid = true; // be permissive on init errors if token exists
            _sessionError = null;
          });
        }
      });
      
      // Set initial state optimistically; will be confirmed above
      setState(() {
        _isSessionValid = true;
        _sessionError = null;
      });
    } catch (e) {
      debugPrint('Error initializing session: $e');
      setState(() {
        _isSessionValid = true;
        _sessionError = null;
      });
    }
  }

  void _listenToSessionEvents() {
    _sessionManager.sessionStatusStream.listen((isValid) {
      if (mounted) {
        setState(() {
          _isSessionValid = isValid;
        });
        
        if (!isValid) {
          _handleSessionExpired();
        }
      }
    });

    _sessionManager.sessionErrorStream.listen((error) {
      if (mounted) {
        setState(() {
          _sessionError = error;
        });
        
        if (error.contains('expired') || error.contains('invalid')) {
          _handleSessionExpired();
        }
      }
    });
  }

  void _handleSessionExpired() {
    // Do not auto-clear auth on first sign; allow retry without losing tokens
    _showSessionExpiredDialog();
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
              onPressed: _isRetrying ? null : () {
                Navigator.of(context).pop();
                _attemptSessionRefresh();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isRetrying 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Retry'),
            ),
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

  Future<void> _attemptSessionRefresh() async {
    try {
      // Show loading state
      setState(() {
        _sessionError = 'Attempting to refresh session...';
        _isRetrying = true;
      });

      // Use the enhanced retry method with multiple attempts
      final refreshSuccess = await _sessionManager.retrySessionRefresh(maxRetries: 3);
      
      if (refreshSuccess) {
        // Use enhanced validation to get detailed results
        final validationResult = await _sessionManager.validateSessionWithDetails();
        
        if (validationResult['isValid']) {
          setState(() {
            _isSessionValid = true;
            _sessionError = null;
          });
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session refreshed successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() {
            _isSessionValid = false;
            _sessionError = validationResult['reason'] ?? 'Session refresh failed. Please login again.';
          });
        }
      } else {
        setState(() {
          _isSessionValid = false;
          _sessionError = 'Unable to refresh session after multiple attempts. Please login again.';
        });
      }
    } catch (e) {
      debugPrint('Error during session refresh: $e');
      setState(() {
        _isSessionValid = false;
        _sessionError = 'Session refresh failed: ${e.toString()}';
        _isRetrying = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh session: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Ensure loading state is always reset
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                _sessionError ?? 'Your session has expired. Please try to refresh or log in again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _attemptSessionRefresh,
                    icon: _isRetrying 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isRetrying ? 'Retrying...' : 'Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2079C2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _navigateToLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('Login Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2079C2),
                      side: const BorderSide(color: Color(0xFF2079C2)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
