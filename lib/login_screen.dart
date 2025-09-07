import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'modern_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  // Form keys for validation
  final _loginFormKey = GlobalKey<FormState>();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color ?? Colors.red));
  }

  Future<void> _loginUser() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {});

    try {
      final email = _loginEmailController.text.trim();
      final password = _loginPasswordController.text.trim();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _showSnackbar("Login Successful", Colors.green);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      _showSnackbar(errorMessage);
    } catch (e) {
      _showSnackbar("An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _registerUser() async {
    try {
      final email = _registerEmailController.text.trim();
      final password = _registerPasswordController.text.trim();
      final name = _nameController.text.trim();

      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        _showSnackbar("Please fill all fields");
        return;
      }

      if (!_isValidEmail(email)) {
        _showSnackbar("Please enter a valid email address");
        return;
      }

      if (password.length < 6) {
        _showSnackbar("Password must be at least 6 characters long");
        return;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(name);
      _showSnackbar("Registration Successful", Colors.green);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      _showSnackbar(errorMessage);
    } catch (e) {
      _showSnackbar("An unexpected error occurred. Please try again.");
    }
  }

  Future<void> _resetPassword() async {
    final email = _loginEmailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar("Please enter your email to reset password");
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackbar("Password reset email sent. Check your inbox.", Colors.green);
    } on FirebaseAuthException catch (e) {
      _showSnackbar(e.message ?? "Password reset failed");
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);
      _showSnackbar("Google Sign-In Successful", Colors.green);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      _showSnackbar(errorMessage);
    } catch (e) {
      _showSnackbar("Google Sign-In failed. Please try again.");
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ModernHomeScreen()));
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

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

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _loginForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextField(_loginEmailController, "Email"),
          const SizedBox(height: 10),
          _buildTextField(_loginPasswordController, "Password", isPassword: true),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _resetPassword, child: const Text("Forgot Password?")),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loginUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Login"),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("OR", style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _signInWithGoogle,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Colors.grey),
            ),
            icon: Image.network('https://developers.google.com/identity/images/g-logo.png', height: 20, width: 20),
            label: const Text("Continue with Google", style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _registerForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextField(_nameController, "Full Name"),
          const SizedBox(height: 10),
          _buildTextField(_registerEmailController, "Email"),
          const SizedBox(height: 10),
          _buildTextField(_registerPasswordController, "Password", isPassword: true),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _registerUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Sign Up"),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("OR", style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _signInWithGoogle,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Colors.grey),
            ),
            icon: Image.network('https://developers.google.com/identity/images/g-logo.png', height: 20, width: 20),
            label: const Text("Continue with Google", style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              "Welcome to IlmExchange",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              tabs: const [Tab(text: "Login"), Tab(text: "Sign Up")],
            ),
            Expanded(child: TabBarView(controller: _tabController, children: [_loginForm(), _registerForm()])),
          ],
        ),
      ),
    );
  }
}
