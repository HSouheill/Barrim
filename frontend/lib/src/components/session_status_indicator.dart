import 'package:flutter/material.dart';
import '../utils/session_manager.dart';
import '../services/api_services.dart';

class SessionStatusIndicator extends StatefulWidget {
  final bool showRefreshButton;
  final VoidCallback? onSessionExpired;

  const SessionStatusIndicator({
    super.key,
    this.showRefreshButton = true,
    this.onSessionExpired,
  });

  @override
  State<SessionStatusIndicator> createState() => _SessionStatusIndicatorState();
}

class _SessionStatusIndicatorState extends State<SessionStatusIndicator> {
  final SessionManager _sessionManager = SessionManager();
  bool _isSessionValid = true;
  bool _isRefreshing = false;
  Duration? _timeUntilExpiry;
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    _initializeSessionStatus();
    _listenToSessionEvents();
    _startStatusUpdates();
  }

  Future<void> _initializeSessionStatus() async {
    try {
      final isValid = await _sessionManager.isSessionValid();
      final timeUntilExpiry = await _sessionManager.getTimeUntilExpiry();
      
      setState(() {
        _isSessionValid = isValid;
        _timeUntilExpiry = timeUntilExpiry;
      });
    } catch (e) {
      setState(() {
        _isSessionValid = false;
        _sessionError = 'Failed to check session status';
      });
    }
  }

  void _listenToSessionEvents() {
    _sessionManager.sessionStatusStream.listen((isValid) {
      setState(() {
        _isSessionValid = isValid;
      });
      
      if (!isValid) {
        widget.onSessionExpired?.call();
      }
    });

    _sessionManager.sessionErrorStream.listen((error) {
      setState(() {
        _sessionError = error;
      });
    });
  }

  void _startStatusUpdates() {
    // Update status every minute
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _updateStatus();
        _startStatusUpdates();
      }
    });
  }

  Future<void> _updateStatus() async {
    if (!mounted) return;
    
    try {
      final timeUntilExpiry = await _sessionManager.getTimeUntilExpiry();
      setState(() {
        _timeUntilExpiry = timeUntilExpiry;
      });
    } catch (e) {
      // Ignore errors during status updates
    }
  }

  Future<void> _refreshToken() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final success = await _sessionManager.refreshToken();
      if (success) {
        await _initializeSessionStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh token'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing token: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Unknown';
    
    if (duration.isNegative) return 'Expired';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Color _getStatusColor() {
    if (!_isSessionValid) return Colors.red;
    
    if (_timeUntilExpiry == null) return Colors.grey;
    
    if (_timeUntilExpiry!.isNegative) return Colors.red;
    
    if (_timeUntilExpiry! < const Duration(minutes: 10)) {
      return Colors.orange;
    }
    
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (!_isSessionValid) return Icons.error;
    
    if (_timeUntilExpiry == null) return Icons.help;
    
    if (_timeUntilExpiry!.isNegative) return Icons.error;
    
    if (_timeUntilExpiry! < const Duration(minutes: 10)) {
      return Icons.warning;
    }
    
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Session Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                _isSessionValid 
                    ? 'Valid (${_formatDuration(_timeUntilExpiry)})'
                    : 'Invalid',
                style: TextStyle(
                  fontSize: 11,
                  color: _getStatusColor(),
                ),
              ),
            ],
          ),
          if (widget.showRefreshButton && _isSessionValid) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                onPressed: _isRefreshing ? null : _refreshToken,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Refresh Token',
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
