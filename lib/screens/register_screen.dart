import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_reset_service.dart';
import 'profile_setup_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final AuthService authService = AuthService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Create account ✨",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Start your fitness journey today",
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Email field
            _inputField(
              hint: "Email",
              controller: emailController,
            ),

            const SizedBox(height: 16),

            // Password field
            _inputField(
              hint: "Password",
              controller: passwordController,
              isPassword: true,
            ),

            const SizedBox(height: 24),

            // Create Account Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  try {
                    // 1️⃣ Register user in Firebase
                    await authService.register(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    );

                    // Clear any lingering local data from previous users on this device
                    if (context.mounted) {
                      await DataResetService.resetAllData(context);
                    }

                    // 2️⃣ Navigate to Profile Setup
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileSetupScreen(),
                      ),
                    );
                  } catch (e) {
                    if (context.mounted) {
                      String errorMessage = "Registration failed. Please try again.";

                      if (e is FirebaseAuthException) {
                        switch (e.code) {
                          case 'email-already-in-use':
                            errorMessage = "This email is already in use.";
                            break;
                          case 'weak-password':
                            errorMessage = "The password provided is too weak.";
                            break;
                          case 'invalid-email':
                            errorMessage = "The email address is badly formatted.";
                            break;
                          default:
                            errorMessage = e.message ?? errorMessage;
                        }
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable input field
  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
