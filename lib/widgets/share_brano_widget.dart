import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/brano.dart';
import '../theme/app_theme.dart';

/// Genera e condivide una share card 1080×1080 con il frame RISE.
/// Usa RepaintBoundary per catturare il widget come immagine PNG.
Future<void> shareBranoCard(BuildContext context, Brano brano) async {
  // Mostra un bottom sheet con la card in anteprima + bottone condividi
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.backgroundDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ShareCardSheet(brano: brano),
  );
}

class _ShareCardSheet extends StatefulWidget {
  final Brano brano;
  const _ShareCardSheet({required this.brano});

  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet> {
  final _repaintKey = GlobalKey();
  bool _sharing = false;

  Future<void> _condividi() async {
    setState(() => _sharing = true);
    try {
      // Cattura il widget come immagine
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      // Salva in temp
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/rise_share_${widget.brano.id.substring(0, 8)}.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text:
            '🎵 Vota "${widget.brano.titolo}" di ${widget.brano.artistaNome} su RISE!\n'
            '#RISE #musicaindipendente #musicaitaliana',
      );
    } catch (e) {
      debugPrint('shareBranoCard error: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CONDIVIDI BRANO',
              style: GoogleFonts.oswald(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),

            // Anteprima card
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _ShareCard(brano: widget.brano),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : _condividi,
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.share),
                label: Text(_sharing ? 'Generando...' : 'CONDIVIDI'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La card 1:1 da condividere — disegnata interamente con Flutter widgets.
class _ShareCard extends StatelessWidget {
  final Brano brano;
  const _ShareCard({required this.brano});

  String get _medal {
    switch (brano.posizioneAttuale) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#${brano.posizioneAttuale}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D0D), Color(0xFF1A0505), Color(0xFF0D0D0D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Gradiente rosso in basso
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primary.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Logo RISE in alto a sinistra
          Positioned(
            top: 16,
            left: 16,
            child: ShaderMask(
              shaderCallback: (b) =>
                  AppColors.primaryGradient.createShader(b),
              child: Text(
                'RISE',
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
            ),
          ),

          // Posizione in alto a destra
          Positioned(
            top: 12,
            right: 16,
            child: Text(
              _medal,
              style: const TextStyle(fontSize: 28),
            ),
          ),

          // Cover art al centro
          Center(
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: brano.urlCover,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.cardDark,
                    child: const Icon(Icons.music_note,
                        color: AppColors.textDim, size: 40),
                  ),
                ),
              ),
            ),
          ),

          // Nome artista + titolo in basso
          Positioned(
            bottom: 36,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Text(
                  brano.titolo,
                  style: GoogleFonts.oswald(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  brano.artistaNome,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // CTA in basso
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Text(
              'Vota su RISE 🔥',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
