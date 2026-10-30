import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_reset_service.dart';
import '../services/user_profile_service.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Arogya",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Welcome back to your journey.",
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Email
              _inputField(
                hint: "Email",
                controller: emailController,
              ),

              const SizedBox(height: 16),

              // Password
              _inputField(
                hint: "Password",
                controller: passwordController,
                isPassword: true,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),

              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter your email first")),
                      );
                      return;
                    }
                    try {
                      await authService.resetPassword(email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Password reset email sent!")),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Login Button
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
                      await authService.login(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );

                      // Reset all local data after a successful login to ensure no leakage from previous user
                      if (context.mounted) {
                        await DataResetService.resetAllData(context);
                      }

                      // RESTORE: Pull the existing profile from Firestore if it exists
                      final profile = await UserProfileService()
                          .fetchProfileFromFirestore();

                      // Navigate based on profile existence
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => profile != null
                                ? const DashboardScreen()
                                : const ProfileSetupScreen(),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        String errorMessage = "An error occurred. Please try again.";
                        
                        if (e is FirebaseAuthException) {
                          switch (e.code) {
                            case 'user-not-found':
                              errorMessage = "No user found with this email.";
                              break;
                            case 'wrong-password':
                              errorMessage = "Wrong password provided.";
                              break;
                            case 'invalid-email':
                              errorMessage = "The email address is badly formatted.";
                              break;
                            case 'user-disabled':
                              errorMessage = "This user has been disabled.";
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
                    "Login",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Register Navigation
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text("Create new account"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable input field
  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.textSecondary,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
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
