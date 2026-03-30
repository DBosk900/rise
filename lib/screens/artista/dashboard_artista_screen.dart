import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/artista.dart';
import '../../models/brano.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gara_provider.dart';
import '../../services/pagamento_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badge_vincitore.dart';
import '../home/home_screen.dart';
import 'upload_brano_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardArtistaScreen extends StatefulWidget {
  const DashboardArtistaScreen({super.key});

  @override
  State<DashboardArtistaScreen> createState() => _DashboardArtistaScreenState();
}

class _DashboardArtistaScreenState extends State<DashboardArtistaScreen> {
  Brano? _branoAttuale;
  bool _loading = true;
  bool _acquistandoAbbonamento = false;
  final _pagamento = PagamentoService();

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    final auth = context.read<AuthProvider>();
    final gara = context.read<GaraProvider>();
    if (gara.garaAttiva == null) await gara.caricaGaraAttiva();

    if (auth.user != null && gara.garaAttiva != null) {
      final branoSnap = _branoArtistaFromProvider(auth.user!.uid, gara);
      setState(() {
        _branoAttuale = branoSnap;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Brano? _branoArtistaFromProvider(String artistaId, GaraProvider gara) {
    return gara.brani
        .where((b) => b.artistaId == artistaId)
        .firstOrNull;
  }

  Future<void> _acquistaAbbonamento() async {
    setState(() => _acquistandoAbbonamento = true);
    try {
      await _pagamento.initialize();
      final ok = await _pagamento.acquistaAbbonamentoArtista();
      if (!mounted) return;
      if (ok) {
        await context.read<AuthProvider>().refreshArtista();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Abbonamento attivato!'),
              backgroundColor: AppColors.rankUp),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Acquisto annullato'),
              backgroundColor: AppColors.cardDark),
        );
      }
    } finally {
      if (mounted) setState(() => _acquistandoAbbonamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final artista = auth.artista;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Dashboard Artista'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stato abbonamento
            _AbbonamentiCard(
              artista: artista,
              onAcquista: _acquistaAbbonamento,
              loading: _acquistandoAbbonamento,
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            if (artista?.abbonamentoAttivo == true) ...[
              // Brano in gara
              if (_branoAttuale != null)
                _BranoAttualeCard(brano: _branoAttuale!)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // Statistiche
              _StatsCard(artista: artista!)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // Badge
              _BadgeCard(artista: artista)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // CTA iscrivi brano
              SizedBox(
                width: double.infinity,
                height: 54,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const UploadBranoScreen()),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.upload_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'ISCRIVI UN NUOVO BRANO',
                          style: GoogleFonts.oswald(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}

class _AbbonamentiCard extends StatelessWidget {
  final Artista? artista;
  final VoidCallback onAcquista;
  final bool loading;

  const _AbbonamentiCard(
      {this.artista, required this.onAcquista, required this.loading});

  @override
  Widget build(BuildContext context) {
    final attivo = artista?.abbonamentoAttivo ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: attivo
              ? AppColors.rankUp.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (attivo ? AppColors.rankUp : AppColors.primary)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              attivo ? Icons.verified : Icons.music_note_outlined,
              color: attivo ? AppColors.rankUp : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attivo ? 'Abbonamento Attivo' : 'Abbonamento Non Attivo',
                  style: AppTextStyles.labelBold(context),
                ),
                Text(
                  attivo
                      ? 'Scade: ${_fmt(artista?.dataScadenzaAbbonamento)}'
                      : '5,99€/mese — sblocca le gare',
                  style: AppTextStyles.bodySmall(context),
                ),
              ],
            ),
          ),
          if (!attivo)
            loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  )
                : GestureDetector(
                    onTap: onAcquista,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ABBONATI',
                        style: GoogleFonts.oswald(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _BranoAttualeCard extends StatelessWidget {
  final Brano brano;
  const _BranoAttualeCard({required this.brano});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BRANO IN GARA',
            style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: brano.urlCover.isNotEmpty
                    ? Image.network(brano.urlCover,
                        width: 56, height: 56, fit: BoxFit.cover)
                    : Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(Icons.music_note,
                            color: AppColors.textDim)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(brano.titolo, style: AppTextStyles.labelBold(context)),
                    Text(brano.faseAttuale.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.primary,
                            letterSpacing: 1)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '#${brano.posizioneAttuale}',
                    style: GoogleFonts.oswald(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold),
                  ),
                  Text('${brano.votiTotali} voti',
                      style: AppTextStyles.bodySmall(context)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final Artista artista;
  const _StatsCard({required this.artista});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LE TUE STATISTICHE',
            style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 3),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'Gare', value: '${artista.storicoGare.length}'),
              _Stat(label: 'Badge', value: '${artista.badge.length}'),
              _Stat(label: 'Voti extra', value: '${artista.votiExtraDisponibili}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.oswald(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.primary),
        ),
        Text(label, style: AppTextStyles.bodySmall(context)),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Artista artista;
  const _BadgeCard({required this.artista});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BADGE CONQUISTATI',
            style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 3),
          ),
          const SizedBox(height: 16),
          BadgeList(badges: artista.badge),
        ],
      ),
    );
  }
}
