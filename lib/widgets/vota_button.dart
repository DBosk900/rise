import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class VotaButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool loading;
  final bool compact;
  final bool haVotiDisponibili;

  const VotaButton({
    super.key,
    this.onTap,
    this.loading = false,
    this.compact = false,
    this.haVotiDisponibili = true,
  });

  @override
  State<VotaButton> createState() => _VotaButtonState();
}

class _VotaButtonState extends State<VotaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null &&
        !widget.loading &&
        widget.haVotiDisponibili;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = enabled
            ? 1.0 + (_pulseController.value * 0.04)
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.compact ? 36 : 50,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 16 : 28,
          ),
          decoration: BoxDecoration(
            gradient: enabled
                ? AppColors.primaryGradient
                : const LinearGradient(
                    colors: [Color(0xFF444444), Color(0xFF555555)],
                  ),
            borderRadius: BorderRadius.circular(widget.compact ? 18 : 25),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(
                  Icons.how_to_vote_rounded,
                  color: Colors.white,
                  size: widget.compact ? 16 : 22,
                ),
              const SizedBox(width: 8),
              Text(
                widget.haVotiDisponibili ? 'VOTA' : 'VOTI ESAURITI',
                style: GoogleFonts.oswald(
                  fontSize: widget.compact ? 13 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
