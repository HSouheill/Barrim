import 'package:flutter/material.dart';
import '../utils/session_manager.dart';
import '../services/api_services.dart';
import 'session_status_indicator.dart';

/// Example of how to integrate session management in a dashboard screen
class DashboardWithSessionExample extends StatefulWidget {
  const DashboardWithSessionExample({super.key});

  @override
  State<DashboardWithSessionExample> createState() => _DashboardWithSessionExampleState();
}

class _DashboardWithSessionExampleState extends State<DashboardWithSessionExample> {
  final SessionManager _sessionManager = SessionManager();
  bool _isSessionValid = true;
  Duration? _timeUntilExpiry;
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _listenToSessionEvents();
  }

  Future<void> _initializeSession() async {
    try {
      await _sessionManager.initialize();
      final isValid = await _sessionManager.isSessionValid();
      
      if (mounted) {
        setState(() {
          _isSessionValid = isValid;
        });
      }
      
      if (isValid) {
        _updateSessionStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSessionValid = false;
          _sessionError = e.toString();
        });
      }
    }
  }

  void _listenToSessionEvents() {
    // Listen to session status changes
    _sessionManager.sessionStatusStream.listen((isValid) {
      if (mounted) {
        setState(() {
          _isSessionValid = isValid;
        });
        
        if (isValid) {
          _updateSessionStatus();
        }
      }
    });

    // Listen to session errors
    _sessionManager.sessionErrorStream.listen((error) {
      if (mounted) {
        setState(() {
          _sessionError = error;
        });
      }
    });
  }

  Future<void> _updateSessionStatus() async {
    try {
      final timeUntilExpiry = await _sessionManager.getTimeUntilExpiry();
      if (mounted) {
        setState(() {
          _timeUntilExpiry = timeUntilExpiry;
        });
      }
    } catch (e) {
      // Ignore errors during status updates
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Perform logout
        await ApiService.logout();
        
        // Navigate to login (this will be handled by SessionWrapper)
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshToken() async {
    try {
      final success = await _sessionManager.refreshToken();
      if (success) {
        await _updateSessionStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token refreshed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to refresh token'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing token: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSessionInfo() {
    final stats = _sessionManager.getSessionStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session Valid: ${stats['isValid']}'),
            Text('User Active: ${stats['isUserActive']}'),
            Text('Session Timeout: ${stats['sessionTimeout']} minutes'),
            Text('Activity Timeout: ${stats['activityTimeout']} minutes'),
            if (_timeUntilExpiry != null)
              Text('Time Until Expiry: ${_formatDuration(_timeUntilExpiry!)}'),
            if (_sessionError != null)
              Text('Error: $_sessionError', style: const TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Expired';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard with Session Management'),
        actions: [
          // Session status indicator
          SessionStatusIndicator(
            showRefreshButton: true,
            onSessionExpired: () {
              // This will be handled by SessionWrapper
            },
          ),
          // Session info button
          IconButton(
            onPressed: _showSessionInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Session Information',
          ),
          // Logout button
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSessionValid ? Icons.check_circle : Icons.error,
                          color: _isSessionValid ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Session Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSessionValid ? 'Active' : 'Expired',
                      style: TextStyle(
                        color: _isSessionValid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_timeUntilExpiry != null) ...[
                      const SizedBox(height: 8),
                      Text('Time until expiry: ${_formatDuration(_timeUntilExpiry!)}'),
                    ],
                    if (_sessionError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_sessionError',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshToken,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Token'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showSessionInfo,
                  icon: const Icon(Icons.info),
                  label: const Text('Session Info'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Dashboard content placeholder
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Content',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This is where your actual dashboard content would go. '
                      'The session management system is running in the background '
                      'to ensure security and provide a seamless user experience.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Note: Don't dispose SessionManager here as it's a singleton
    super.dispose();
  }
}
