import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import 'otp.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false; // Added loading state
  String? _errorMessage; // Added error message

  // Set to true to use an image file from assets, or false to use the custom painter
  final bool _useImageLogo = true;
  // Path to your logo image in assets directory
  final String _logoPath = 'assets/logo/logo.png';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Function to handle forgot password request
  Future<void> _handleForgotPassword() async {
    // Validate email
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }

    // Simple email validation
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call the API service
      final response = await ApiService.forgotPassword();

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        // Navigate to OTP verification page
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(email: email),
          ),
        );
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
    // Get the current screen size for responsiveness
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isSmallScreen ? size.width : 400,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  _useImageLogo
                      ? Container(
                    width: 170,
                    height: 170,
                    decoration: const BoxDecoration(
                      color: Color(0x00000000),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        _logoPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                      : Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D1752),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(40, 40),
                        painter: LogoPainter(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  // Forgot Password text
                  const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF05055A),
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Instructional text
                  const Text(
                    'No worries, we\'ll send you the reset instructions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF555B7C),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Email field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF0D1752)),
                      ),
                      errorText: _errorMessage,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Send OTP button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
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
                        'Send OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Back to Login link
                  TextButton(
                    onPressed: () {
                      // Navigate back to login page
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Back to Log In',
                      style: TextStyle(
                        color: Color(0xFF0D1752),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for the logo
class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the main logo shape (white)
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Paint for the blue dot
    final Paint dotPaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;

    // Draw stylized '6' or droplet-like shape for the logo
    final Path path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.2);
    path.quadraticBezierTo(
        size.width * 0.1, size.height * 0.4,
        size.width * 0.3, size.height * 0.6
    );
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.8,
        size.width * 0.7, size.height * 0.6
    );
    path.quadraticBezierTo(
        size.width * 0.9, size.height * 0.4,
        size.width * 0.7, size.height * 0.2
    );
    path.close();

    // Draw the path
    canvas.drawPath(path, paint);

    // Draw the blue dot
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.8),
      size.width * 0.08,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
