import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../main/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_usernameController.text.isNotEmpty && _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      if (_passwordController.text == _confirmPasswordController.text) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.register(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phone: '', // Phone is not in the form, sending empty or modify later
        );

        if (mounted) {
          if (success) {
            // Show welcome dialog with 500 coins reward
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.surfaceCharcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Welcome to UFL!', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, size: 64, color: AppTheme.goldAccent),
                    const SizedBox(height: 16),
                    const Text('You received your welcome bonus:', style: TextStyle(color: AppTheme.textWhite)),
                    const SizedBox(height: 8),
                    const Text('500 COINS', style: TextStyle(color: AppTheme.goldAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('START PLAYING'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Registration failed'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppTheme.errorRed),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              'UFL',
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
                height: 1.1,
              ),
            ),
            Text(
              'SPORTS GAMING',
              style: GoogleFonts.inter(
                fontSize: 6,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(color: AppTheme.textWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 14),
            filled: true,
            fillColor: AppTheme.backgroundBlack, // Using darker color for the field inside the dark gray box
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted, size: 20),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and Title
              Center(
                child: Column(
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 16),
                    Text(
                      'JOIN THE LEAGUE',
                      style: GoogleFonts.oswald(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your profile to start competing in global\ntournaments.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildInputField(
                      label: 'Username',
                      hint: 'GamerTag99',
                      icon: Icons.person_outline,
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Email',
                      hint: 'player@domain.com',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Password',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Confirm Password',
                      hint: '••••••••',
                      icon: Icons.restore,
                      controller: _confirmPasswordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),
                    
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: AppTheme.backgroundBlack,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.backgroundBlack,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'CREATE ACCOUNT',
                                      style: GoogleFonts.oswald(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Welcome Bonus Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.monetization_on, color: AppTheme.goldAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Bonus!',
                            style: GoogleFonts.inter(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                              children: [
                                const TextSpan(text: 'Join now and get '),
                                TextSpan(
                                  text: '500 Coins',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.goldAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: ' instantly.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Login here',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
