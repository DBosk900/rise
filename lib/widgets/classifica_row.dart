import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/classifica.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassificaRow extends StatelessWidget {
  final RigaClassifica riga;
  final VoidCallback? onTap;

  const ClassificaRow({super.key, required this.riga, this.onTap});

  @override
  Widget build(BuildContext context) {
    final brano = riga.brano;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${riga.posizione}',
              style: AppTextStyles.rankNumber(context).copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: brano.urlCover,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: AppColors.cardDark,
                child: const Icon(Icons.music_note,
                    size: 20, color: AppColors.textDim),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        brano.titolo,
        style: AppTextStyles.labelBold(context).copyWith(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        brano.artistaNome,
        style: AppTextStyles.bodySmall(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${brano.votiTotali}',
            style: GoogleFonts.oswald(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          _buildVariation(riga.variazioneRank),
        ],
      ),
    );
  }

  Widget _buildVariation(int v) {
    if (v == 0) {
      return const Icon(Icons.remove, size: 14, color: AppColors.rankStable);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          v > 0 ? Icons.arrow_upward : Icons.arrow_downward,
          size: 12,
          color: v > 0 ? AppColors.rankUp : AppColors.rankDown,
        ),
        Text(
          v.abs().toString(),
          style: GoogleFonts.inter(
            fontSize: 11,
            color: v > 0 ? AppColors.rankUp : AppColors.rankDown,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
