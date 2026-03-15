import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED for InputFormatters
import 'package:google_fonts/google_fonts.dart';

import '../main_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State Variables
  bool _isLoading = false;
  bool _isEmailSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Real-time Username Check Variables
  Timer? _debounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;
  String? _passwordError;
  Timer? _authTimer;

  // Reserved Usernames
  final List<String> _reservedUsernames = [
    'admin',
    'support',
    'grindchat',
    'official',
    'moderator',
    'system',
    'owner',
    'root',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _authTimer?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- LOGIC: DEBOUNCED USERNAME CHECK ---
  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    String username = _usernameController.text.trim().toLowerCase();

    if (username.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        _usernameError = "Username too short (min 3)";
        _isUsernameAvailable = false;
      });
      return;
    }

    if (_reservedUsernames.contains(username)) {
      setState(() {
        _usernameError = "This username is reserved";
        _isUsernameAvailable = false;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          if (result.docs.isEmpty) {
            _isUsernameAvailable = true;
            _usernameError = null;
          } else {
            _isUsernameAvailable = false;
            _usernameError = "Username already taken";
          }
        });
      }
    });
  }

  // --- LOGIC: FINAL SIGNUP ---
  Future<void> _handleSignup() async {
    setState(() => _passwordError = null);

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _isUsernameAvailable != true) {
      _showSnackBar("Please complete the form correctly", Colors.redAccent);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _passwordError = "Passwords do not match");
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _passwordError = "Password must be at least 6 characters");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await userCredential.user!.sendEmailVerification();

      setState(() {
        _isEmailSent = true;
        _isLoading = false;
      });

      _authTimer = Timer.periodic(
        const Duration(seconds: 3),
        (timer) => _checkEmailVerified(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.message ?? "An error occurred", Colors.redAccent);
    }
  }

  Future<void> _checkEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    if (user != null && user.emailVerified) {
      _authTimer?.cancel();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'username': _usernameController.text.toLowerCase().trim(),
        'email': user.email,
        'status': 'GRINDING',
        'subtext': 'Stay connected. Stay grinding.',
        'profilePic': '',
        'createdAt': DateTime.now(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                ),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),

            if (!_isEmailSent) ...[
              Text(
                "Join GrindChat",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField("Full Name", "Himanshu", _nameController),
              const SizedBox(height: 15),

              // --- USERNAME FIELD WITH INPUT FILTERING ---
              _buildTextField(
                "Username",
                "unique_username",
                _usernameController,
                errorText: _usernameError,
                // Restriction: lowercase, numbers, dots, and underscores only
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._]')),
                ],
                suffix: _isCheckingUsername
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF8E2DE2),
                        ),
                      )
                    : (_isUsernameAvailable == true
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            )
                          : null),
                isSuccess: _isUsernameAvailable == true,
              ),
              const SizedBox(height: 15),

              _buildTextField("Email", "your@email.com", _emailController),
              const SizedBox(height: 15),

              _buildTextField(
                "Password",
                "Min 6 characters",
                _passwordController,
                isPassword: true,
                obscure: _obscurePassword,
                onToggleVisibility: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 15),

              _buildTextField(
                "Confirm Password",
                "Repeat password",
                _confirmPasswordController,
                isPassword: true,
                obscure: _obscureConfirm,
                errorText: _passwordError,
                onToggleVisibility: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 30),
              GestureDetector(
                onTap: (_isLoading || _isCheckingUsername)
                    ? null
                    : _handleSignup,
                child: _buildGradientButton("Sign Up"),
              ),
              const SizedBox(height: 30),
            ] else ...[
              const SizedBox(height: 50),
              const Icon(
                Icons.mark_email_unread_outlined,
                color: Color(0xFF8E2DE2),
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                "Verify Email",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Check your inbox: ${_emailController.text}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Color(0xFF00D2FF)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton(String title) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF00D2FF)],
        ),
      ),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
    String? errorText,
    Widget? suffix,
    bool isSuccess = false,
    List<TextInputFormatter>? inputFormatters, // NEW Parameter
  }) {
    bool hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          inputFormatters: inputFormatters, // ATTACH FORMATTERS HERE
          obscureText: isPassword ? obscure : false,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[800]),
            filled: true,
            fillColor: const Color(0xFF161616),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.redAccent
                    : (isSuccess
                          ? Colors.green.withOpacity(0.5)
                          : Colors.transparent),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.redAccent
                    : (isSuccess ? Colors.green : const Color(0xFF8E2DE2)),
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : (suffix != null
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: suffix,
                        )
                      : null),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
