import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class NewPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const NewPasswordPage({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _resetSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Function to reset password
  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate passwords
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a password';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call the API service
      final response = await ApiService.verifyOTPAndResetPassword(widget.otp, password);

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        setState(() {
          _resetSuccess = true;
        });

        // Show success message and navigate to login after a delay
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful! Please log in with your new password.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to login after short delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0A1172)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/logo/logo.png',
                height: 80,
                width: 80,
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'New Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1172), // Dark blue
                ),
              ),
              const SizedBox(height: 16),

              // Password requirements
              const Text(
                'Password must be at least\n8 characters.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              if (_resetSuccess)
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Password Reset Successful!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Redirecting to login page...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),

                    const SizedBox(height: 36),

                    // Reset Password Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2), // Blue
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Back to Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Back to ',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to login page
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
}