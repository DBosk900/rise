import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/brano.dart';
import '../../models/gara.dart';
import '../../providers/auth_provider.dart';
import '../../providers/voti_provider.dart';
import '../../services/gara_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brano_card.dart';
import '../../widgets/countdown_timer.dart';
import 'package:google_fonts/google_fonts.dart';

class DettaglioGaraScreen extends StatefulWidget {
  final String garaId;

  const DettaglioGaraScreen({super.key, required this.garaId});

  @override
  State<DettaglioGaraScreen> createState() => _DettaglioGaraScreenState();
}

class _DettaglioGaraScreenState extends State<DettaglioGaraScreen>
    with SingleTickerProviderStateMixin {
  final _garaService = GaraService();
  Gara? _gara;
  List<String> _generi = [];
  late TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    final gare = await _garaService.getAllGare();
    final gara = gare.firstWhere(
      (g) => g.id == widget.garaId,
      orElse: () => gare.first,
    );
    final generi = await _garaService.getGeneriDisponibili(widget.garaId);
    final allGeneri = ['Tutti', ...generi];

    setState(() {
      _gara = gara;
      _generi = allGeneri;
      _tabController = TabController(length: allGeneri.length, vsync: this);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _gara == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.backgroundDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
          ),
          if (_generi.length > 1)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: _generi.map((g) => Tab(text: g)).toList(),
                ),
              ),
            ),
        ],
        body: _generi.length <= 1
            ? _BraniList(
                garaId: widget.garaId,
                genere: null,
              )
            : TabBarView(
                controller: _tabController,
                children: _generi.map((g) {
                  return _BraniList(
                    garaId: widget.garaId,
                    genere: g == 'Tutti' ? null : g,
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.secondary.withValues(alpha: 0.6),
            AppColors.backgroundDark,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _gara!.tema.toUpperCase(),
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _PhaseChip(label: _gara!.stato.label),
                  const SizedBox(width: 12),
                  Text(
                    '${_gara!.numeroIscritti} artisti',
                    style: AppTextStyles.bodySmall(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CountdownTimer(targetDate: _gara!.dataFine),
            ],
          ),
        ),
      ),
    );
  }
}

class _BraniList extends StatelessWidget {
  final String garaId;
  final String? genere;

  const _BraniList({required this.garaId, this.genere});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final voti = context.watch<VotiProvider>();
    final garaService = GaraService();

    return StreamBuilder<List<Brano>>(
      stream: garaService.braniPerGaraStream(garaId, genere: genere),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Errore: ${snap.error}',
                  style: const TextStyle(color: AppColors.textSecondary)));
        }
        final brani = snap.data ?? [];
        if (brani.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎵', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Nessun brano in questa categoria',
                    style: AppTextStyles.bodyMedium(context)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: brani.length,
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemBuilder: (ctx, i) {
            return BranoCard(
              brano: brani[i],
              posizione: i + 1,
              haVotiDisponibili: voti.stato?.haVoti ?? false,
              onTap: () => ctx.go('/brano/${brani[i].id}'),
              onVota: auth.user == null
                  ? null
                  : () async {
                      final result = await voti.vota(
                        userId: auth.user!.uid,
                        branoId: brani[i].id,
                        garaId: garaId,
                      );
                      if (!result.success && ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                              content: Text(result.error ?? 'Errore'),
                              backgroundColor: AppColors.primary),
                        );
                      }
                    },
            ).animate().fadeIn(
                  delay: Duration(milliseconds: 60 * i),
                  duration: 300.ms,
                );
          },
        );
      },
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final String label;
  const _PhaseChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(context, _, __) {
    return Container(
      color: AppColors.backgroundDark,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
