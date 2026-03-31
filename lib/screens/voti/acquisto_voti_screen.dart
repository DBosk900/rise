import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/voti_provider.dart';
import '../../services/pagamento_service.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AcquistoVotiScreen extends StatefulWidget {
  const AcquistoVotiScreen({super.key});

  @override
  State<AcquistoVotiScreen> createState() => _AcquistoVotiScreenState();
}

class _AcquistoVotiScreenState extends State<AcquistoVotiScreen> {
  bool _acquistando = false;
  final _pagamento = PagamentoService();

  Future<void> _acquista() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    setState(() => _acquistando = true);
    await _pagamento.initialize();
    final (ok, errore) = await _pagamento.acquistaVotiExtra5();

    if (mounted) {
      setState(() => _acquistando = false);
      if (!ok && errore != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errore), backgroundColor: AppColors.primary),
        );
      }
      if (ok) {
        // Aggiorna Firestore
        final voti = context.read<VotiProvider>();
        await _aggiungiVotiExtra(auth.user!.uid);
        await voti.caricaStato(auth.user!.uid);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 5 voti aggiunti al tuo account!'),
            backgroundColor: AppColors.rankUp,
          ),
        );
      }
    }
  }

  Future<void> _aggiungiVotiExtra(String uid) async {
    // Chiama VotoService per aggiornare Firestore
    final voto = context.read<VotiProvider>();
    // Il provider aggiorna lo stato in automatico dopo l'acquisto RevenueCat
    await voto.caricaStato(uid);
  }

  @override
  Widget build(BuildContext context) {
    final voti = context.watch<VotiProvider>();
    final stato = voti.stato;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Voti Extra'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Stato voti attuali
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'VOTI DISPONIBILI',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        letterSpacing: 3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stato?.totaleDisponibili ?? 0}',
                    style: GoogleFonts.oswald(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _VotiChip(
                        label: '${stato?.votiGratuiRimasti ?? 0} gratuiti',
                        color: AppColors.rankUp,
                      ),
                      const SizedBox(width: 8),
                      _VotiChip(
                        label: '${stato?.votiExtraDisponibili ?? 0} extra',
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reset ogni lunedì a mezzanotte',
                    style: AppTextStyles.bodySmall(context),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            Text(
              'ACQUISTA VOTI EXTRA',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  letterSpacing: 3),
            ),
            const SizedBox(height: 16),

            // Pacchetto voti
            _PackageCard(
              voti: 5,
              prezzo: '0,99€',
              note: 'I voti extra non scadono mai',
              onAcquista: _acquistando ? null : _acquista,
              loading: _acquistando,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 24),

            // Regole
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COME FUNZIONANO I VOTI',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        letterSpacing: 3),
                  ),
                  const SizedBox(height: 12),
                  _Rule(
                      icon: '🗓️',
                      text: '5 voti gratuiti ogni settimana (reset lunedì)'),
                  _Rule(
                      icon: '💪',
                      text: 'Voti extra: 0,99€ per 5 voti, non scadono'),
                  _Rule(
                      icon: '🛡️',
                      text:
                          'Max 1 voto per brano per settimana (anti-bot)'),
                  _Rule(
                      icon: '🔥',
                      text:
                          'Vota più brani! I voti gratuiti si usano prima'),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _VotiChip extends StatelessWidget {
  final String label;
  final Color color;
  const _VotiChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final int voti;
  final String prezzo;
  final String note;
  final VoidCallback? onAcquista;
  final bool loading;

  const _PackageCard({
    required this.voti,
    required this.prezzo,
    required this.note,
    this.onAcquista,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A0A), Color(0xFF1E1205)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$voti VOTI EXTRA',
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Text(note, style: AppTextStyles.bodySmall(context)),
              ],
            ),
          ),
          loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                )
              : GestureDetector(
                  onTap: onAcquista,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      prezzo,
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

class _Rule extends StatelessWidget {
  final String icon;
  final String text;
  const _Rule({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTextStyles.bodyMedium(context)),
          ),
        ],
      ),
    );
  }
}
