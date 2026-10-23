import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';

/// Clean, accessible mobile sign up screen for HabitForge.
/// Lets new users create an offline-first profile with name, email, and password.
class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authVm = context.read<AuthViewModel>();
    final nav = Navigator.of(context);

    await authVm.signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      nav.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF10B981);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                const Text(
                  'Create Account 🌿',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Start your journey toward lasting habits with HabitForge.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 28),

                // 2. Full Name Field
                const Text(
                  'Your Name',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Soham',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name.';
                    }
                    if (val.trim().length < 2) {
                      return 'Name must be at least 2 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 3. Email Field
                const Text(
                  'Email Address',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 4. Password Field
                const Text(
                  'Password',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Create a password (min 4 characters)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a password.';
                    }
                    if (val.trim().length < 4) {
                      return 'Password must be at least 4 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 5. Confirm Password Field
                const Text(
                  'Confirm Password',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please confirm your password.';
                    }
                    if (val.trim() != _passwordController.text.trim()) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 6. Privacy Trust Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: Color(0xFF059669)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '100% Private & Stored on Device. No tracking.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // 8. Log In Navigation Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginView()),
                        );
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                      ),
                    ),
                  ],
                ),

                // 9. Continue as Guest
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      await context.read<AuthViewModel>().continueAsGuest();
                      if (mounted) {
                        nav.popUntil((route) => route.isFirst);
                      }
                    },
                    child: const Text(
                      'Or Continue as Guest',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
