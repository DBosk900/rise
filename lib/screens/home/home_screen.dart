import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gara_provider.dart';
import '../../models/gara.dart';
import '../../providers/voti_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/countdown_timer.dart';
import '../../widgets/montepremi_counter.dart';
import '../../widgets/brano_card.dart';
import '../../widgets/admob_banner.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final _interstitial = AdmobInterstitialHelper();

  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen: initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GaraProvider>().caricaGaraAttiva();
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) {
        context.read<VotiProvider>().ascoltaStato(uid);
      }
      _interstitial.load();
    });
  }

  @override
  void dispose() {
    _interstitial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gara = context.watch<GaraProvider>();
    final voti = context.watch<VotiProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: _navIndex == 0
          ? _buildHome(context, gara, voti, auth)
          : _navIndex == 1
              ? _buildGare(context)
              : _navIndex == 2
                  ? _buildClassifica(context)
                  : _buildProfilo(context, auth),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildHome(context, gara, voti, auth) {
    return CustomScrollView(
      slivers: [
        // App bar con logo e voti rimasti
        SliverAppBar(
          backgroundColor: AppColors.backgroundDark,
          floating: true,
          title: ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
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
          actions: [
            if (auth.isAuthenticated) ...[
              _VotiIndicator(
                votiRimasti: voti.stato?.votiGratuiRimasti ?? 0,
                onTap: () => context.go('/voti/acquisto'),
              ),
              const SizedBox(width: 8),
            ],
            if (auth.isArtista)
              IconButton(
                icon: const Icon(Icons.dashboard_outlined, color: Colors.white),
                onPressed: () => context.go('/artista/dashboard'),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: AppColors.textSecondary),
              onPressed: () {},
            ),
          ],
        ),

        if (gara.loading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (gara.garaAttiva == null)
          SliverFillRemaining(
            child: _NoGaraPlaceholder(),
          )
        else ...[
          // Banner gara del mese
          SliverToBoxAdapter(
            child: _GaraBanner(gara: gara, voti: voti)
                .animate()
                .fadeIn(duration: 500.ms),
          ),

          // Top 3 brani
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.primaryGradient.createShader(b),
                    child: Text(
                      'TOP 3 QUESTA SETTIMANA',
                      style: GoogleFonts.oswald(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final brano = gara.top3[i];
                return BranoCard(
                  brano: brano,
                  posizione: i + 1,
                  haVotiDisponibili: voti.stato?.haVoti ?? false,
                  onTap: () => context.go('/brano/${brano.id}'),
                  onVota: () => _vota(ctx, brano.id,
                      gara.garaAttiva!.id, voti, auth),
                ).animate().fadeIn(
                      delay: Duration(milliseconds: 100 * i),
                      duration: 400.ms,
                    );
              },
              childCount: gara.top3.length,
            ),
          ),

          // Vota per genere
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VOTA ADESSO',
                    style: GoogleFonts.oswald(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.go('/gara/${gara.garaAttiva!.id}'),
                    child: Text('Vedi tutti →',
                        style: GoogleFonts.inter(
                            color: AppColors.primary, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final brano = gara.brani.length > i ? gara.brani[i] : null;
                if (brano == null) return null;
                return BranoCard(
                  brano: brano,
                  posizione: gara.brani.indexOf(brano) + 1,
                  haVotiDisponibili: voti.stato?.haVoti ?? false,
                  onTap: () => ctx.go('/brano/${brano.id}'),
                  onVota: () => _vota(ctx, brano.id,
                      gara.garaAttiva!.id, voti, auth),
                );
              },
              childCount: gara.brani.length.clamp(0, 10),
            ),
          ),

          // AdMob banner
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: AdmobBanner()),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ],
    );
  }

  Future<void> _vota(BuildContext ctx, String branoId, String garaId,
      VotiProvider voti, AuthProvider auth) async {
    if (auth.user == null) {
      ctx.go('/auth/login');
      return;
    }
    final result = await voti.vota(
      userId: auth.user!.uid,
      branoId: branoId,
      garaId: garaId,
    );

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Errore nel voto'),
          backgroundColor: AppColors.primary,
        ),
      );
    }

    if (voti.deveMonstrareInterstitial) {
      _interstitial.showIfReady();
      voti.resetVotiConsecutivi();
      _interstitial.load();
    }
  }

  Widget _buildGare(BuildContext context) {
    final gara = context.watch<GaraProvider>();
    if (gara.garaAttiva == null) return const Center(
      child: Text('Nessuna gara attiva', style: TextStyle(color: AppColors.textSecondary)),
    );
    return Center(
      child: ElevatedButton(
        onPressed: () => context.go('/gara/${gara.garaAttiva!.id}'),
        child: const Text('Vedi gara attiva'),
      ),
    );
  }

  Widget _buildClassifica(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/classifica');
    });
    return const SizedBox.shrink();
  }

  Widget _buildProfilo(BuildContext context, AuthProvider auth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(auth.user?.displayName ?? 'Profilo',
              style: AppTextStyles.headline3(context)),
          const SizedBox(height: 24),
          if (auth.isArtista)
            ElevatedButton(
              onPressed: () => context.go('/artista/dashboard'),
              child: const Text('Dashboard Artista'),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await auth.signOut();
              if (mounted) context.go('/auth/login');
            },
            child: const Text('Esci',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) {
        if (i == 2) {
          context.go('/classifica');
          return;
        }
        setState(() => _navIndex = i);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events_outlined),
          activeIcon: Icon(Icons.emoji_events),
          label: 'Gare',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Classifica',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profilo',
        ),
      ],
    );
  }
}

class _VotiIndicator extends StatelessWidget {
  final int votiRimasti;
  final VoidCallback onTap;

  const _VotiIndicator({required this.votiRimasti, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.how_to_vote, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              '$votiRimasti/5',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaraBanner extends StatelessWidget {
  final GaraProvider gara;
  final VotiProvider voti;

  const _GaraBanner({required this.gara, required this.voti});

  @override
  Widget build(BuildContext context) {
    final g = gara.garaAttiva!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A0A), Color(0xFF1E1205)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GARA DEL MESE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    g.tema.toUpperCase(),
                    style: GoogleFonts.oswald(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      g.stato.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              MontepremiCounter(importo: g.montepremitotale),
            ],
          ),
          const SizedBox(height: 20),
          CountdownTimer(targetDate: g.dataFine, label: 'Fine gara tra'),
        ],
      ),
    );
  }
}

class _NoGaraPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎤', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'Nessuna gara attiva',
            style: AppTextStyles.headline3(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Le gare aprono ogni mese.\nTorna presto!',
            style: AppTextStyles.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
