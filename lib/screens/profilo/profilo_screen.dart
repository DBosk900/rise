import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../models/artista.dart';
import '../../models/brano.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badge_vincitore.dart';
import '../../widgets/brano_card.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfiloScreen extends StatefulWidget {
  final String artistaId;
  const ProfiloScreen({super.key, required this.artistaId});

  @override
  State<ProfiloScreen> createState() => _ProfiloScreenState();
}

class _ProfiloScreenState extends State<ProfiloScreen> {
  Artista? _artista;
  List<Brano> _brani = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    final db = FirebaseFirestore.instance;
    final artistaDoc =
        await db.collection('artisti').doc(widget.artistaId).get();
    if (!artistaDoc.exists) {
      setState(() => _loading = false);
      return;
    }
    final artista = Artista.fromFirestore(artistaDoc);

    final braniSnap = await db
        .collection('brani_in_gara')
        .where('artista_id', isEqualTo: widget.artistaId)
        .orderBy('data_iscrizione', descending: true)
        .limit(10)
        .get();
    final brani = braniSnap.docs.map(Brano.fromFirestore).toList();

    setState(() {
      _artista = artista;
      _brani = brani;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_artista == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Text('Artista non trovato',
              style: AppTextStyles.bodyMedium(context)),
        ),
      );
    }

    final a = _artista!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.backgroundDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.6),
                          AppColors.backgroundDark,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 24,
                    right: 24,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.cardDark,
                          backgroundImage: a.fotoProfilo != null
                              ? CachedNetworkImageProvider(a.fotoProfilo!)
                              : null,
                          child: a.fotoProfilo == null
                              ? Text(
                                  a.nome.isNotEmpty
                                      ? a.nome[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.oswald(
                                      fontSize: 28,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.nome,
                                style: AppTextStyles.headline3(context)),
                            Text(
                              '${a.storicoGare.length} gare partecipate',
                              style: AppTextStyles.bodySmall(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (a.bio != null && a.bio!.isNotEmpty) ...[
                    Text(
                      'BIO',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          letterSpacing: 3),
                    ),
                    const SizedBox(height: 8),
                    Text(a.bio!,
                        style: AppTextStyles.bodyMedium(context)),
                    const SizedBox(height: 24),
                  ],

                  if (a.badge.isNotEmpty) ...[
                    Text(
                      'BADGE',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          letterSpacing: 3),
                    ),
                    const SizedBox(height: 12),
                    BadgeList(badges: a.badge),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),

          if (_brani.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'BRANI IN GARA',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      letterSpacing: 3),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => BranoCard(
                  brano: _brani[i],
                  posizione: _brani[i].posizioneAttuale,
                  onTap: () => ctx.go('/brano/${_brani[i].id}'),
                ).animate().fadeIn(
                      delay: Duration(milliseconds: 60 * i),
                      duration: 300.ms,
                    ),
                childCount: _brani.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
