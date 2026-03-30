import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../models/brano.dart';
import '../../widgets/share_brano_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/voti_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admob_banner.dart';
import '../../widgets/vota_button.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/profilo/profilo_screen.dart';
import '../../screens/voti/acquisto_voti_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SchermataBranoScreen extends StatefulWidget {
  final String branoId;

  const SchermataBranoScreen({super.key, required this.branoId});

  @override
  State<SchermataBranoScreen> createState() => _SchermataBranoScreenState();
}

class _SchermataBranoScreenState extends State<SchermataBranoScreen> {
  Brano? _brano;
  bool _loading = true;
  final _player = AudioPlayer();
  bool _playing = false;
  bool _playerReady = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _votaLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBrano();
    _player.positionStream.listen((p) => setState(() => _position = p));
    _player.durationStream.listen((d) {
      if (d != null) setState(() => _duration = d);
    });
    _player.playerStateStream.listen((s) {
      setState(() => _playing = s.playing);
    });
  }

  Future<void> _loadBrano() async {
    final doc = await FirebaseFirestore.instance
        .collection('brani_in_gara')
        .doc(widget.branoId)
        .get();
    if (doc.exists && mounted) {
      final brano = Brano.fromFirestore(doc);
      setState(() {
        _brano = brano;
        _loading = false;
      });
      _initPlayer(brano.urlAudio);
    }
  }

  Future<void> _initPlayer(String url) async {
    if (url.isEmpty) return;
    try {
      await _player.setUrl(url);
      setState(() => _playerReady = true);
    } catch (_) {}
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final brano = _brano!;
    final auth = context.watch<AuthProvider>();
    final voti = context.watch<VotiProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // Cover art full width
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.backgroundDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () => shareBranoCard(context, brano),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: brano.urlCover,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.cardDark,
                      child: const Icon(Icons.music_note,
                          size: 80, color: AppColors.textDim),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.darkOverlay),
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
                  // Titolo e artista
                  Text(
                    brano.titolo,
                    style: AppTextStyles.headline2(context),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 4),

                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfiloScreen(artistaId: brano.artistaId),
                      ),
                    ),
                    child: Text(
                      brano.artistaNome,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Posizione e voti
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.leaderboard,
                        label: '#${brano.posizioneAttuale}',
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.how_to_vote,
                        label: '${brano.votiTotali} voti',
                        color: AppColors.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Player audio
                  if (_playerReady) _buildPlayer(),

                  const SizedBox(height: 32),

                  // Bottone VOTA grande
                  Center(
                    child: VotaButton(
                      haVotiDisponibili: voti.stato?.haVoti ?? false,
                      loading: _votaLoading,
                      onTap: auth.user == null
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              )
                          : () => _vota(auth, voti),
                    ),
                  ).animate().scale(
                        delay: 300.ms,
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      ),

                  if (!(voti.stato?.haVoti ?? true)) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AcquistoVotiScreen()),
                        ),
                        child: Text(
                          'Acquista voti extra →',
                          style: GoogleFonts.inter(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Bio artista
                  Text(
                    'BIO ARTISTA',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    brano.bio.isNotEmpty
                        ? brano.bio
                        : 'Artista indipendente in competizione su RISE.',
                    style: AppTextStyles.bodyMedium(context),
                  ),

                  const SizedBox(height: 32),

                  // AdMob banner
                  const Center(child: AdmobBanner()),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    String fmt(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Barra avanzamento
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.textDim,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (v) {
                _player.seek(
                  Duration(
                      milliseconds:
                          (v * _duration.inMilliseconds).round()),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fmt(_position), style: AppTextStyles.mono(context)),
                Text(fmt(_duration), style: AppTextStyles.mono(context)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10,
                    color: AppColors.textSecondary),
                onPressed: () => _player.seek(
                  Duration(
                      seconds:
                          (_position.inSeconds - 10).clamp(0, double.infinity).toInt()),
                ),
              ),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Icon(
                    _playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.forward_10,
                    color: AppColors.textSecondary),
                onPressed: () => _player.seek(
                  Duration(
                      seconds: (_position.inSeconds + 10)
                          .clamp(0, _duration.inSeconds)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _vota(AuthProvider auth, VotiProvider voti) async {
    if (_brano == null || auth.user == null) return;
    setState(() => _votaLoading = true);
    final result = await voti.vota(
      userId: auth.user!.uid,
      branoId: _brano!.id,
      garaId: _brano!.garaId,
    );
    if (mounted) {
      setState(() => _votaLoading = false);
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.error ?? 'Errore'),
              backgroundColor: AppColors.primary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Voto registrato!'),
            backgroundColor: AppColors.rankUp,
          ),
        );
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
