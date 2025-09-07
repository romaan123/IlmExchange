import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // Temporarily disabled

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen> with TickerProviderStateMixin {
  // Animation and Tab Controller
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  // Form Keys for Validation
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Firebase Instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Temporarily disabled until Google Client ID is configured
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

  // UI State Variables
  bool _isLoginPasswordVisible = false;
  bool _isRegisterPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Show Snackbar with custom styling
  void _showSnackbar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Firebase error message handler
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password should be at least 6 characters long.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Login User
  Future<void> _loginUser() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _loginEmailController.text.trim();
      final password = _loginPasswordController.text.trim();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _showSnackbar("Login Successful! Welcome back.", Colors.green.shade600);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      _showSnackbar(errorMessage);
    } catch (e) {
      _showSnackbar("An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Register User
  Future<void> _registerUser() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _registerEmailController.text.trim();
      final password = _registerPasswordController.text.trim();
      final name = _nameController.text.trim();

      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(name);
      _showSnackbar("Registration Successful! Welcome to IlmExchange.", Colors.green.shade600);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      _showSnackbar(errorMessage);
    } catch (e) {
      _showSnackbar("An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Reset Password
  Future<void> _resetPassword() async {
    Navigator.pushNamed(context, '/forgot-password');
  }

  // Google Sign-In - Temporarily disabled
  Future<void> _signInWithGoogle() async {
    _showSnackbar("Google Sign-In temporarily disabled. Please use email/password.", Colors.orange);

    // TODO: Re-enable when Google Client ID is properly configured
    /*
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      _showSnackbar("Google Sign-In Successful! Welcome.", Colors.green.shade600);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      _showSnackbar(errorMessage);
    } catch (e) {
      _showSnackbar("Google Sign-In failed. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    */
  }

  // Navigate to Home
  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  // Custom Text Field Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? togglePasswordVisibility,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      validator: validator,
      style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: Colors.deepPurple),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: togglePasswordVisibility,
                )
                : null,
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  // Custom Button Builder
  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.deepPurple,
          foregroundColor: textColor ?? Colors.white,
          elevation: 3,
          shadowColor: Colors.deepPurple.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ),
    );
  }

  // Google Sign-In Button
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        icon: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        label: Text(
          'Continue with Google',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  // Build Login Tab
  Widget _buildLoginTab() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _loginEmailController,
            label: 'Email',
            hint: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!_isValidEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _loginPasswordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outlined,
            isPassword: true,
            isPasswordVisible: _isLoginPasswordVisible,
            togglePasswordVisibility: () {
              setState(() => _isLoginPasswordVisible = !_isLoginPasswordVisible);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetPassword,
              child: Text('Forgot Password?', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 20),
          _buildButton(text: 'Login', onPressed: _loginUser, isLoading: _isLoading),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade400)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 16),
          _buildGoogleButton(),
        ],
      ),
    );
  }

  // Build Sign Up Tab
  Widget _buildSignUpTab() {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            prefixIcon: Icons.person_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _registerEmailController,
            label: 'Email',
            hint: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!_isValidEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _registerPasswordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outlined,
            isPassword: true,
            isPasswordVisible: _isRegisterPasswordVisible,
            togglePasswordVisibility: () {
              setState(() => _isRegisterPasswordVisible = !_isRegisterPasswordVisible);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          _buildButton(text: 'Sign Up', onPressed: _registerUser, isLoading: _isLoading),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade400)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 20),
          _buildGoogleButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: screenSize.height - MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    isDarkMode
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Header Section
                    SizedBox(height: screenSize.height * 0.05),

                    // Logo with Hero Animation
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.school_outlined, size: 40, color: Colors.deepPurple),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Welcome Text
                    Text(
                      'Welcome to IlmExchange',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Learn. Teach. Barter.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: screenSize.height * 0.04),

                    // Tab Bar
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.deepPurple),
                        labelColor: Colors.white,
                        unselectedLabelColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        dividerColor: Colors.transparent,
                        tabs: const [Tab(text: 'Login'), Tab(text: 'Sign Up')],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Tab Bar View
                    Expanded(
                      child: TabBarView(controller: _tabController, children: [_buildLoginTab(), _buildSignUpTab()]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
