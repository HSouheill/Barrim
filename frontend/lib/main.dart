import 'package:admin_dashboard/src/screens/forget_password/forgot_password.dart';
import 'package:admin_dashboard/src/screens/homepage/homepage.dart';
import 'package:admin_dashboard/src/screens/sales_management/sales_manager/sales_manager_dashboard.dart';
import 'package:admin_dashboard/src/screens/sales_management/salesperson/salesperson_dashboard.dart';
import 'package:admin_dashboard/src/screens/sales_management/manager/manager_dashboard.dart';
import 'package:admin_dashboard/src/services/api_services.dart';
import 'package:admin_dashboard/src/components/session_wrapper.dart';
import 'package:admin_dashboard/src/utils/last_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:admin_dashboard/src/utils/session_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  
  // // Web-specific optimizations
  // if (kIsWeb) {
  //   // Enable web performance optimizations
  //   // Reduce memory usage and improve loading speed
  //   debugPrint('Web platform detected - applying performance optimizations');
  // }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barrim Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D1752)),
        useMaterial3: true,
      ),
      // Use builder to force mobile view on web
      builder: (context, child) {
        // Only apply mobile view constraints on web platform
        if (kIsWeb) {
          // Define standard mobile dimensions
          const double mobileWidth = 390.0; // iPhone 12/13 width

          return Center(
            child: ClipRect(
              child: SizedBox(
                width: mobileWidth,
                height: MediaQuery.of(context).size.height,
                child: MediaQuery(
                  // Override MediaQuery to make the app think it's on a mobile device
                  data: MediaQuery.of(context).copyWith(
                    size: Size(mobileWidth, MediaQuery.of(context).size.height),
                    devicePixelRatio: 1.0,
                    textScaleFactor: 1.0,
                  ),
                  child: child!,
                ),
              ),
            ),
          );
        }
        return child!;
      },
      home: const SessionWrapper(
        child: RootDecider(),
        onSessionExpired: _handleSessionExpired,
      ),
    );
  }

  // Handle session expiration
  static void _handleSessionExpired() {
    // This will be called when the session expires
    // The session wrapper will handle the UI updates
  }
}

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  Future<Widget> _resolveHome() async {
    final session = SessionManager();
    await session.initialize();
    final hasToken = await session.hasStoredToken();

    if (hasToken) {
      final saved = await LastRouteService.load();
      if (saved == 'sales_manager') return const SalesManagerDashboard();
      if (saved == 'salesperson') return const SalespersonDashboard();
      if (saved == 'manager') return const ManagerDashboard();
      if (saved == 'admin') return const DashboardPage();

      final userType = await ApiService.getCurrentUserType();
      if (userType == 'sales_manager' || userType == 'salesManager') {
        await LastRouteService.save('sales_manager');
        return const SalesManagerDashboard();
      }
      if (userType == 'salesperson') {
        await LastRouteService.save('salesperson');
        return const SalespersonDashboard();
      }
      if (userType == 'manager') {
        await LastRouteService.save('manager');
        return const ManagerDashboard();
      }
      if (userType == 'admin' || userType == 'administrator') {
        await LastRouteService.save('admin');
        return const DashboardPage();
      }
    }

    final loggedIn = await ApiService.isLoggedIn();
    if (loggedIn) {
      final saved = await LastRouteService.load();
      if (saved == 'sales_manager') return const SalesManagerDashboard();
      if (saved == 'salesperson') return const SalespersonDashboard();
      if (saved == 'manager') return const ManagerDashboard();
      if (saved == 'admin') return const DashboardPage();
    }

    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveHome(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data ?? const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Add loading state
  bool _isLoading = false;
  String _errorMessage = '';

  // Set to true to use an image file from assets, or false to use the custom painter
  final bool _useImageLogo = true;
  // Path to your logo image in assets directory
  final String _logoPath = 'assets/logo/logo.png';

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    _checkLoginStatus();
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await ApiService.isLoggedIn();
    if (isLoggedIn) {
      // Get user type from stored user info
      final userType = await ApiService.getCurrentUserType();
      
      // Navigate based on user type
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (userType == 'sales_manager' || userType == 'salesManager') {
          await LastRouteService.save('sales_manager');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SalesManagerDashboard()),
          );
        }
        else if (userType == 'salesperson') {
          await LastRouteService.save('salesperson');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SalespersonDashboard()),
          );
        }
        else if (userType == 'manager') {
          await LastRouteService.save('manager');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ManagerDashboard()),
          );
        } else if (userType == 'admin' || userType == 'administrator') {
          _navigateToDashboard();
        } // else do nothing (stay on login)
      });
    }
  }

  // Navigate to dashboard page
  void _navigateToDashboard() {
    LastRouteService.save('admin');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardPage()),
    );
  }

  // Handle login process
  Future<void> _handleLogin() async {
    // Validate form fields
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password are required';
      });
      return;
    }

    // Clear error message and show loading
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      // Call login API with timeout to prevent app from pausing
      final response = await ApiService.unifiedLogin(
        _emailController.text.trim(),
        _passwordController.text,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Login timeout. Please check your internet connection and try again.');
        },
      );

      // Debug: Print the whole response
      print('Login response: ${response.data}');

      // Hide loading
      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        // Get user type from response data
        final userType = response.data['user']['type'];
        // Debug: Print userType
        print('Logged in userType: ${userType}');
        
        // Navigate based on user type
       if (userType == 'sales_manager' || userType == 'salesManager') {
          await LastRouteService.save('sales_manager');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SalesManagerDashboard()),
          );
        }
        else if (userType == 'salesperson') {
           await LastRouteService.save('salesperson');
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(builder: (context) => const SalespersonDashboard()),
           );
         }
       else if (userType == 'manager') {
          await LastRouteService.save('manager');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ManagerDashboard()),
          );
        } else if (userType == 'admin' || userType == 'administrator') {
          _navigateToDashboard();
        } else {
          // Show error for unknown user type
          setState(() {
            _errorMessage = 'Unknown user type: ${userType}';
          });
        }
      } else {
        // Show user-friendly error message for failed login
        String errorMessage = response.message;
        
        // Handle specific error cases with user-friendly messages
        if (errorMessage.toLowerCase().contains('invalid') || 
            errorMessage.toLowerCase().contains('incorrect') ||
            errorMessage.toLowerCase().contains('wrong') ||
            errorMessage.toLowerCase().contains('failed') ||
            errorMessage.toLowerCase().contains('unauthorized') ||
            errorMessage.toLowerCase().contains('401')) {
          errorMessage = 'Incorrect email or password. Please try again.';
        } else if (errorMessage.toLowerCase().contains('timeout')) {
          errorMessage = 'Login timeout. Please check your internet connection and try again.';
        } else if (errorMessage.toLowerCase().contains('network') || 
                   errorMessage.toLowerCase().contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (errorMessage.toLowerCase().contains('server')) {
          errorMessage = 'Server error. Please try again later.';
        }
        
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      // Handle exceptions with user-friendly messages
      print('Login error caught: $e');
      
      String errorMessage = 'An error occurred during login.';
      
      // Handle specific exception types
      if (e.toString().toLowerCase().contains('timeout')) {
        errorMessage = 'Login timeout. Please check your internet connection and try again.';
      } else if (e.toString().toLowerCase().contains('network') || 
                 e.toString().toLowerCase().contains('connection') ||
                 e.toString().toLowerCase().contains('socket')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().toLowerCase().contains('stream') ||
                 e.toString().toLowerCase().contains('addstream')) {
        errorMessage = 'Incorrect email or password. Please try again.';
      } else if (e.toString().toLowerCase().contains('unauthorized') ||
                 e.toString().toLowerCase().contains('401')) {
        errorMessage = 'Incorrect email or password. Please try again.';
      }
      
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
    } finally {
      // Ensure loading state is always reset
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Add a container with mobile device frame when on web
      body: SafeArea(
        child: kIsWeb
            ? _buildMobileFrame(context)
            : _buildLoginContent(context),
      ),
    );
  }

  // This creates a visual mobile device frame when running on web
  Widget _buildMobileFrame(BuildContext context) {
    return Center(
      child: Container(
        width: 390, // iPhone 12/13 width
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kIsWeb ? 20 : 0),
          boxShadow: kIsWeb ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ] : null,
        ),
        child: _buildLoginContent(context),
      ),
    );
  }

  // The actual login content
  Widget _buildLoginContent(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity, // Take full width up to constraints
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo - Optimized for web
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
              // Login text
              const Text(
                'Login',
                style: TextStyle(
                  color: Color(0xFF05055A),
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Email Address',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Color(0xFF1F4889)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Color(0xFF1F4889)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF1F4889)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: _isLoading ? null : () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Color(0xFF1F4889)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF1F4889)),
                  ),
                ),
              ),

              // Error message
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),

              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Color(0xFF1F4889),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Login button with loading state
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2079C2),
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
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Custom logo builder
  Widget _buildCustomLogo() {
    return Container(
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
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the main logo shape (white)
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Paint for the blue dot
    final Paint dotPaint = Paint()
      ..color = const Color(0xFF1F4889)
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

