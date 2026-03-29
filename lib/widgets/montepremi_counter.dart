import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class MontepremiCounter extends StatefulWidget {
  final double importo;
  final bool animate;

  const MontepremiCounter({
    super.key,
    required this.importo,
    this.animate = true,
  });

  @override
  State<MontepremiCounter> createState() => _MontepremiCounterState();
}

class _MontepremiCounterState extends State<MontepremiCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _displayedValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    if (widget.animate) {
      _animation.addListener(() {
        setState(() {
          _displayedValue = _animation.value * widget.importo;
        });
      });
      _controller.forward();
    } else {
      _displayedValue = widget.importo;
    }
  }

  @override
  void didUpdateWidget(MontepremiCounter old) {
    super.didUpdateWidget(old);
    if (old.importo != widget.importo && widget.animate) {
      final start = old.importo;
      _animation.addListener(() {
        setState(() {
          _displayedValue = start + (_animation.value * (widget.importo - start));
        });
      });
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MONTEPREMI',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: Text(
            '€ ${_displayedValue.toStringAsFixed(2)}',
            style: GoogleFonts.oswald(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
              duration: 2.seconds,
              color: AppColors.gold.withValues(alpha: 0.3),
            ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '70% delle iscrizioni',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
