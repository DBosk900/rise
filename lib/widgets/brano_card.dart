import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/brano.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vota_button.dart';

class BranoCard extends StatelessWidget {
  final Brano brano;
  final int posizione;
  final VoidCallback? onVota;
  final VoidCallback? onTap;
  final bool haVotiDisponibili;
  final bool votaLoading;

  const BranoCard({
    super.key,
    required this.brano,
    required this.posizione,
    this.onVota,
    this.onTap,
    this.haVotiDisponibili = true,
    this.votaLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: posizione <= 3
              ? Border.all(
                  color: _rankBorderColor(posizione).withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            // Posizione
            SizedBox(
              width: 50,
              child: Center(
                child: posizione <= 3
                    ? _TopBadge(posizione: posizione)
                    : Text(
                        '$posizione',
                        style: AppTextStyles.rankNumber(context),
                      ),
              ),
            ),

            // Cover art
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                bottomLeft: Radius.circular(0),
              ),
              child: CachedNetworkImage(
                imageUrl: brano.urlCover,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: const Color(0xFF2A2A2A),
                  highlightColor: const Color(0xFF3A3A3A),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFF2A2A2A),
                  child: const Icon(Icons.music_note, color: AppColors.textDim),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brano.titolo,
                      style: AppTextStyles.labelBold(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      brano.artistaNome,
                      style: AppTextStyles.bodyMedium(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.how_to_vote,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${brano.votiTotali} voti',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RankVariation(variazione: brano.variazioneRank),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Vota
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: VotaButton(
                onTap: onVota,
                compact: true,
                haVotiDisponibili: haVotiDisponibili,
                loading: votaLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rankBorderColor(int pos) {
    if (pos == 1) return AppColors.gold;
    if (pos == 2) return const Color(0xFFC0C0C0);
    return const Color(0xFFCD7F32);
  }
}

class _TopBadge extends StatelessWidget {
  final int posizione;
  const _TopBadge({required this.posizione});

  @override
  Widget build(BuildContext context) {
    final colors = {
      1: AppColors.gold,
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };
    final emoji = {1: '🥇', 2: '🥈', 3: '🥉'};
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji[posizione]!, style: const TextStyle(fontSize: 18)),
        Text(
          '#$posizione',
          style: GoogleFonts.oswald(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors[posizione],
          ),
        ),
      ],
    );
  }
}

class _RankVariation extends StatelessWidget {
  final int variazione;
  const _RankVariation({required this.variazione});

  @override
  Widget build(BuildContext context) {
    if (variazione == 0) {
      return const Icon(Icons.remove, size: 12, color: AppColors.rankStable);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          variazione > 0 ? Icons.arrow_upward : Icons.arrow_downward,
          size: 12,
          color: variazione > 0 ? AppColors.rankUp : AppColors.rankDown,
        ),
        Text(
          variazione.abs().toString(),
          style: GoogleFonts.inter(
            fontSize: 11,
            color: variazione > 0 ? AppColors.rankUp : AppColors.rankDown,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
