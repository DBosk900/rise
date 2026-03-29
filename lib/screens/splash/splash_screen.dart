import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (auth.isAuthenticated) {
      context.go('/home');
    } else if (!onboardingDone) {
      context.go('/onboarding');
    } else {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo RISE
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Text(
                'RISE',
                style: GoogleFonts.oswald(
                  fontSize: 80,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 12,
                ),
              ),
            )
                .animate()
                .slideY(
                  begin: 0.5,
                  end: 0,
                  duration: 800.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(duration: 600.ms),

            const SizedBox(height: 16),

            Text(
              'LA COMPETIZIONE MUSICALE',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                letterSpacing: 4,
                fontWeight: FontWeight.w400,
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 600.ms),

            const SizedBox(height: 60),

            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
                .animate(delay: 800.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
