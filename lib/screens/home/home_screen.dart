import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../widgets/mini_player.dart';
import '../artista/dashboard_artista_screen.dart';
import '../auth/login_screen.dart';
import '../classifica/classifica_screen.dart';
import '../gare/dettaglio_gara_screen.dart';
import '../gare/schermata_brano_screen.dart';
import '../voti/acquisto_voti_screen.dart';
import '../ricerca/ricerca_screen.dart';
import '../hall_of_fame/hall_of_fame_screen.dart';
import '../impostazioni/impostazioni_screen.dart';
import '../referral/referral_screen.dart';
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
      context.read<GaraProvider>().ascoltaGaraAttiva();
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

  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImpostazioniScreen()),
    );
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
              : _buildProfilo(context, auth), // indice 2 o 3
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          _buildNavBar(),
        ],
      ),
    );
  }

  Widget _buildHome(context, gara, voti, auth) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<GaraProvider>().ascoltaGaraAttiva();
        final uid = context.read<AuthProvider>().user?.uid;
        if (uid != null) context.read<VotiProvider>().ascoltaStato(uid);
      },
      child: CustomScrollView(
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AcquistoVotiScreen()),
                ),
              ),
              const SizedBox(width: 4),
            ],
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RicercaScreen()),
              ),
            ),
            if (auth.isArtista)
              IconButton(
                icon: const Icon(Icons.dashboard_outlined, color: Colors.white),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const DashboardArtistaScreen()),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: AppColors.textSecondary),
              onPressed: _showSettings,
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
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SchermataBranoScreen(branoId: brano.id),
                    ),
                  ),
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
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DettaglioGaraScreen(
                            garaId: gara.garaAttiva!.id),
                      ),
                    ),
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
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SchermataBranoScreen(branoId: brano.id),
                    ),
                  ),
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
      ),
    );
  }

  Future<void> _vota(BuildContext ctx, String branoId, String garaId,
      VotiProvider voti, AuthProvider auth) async {
    if (auth.user == null) {
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (gara.garaAttiva != null)
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DettaglioGaraScreen(garaId: gara.garaAttiva!.id),
              ),
            ),
            icon: const Icon(Icons.emoji_events_outlined),
            label: Text('Gara di ${gara.garaAttiva!.tema} →'),
          )
        else
          Text(
            'Nessuna gara attiva',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HallOfFameScreen()),
          ),
          icon: const Icon(Icons.workspace_premium_outlined,
              color: AppColors.gold),
          label: Text('Hall of Fame',
              style: GoogleFonts.inter(color: AppColors.gold)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.gold),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilo(BuildContext context, AuthProvider auth) {
    if (!auth.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Accedi a RISE',
                style: AppTextStyles.headline3(context)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('ACCEDI'),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        // Avatar + nome
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  (auth.user?.displayName ?? auth.user?.email ?? '?')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: AppTextStyles.headline2(context)
                      .copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                auth.user?.displayName ?? 'Utente',
                style: AppTextStyles.headline3(context),
              ),
              if (auth.user?.email != null)
                Text(auth.user!.email!,
                    style: AppTextStyles.bodyMedium(context)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Actions
        if (auth.isArtista)
          _ProfiloTile(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard Artista',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const DashboardArtistaScreen()),
            ),
          ),
        _ProfiloTile(
          icon: Icons.bar_chart_outlined,
          label: 'Classifica',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ClassificaScreen()),
          ),
        ),
        _ProfiloTile(
          icon: Icons.card_giftcard_outlined,
          label: 'Invita amici',
          subtitle: 'Ottieni voti bonus',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const ReferralScreen()),
          ),
        ),
        _ProfiloTile(
          icon: Icons.settings_outlined,
          label: 'Impostazioni',
          onTap: _showSettings,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () async {
            await auth.signOut();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
          child: const Text('ESCI',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  BottomNavigationBar _buildNavBar() {
    // _navIndex: 0=Home 1=Gare 2=HallOfFame(push) 3=Profilo
    // Hall of Fame si apre come route separata (evita nested Scaffold)
    final displayIndex = _navIndex == 3 ? 3 : _navIndex;
    return BottomNavigationBar(
      currentIndex: displayIndex,
      onTap: (i) {
        if (i == 2) {
          // Hall of Fame → push route separata, non cambia _navIndex
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HallOfFameScreen()),
          );
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
          icon: Icon(Icons.workspace_premium_outlined),
          activeIcon: Icon(Icons.workspace_premium),
          label: 'Hall of Fame',
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

class _ProfiloTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _ProfiloTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(
          label,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: GoogleFonts.inter(
                    color: AppColors.textDim, fontSize: 12))
            : null,
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.textDim),
        onTap: onTap,
      ),
    );
  }
}

