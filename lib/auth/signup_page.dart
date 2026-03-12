import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailSent = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_emailController.text.isEmpty || _nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      await userCredential.user!.sendEmailVerification();
      setState(() => _isEmailSent = true);
      _timer = Timer.periodic(
        const Duration(seconds: 3),
        (timer) => _checkEmailVerified(),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    if (user != null && user.emailVerified) {
      _timer?.cancel();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'email': user.email,
        'status': 'GRINDING',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              if (!_isEmailSent) ...[
                Text(
                  "Join GrindChat",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField("Full Name", "Name", _nameController),
                const SizedBox(height: 15),
                _buildTextField("Email", "Email", _emailController),
                const SizedBox(height: 15),
                _buildTextField(
                  "Password",
                  "Password",
                  _passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _isLoading ? null : _handleSignup,
                  child: _buildGradientButton("Sign Up"),
                ),
              ] else ...[
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: Color(0xFF8E2DE2),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Verify Your Email",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Check your inbox and click the link to continue.",
                    textAlign: TextAlign.center,
                  ),
                ),
                const CircularProgressIndicator(color: Color(0xFF8E2DE2)),
              ],
            ],
          ),
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
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFF161616),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
