import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime targetDate;
  final String label;
  final bool large;

  const CountdownTimer({
    super.key,
    required this.targetDate,
    this.label = 'Scade tra',
    this.large = false,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.targetDate.isAfter(now)
          ? widget.targetDate.difference(now)
          : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: widget.large ? 13 : 11,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Digit(value: days, unit: 'GG', large: widget.large),
            _Separator(large: widget.large),
            _Digit(value: hours, unit: 'HH', large: widget.large),
            _Separator(large: widget.large),
            _Digit(value: minutes, unit: 'MM', large: widget.large),
            _Separator(large: widget.large),
            _Digit(value: seconds, unit: 'SS', large: widget.large),
          ],
        ),
      ],
    );
  }
}

class _Digit extends StatelessWidget {
  final int value;
  final String unit;
  final bool large;

  const _Digit({required this.value, required this.unit, required this.large});

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 40.0 : 24.0;
    final unitSize = large ? 10.0 : 8.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 12 : 8,
            vertical: large ? 8 : 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.oswald(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: GoogleFonts.inter(
            fontSize: unitSize,
            color: AppColors.textDim,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  final bool large;
  const _Separator({required this.large});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      child: Text(
        ':',
        style: GoogleFonts.oswald(
          fontSize: large ? 36 : 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
