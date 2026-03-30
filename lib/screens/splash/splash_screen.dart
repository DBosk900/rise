import 'package:flutter/material.dart';
import '../onboarding/onboarding_screen.dart';
import '../../theme/app_theme.dart';

// Splash ultra-semplice: nessuna animazione, nessun provider, nessun go_router.
// Scopo: verificare che il widget tree si carichi su iPhone reale.
// Dopo 2 secondi naviga verso OnboardingScreen con Navigator.pushReplacement.
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
    debugPrint('SplashScreen: waiting 2s...');
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('SplashScreen: navigating to onboarding');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SplashScreen: build');
    return const Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Text(
          'RISE',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 12,
          ),
        ),
      ),
    );
  }
}
