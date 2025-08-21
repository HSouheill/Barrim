import 'package:flutter/material.dart';

import 'new_password.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email; // Add email parameter

  const OTPVerificationPage({super.key, required this.email});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
        (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(
    4,
        (index) => FocusNode(),
  );

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Get the complete OTP from the controllers
  String _getCompleteOTP() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  // Function to verify OTP
  Future<void> _verifyOTP() async {
    final otp = _getCompleteOTP();

    // Validate OTP
    if (otp.length != 4) {
      setState(() {
        _errorMessage = 'Please enter the 4-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // We'll just verify the OTP here, password reset will be in the next screen
      // For now, just navigate to the NewPasswordPage
      // In a real implementation, you might want to verify OTP first

      // Simulating API call delay
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewPasswordPage(
            email: widget.email,
            otp: otp,
          ),
        ),
      );
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
                'Password Reset',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1172), // Dark blue
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  children: [
                    const TextSpan(text: 'We sent the OTP to your email: '),
                    TextSpan(
                      text: widget.email, // Use the email from widget parameter
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                      (index) => SizedBox(
                    width: 60,
                    height: 60,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24),
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        // Auto focus to next field
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        }
                      },
                    ),
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

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
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
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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

