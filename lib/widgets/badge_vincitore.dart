import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../models/premio.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class BadgeVincitore extends StatelessWidget {
  final TipoBadge tipo;
  final bool animato;
  final double size;

  const BadgeVincitore({
    super.key,
    required this.tipo,
    this.animato = true,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.3),
            AppColors.gold.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tipo.emoji,
            style: TextStyle(fontSize: size * 0.35),
          ),
          Text(
            tipo.label,
            style: GoogleFonts.inter(
              fontSize: size * 0.12,
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (animato) {
      badge = Shimmer.fromColors(
        baseColor: AppColors.gold.withValues(alpha: 0.8),
        highlightColor: Colors.white,
        period: const Duration(seconds: 2),
        child: badge,
      );
    }

    return badge
        .animate()
        .scale(duration: 400.ms, curve: Curves.elasticOut);
  }
}

class BadgeList extends StatelessWidget {
  final List<String> badges;

  const BadgeList({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Text(
        'Nessun badge ancora — partecipa a una gara!',
        style: AppTextStyles.bodySmall(context),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: badges.map((b) {
        final tipo = TipoBadge.values.firstWhere(
          (t) => t.name == b,
          orElse: () => TipoBadge.primaGara,
        );
        return BadgeVincitore(tipo: tipo, size: 56, animato: false);
      }).toList(),
    );
  }
}
