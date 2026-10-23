import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';
import 'signup_view.dart';

/// Title and onboarding welcome landing view for HabitForge.
/// Designed for maximum visual appeal, clean typography, and zero-friction entry for ages 20 to 80+.
class TitleView extends StatelessWidget {
  const TitleView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // 1. App Icon with Ambient Glow
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // 2. Brand Title & Tagline
              Text(
                'HabitForge',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Build positive routines that last a lifetime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              // 3. Feature Highlights Showcase
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFF97316),
                      title: 'Streak & Consistency Tracking',
                      desc: 'Celebrate daily progress and protect your streaks.',
                      isDark: isDark,
                    ),
                    Divider(height: 24, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    _FeatureRow(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF4F46E5),
                      title: 'Personal AI Habit Coach',
                      desc: 'Receive tailored guidance based on your routines.',
                      isDark: isDark,
                    ),
                    Divider(height: 24, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    _FeatureRow(
                      icon: Icons.shield_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: '100% Private On-Device',
                      desc: 'Your habits and notes remain safely on your phone.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 4. Action Buttons
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpView()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: primaryColor.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Log In Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'I Already Have an Account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Continue as Guest Option (zero barrier for seniors or instant testing)
              TextButton(
                onPressed: () async {
                  await context.read<AuthViewModel>().continueAsGuest();
                },
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

