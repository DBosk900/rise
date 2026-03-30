import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../info/come_funziona_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _SlideData(
      emoji: '🎤',
      title: 'Carica il tuo\nbrano inedito',
      subtitle:
          'Iscriviti con 5,99€/mese e partecipa alle gare mensili con il tuo brano inedito.',
      detail: '2€ per iscrizione a gara',
    ),
    _SlideData(
      emoji: '🏆',
      title: 'Il pubblico vota —\nil migliore vince',
      subtitle:
          'Gli ascoltatori votano con 5 voti gratuiti a settimana. Il brano più votato conquista il podio.',
      detail: 'Voti extra a 0,99€',
    ),
    _SlideData(
      emoji: '💰',
      title: 'Montepremi reale\nogni mese',
      subtitle:
          '70% delle quote di iscrizione forma il montepremi. I vincitori ricevono il pagamento diretto.',
      detail: 'Più artisti = premio più alto',
    ),
  ];

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    debugPrint('OnboardingScreen: initState');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Salta',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _SlidePage(data: _slides[i]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: _page == i ? AppColors.primaryGradient : null,
                    color: _page == i ? null : AppColors.textDim,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: _next,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _page < 2 ? 'AVANTI' : 'INIZIA ADESSO',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Link "Come funziona"
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ComeFunzionaScreen()),
              ),
              child: Text(
                'Come funziona RISE? Scoprilo →',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String emoji;
  final String title;
  final String subtitle;
  final String detail;

  const _SlideData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.detail,
  });
}

class _SlidePage extends StatelessWidget {
  final _SlideData data;

  const _SlidePage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 80))
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 32),

          Text(
            data.title,
            style: GoogleFonts.oswald(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 20),

          Text(
            data.subtitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

          const SizedBox(height: 20),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              data.detail,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
