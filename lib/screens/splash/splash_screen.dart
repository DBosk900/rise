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
    debugPrint('SplashScreen: initState');
    _navigate();
  }

  Future<void> _navigate() async {
    debugPrint('SplashScreen: waiting for auth...');

    final auth = context.read<AuthProvider>();

    // Attendi che l'auth esca dallo stato loading, con timeout di 5 secondi
    const maxAuthWait = Duration(seconds: 5);
    const tick = Duration(milliseconds: 100);
    var waited = Duration.zero;

    while (auth.isLoading && waited < maxAuthWait) {
      await Future.delayed(tick);
      waited += tick;
      if (!mounted) return;
    }

    debugPrint('SplashScreen: auth resolved after ${waited.inMilliseconds}ms, status=${auth.status}');

    // Garantisce almeno 2 secondi di splash visibile
    final minSplash = const Duration(seconds: 2) - waited;
    if (minSplash > Duration.zero) {
      await Future.delayed(minSplash);
    }

    if (!mounted) return;

    // Hard fallback: se ancora in loading (non dovrebbe mai accadere), vai a onboarding
    if (auth.isLoading) {
      debugPrint('SplashScreen: still loading after timeout — going to onboarding');
      context.go('/onboarding');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (auth.isAuthenticated) {
      debugPrint('SplashScreen: user authenticated — going to home');
      context.go('/home');
    } else if (!onboardingDone) {
      debugPrint('SplashScreen: first launch — going to onboarding');
      context.go('/onboarding');
    } else {
      debugPrint('SplashScreen: not authenticated — going to login');
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SplashScreen: build');
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
