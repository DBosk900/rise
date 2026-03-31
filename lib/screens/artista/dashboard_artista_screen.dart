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
  bool _abbonamentoAttivo = false;
  bool _acquistandoAbbonamento = false;
  String? _acquistaErrore;
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

    // Verifica abbonamento: prima da artista model, poi da RevenueCat
    bool attivo = auth.artista?.abbonamentoAttivo ?? false;
    if (!attivo) {
      try {
        await _pagamento.initialize();
        attivo = await _pagamento.haAbbonamentoAttivo();
      } catch (_) {}
    }

    Brano? brano;
    if (auth.user != null && gara.garaAttiva != null) {
      brano = gara.brani
          .where((b) => b.artistaId == auth.user!.uid)
          .firstOrNull;
    }

    if (mounted) {
      setState(() {
        _abbonamentoAttivo = attivo;
        _branoAttuale = brano;
        _loading = false;
      });
    }
  }

  Future<void> _acquistaAbbonamento() async {
    setState(() {
      _acquistandoAbbonamento = true;
      _acquistaErrore = null;
    });
    try {
      await _pagamento.initialize();
      final (ok, errore) = await _pagamento.acquistaAbbonamentoArtista();
      if (!mounted) return;
      if (ok) {
        await context.read<AuthProvider>().refreshArtista();
        setState(() => _abbonamentoAttivo = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Abbonamento attivato!'),
              backgroundColor: AppColors.rankUp),
        );
      } else {
        setState(() => _acquistaErrore = errore);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errore ?? 'Acquisto annullato'),
              backgroundColor: AppColors.cardDark),
        );
      }
    } finally {
      if (mounted) setState(() => _acquistandoAbbonamento = false);
    }
  }

  Future<void> _ripristinaAcquisti() async {
    setState(() => _acquistandoAbbonamento = true);
    try {
      await _pagamento.initialize();
      await _pagamento.restoreAcquisti();
      final attivo = await _pagamento.haAbbonamentoAttivo();
      if (!mounted) return;
      setState(() => _abbonamentoAttivo = attivo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attivo
              ? '✅ Abbonamento ripristinato!'
              : 'Nessun acquisto trovato'),
          backgroundColor:
              attivo ? AppColors.rankUp : AppColors.cardDark,
        ),
      );
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
            // ── Stato abbonamento ────────────────────────────────────────
            _AbbonamentiCard(
              artista: artista,
              abbonamentoAttivo: _abbonamentoAttivo,
              onAcquista: _acquistaAbbonamento,
              onRipristina: _ripristinaAcquisti,
              loading: _acquistandoAbbonamento,
              errore: _acquistaErrore,
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            if (_abbonamentoAttivo) ...[
              // ── Brano in gara ──────────────────────────────────────────
              if (_branoAttuale != null)
                _BranoAttualeCard(brano: _branoAttuale!)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),

              if (_branoAttuale == null)
                _NessunBranoCard()
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // ── Statistiche ────────────────────────────────────────────
              if (artista != null)
                _StatsCard(artista: artista)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // ── Badge ──────────────────────────────────────────────────
              if (artista != null)
                _BadgeCard(artista: artista)
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // ── CTA iscrivi brano ──────────────────────────────────────
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
            ] else ...[
              // ── Features bloccate (non abbonato) ──────────────────────
              _LockedFeaturesPreview(
                onAbbonati: _acquistaAbbonamento,
                loading: _acquistandoAbbonamento,
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Componenti ────────────────────────────────────────────────────────────────

class _AbbonamentiCard extends StatelessWidget {
  final Artista? artista;
  final bool abbonamentoAttivo;
  final VoidCallback onAcquista;
  final VoidCallback onRipristina;
  final bool loading;
  final String? errore;

  const _AbbonamentiCard({
    this.artista,
    required this.abbonamentoAttivo,
    required this.onAcquista,
    required this.onRipristina,
    required this.loading,
    this.errore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: abbonamentoAttivo
              ? AppColors.rankUp.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (abbonamentoAttivo
                          ? AppColors.rankUp
                          : AppColors.primary)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  abbonamentoAttivo ? Icons.verified : Icons.lock_outlined,
                  color: abbonamentoAttivo
                      ? AppColors.rankUp
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      abbonamentoAttivo
                          ? 'Piano Pro Artista'
                          : 'Abbonati per partecipare',
                      style: AppTextStyles.labelBold(context),
                    ),
                    Text(
                      abbonamentoAttivo
                          ? 'Scade: ${_fmt(artista?.dataScadenzaAbbonamento)}'
                          : '5,99€/mese — gare illimitate',
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ],
                ),
              ),
              if (!abbonamentoAttivo)
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
          if (!abbonamentoAttivo && !loading) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRipristina,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ripristina acquisti precedenti',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          if (errore != null) ...[
            const SizedBox(height: 8),
            Text(
              errore!,
              style: GoogleFonts.inter(
                  color: AppColors.primary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _LockedFeaturesPreview extends StatelessWidget {
  final VoidCallback onAbbonati;
  final bool loading;

  const _LockedFeaturesPreview({
    required this.onAbbonati,
    required this.loading,
  });

  static const _features = [
    (Icons.upload_outlined, 'Iscrivi brani alle gare mensili'),
    (Icons.bar_chart_outlined, 'Statistiche voti e posizione'),
    (Icons.emoji_events_outlined, 'Storico partecipazioni e premi'),
    (Icons.workspace_premium_outlined, 'Badge e riconoscimenti'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SBLOCCA LA DASHBOARD',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(f.$1,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f.$2,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(Icons.lock_outline,
                      color: AppColors.textDim, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onAbbonati,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'ABBONATI PER SBLOCCARE — 5,99€/mese',
                      style: GoogleFonts.oswald(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NessunBranoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.music_note_outlined,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nessun brano in gara',
                  style: AppTextStyles.labelBold(context),
                ),
                Text(
                  'Iscriviti alla gara del mese',
                  style: AppTextStyles.bodySmall(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                    Text(brano.titolo,
                        style: AppTextStyles.labelBold(context)),
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
              _Stat(
                  label: 'Voti extra',
                  value: '${artista.votiExtraDisponibili}'),
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
