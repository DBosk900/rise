import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/vincitore.dart';
import '../../services/hall_of_fame_service.dart';
import '../../theme/app_theme.dart';
import '../gare/schermata_brano_screen.dart';

class HallOfFameScreen extends StatelessWidget {
  const HallOfFameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: Text(
            'HALL OF FAME',
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Vincitore>>(
        stream: HallOfFameService().vincitoriStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final vincitori = snap.data ?? [];

          if (vincitori.isEmpty) {
            return _buildEmpty();
          }

          // Raggruppa per mese/anno
          final Map<String, List<Vincitore>> grouped = {};
          for (final v in vincitori) {
            final key = '${v.anno}-${v.mese.toString().padLeft(2, '0')}';
            grouped.putIfAbsent(key, () => []).add(v);
          }

          final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            itemBuilder: (ctx, i) {
              final key = keys[i];
              final gruppo = grouped[key]!;
              gruppo.sort((a, b) => a.posizione.compareTo(b.posizione));
              final primo = gruppo.first;

              return _MeseCard(
                vincitori: gruppo,
                tema: primo.tema,
                meseAnnoLabel: primo.meseAnnoLabel,
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 80 * i), duration: 400.ms)
                  .slideY(begin: 0.08, end: 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: AppColors.textDim),
          const SizedBox(height: 16),
          Text(
            'Nessun vincitore ancora',
            style: GoogleFonts.oswald(
                color: AppColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'I vincitori appariranno qui\ndopo la prima gara.',
            style: GoogleFonts.inter(
                color: AppColors.textDim, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MeseCard extends StatelessWidget {
  final List<Vincitore> vincitori;
  final String tema;
  final String meseAnnoLabel;

  const _MeseCard({
    required this.vincitori,
    required this.tema,
    required this.meseAnnoLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.gold, size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meseAnnoLabel,
                      style: GoogleFonts.inter(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      tema.toUpperCase(),
                      style: GoogleFonts.oswald(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Vincitori
          ...vincitori.map((v) => _VincitoreRow(vincitore: v)),
        ],
      ),
    );
  }
}

class _VincitoreRow extends StatelessWidget {
  final Vincitore vincitore;

  const _VincitoreRow({required this.vincitore});

  Color get _posColor {
    switch (vincitore.posizione) {
      case 1:
        return AppColors.gold;
      case 2:
        return const Color(0xFFB0BEC5);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textDim;
    }
  }

  String get _medal {
    switch (vincitore.posizione) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '${vincitore.posizione}°';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: vincitore.id.isNotEmpty
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SchermataBranoScreen(branoId: vincitore.id),
                ),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Medal
            SizedBox(
              width: 36,
              child: Text(
                _medal,
                style: const TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: vincitore.urlCover,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.backgroundDark,
                  child: const Icon(Icons.music_note,
                      color: AppColors.textDim),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.backgroundDark,
                  child: const Icon(Icons.music_note,
                      color: AppColors.textDim),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vincitore.titoloCanzone,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    vincitore.artistaNome,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (vincitore.premioVinto > 0)
                  Text(
                    '€${vincitore.premioVinto.toStringAsFixed(0)}',
                    style: GoogleFonts.oswald(
                      color: _posColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                Text(
                  '${vincitore.votiTotali} voti',
                  style: GoogleFonts.inter(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
