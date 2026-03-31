import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String? _codice;
  int _amiciInvitati = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) {
      setState(() {
        _codice = _generateCode(uid ?? 'GUEST');
        _loading = false;
      });
      return;
    }

    try {
      // Timeout di 5 secondi per Firestore
      final doc = await FirebaseFirestore.instance
          .collection('utenti')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));

      String? codice = doc.exists
          ? (doc.data()?['referral_code'] as String?)
          : null;

      // Genera codice locale se mancante
      if (codice == null || codice.isEmpty) {
        codice = _generateCode(uid);
        // Salva in background, senza bloccare UI
        FirebaseFirestore.instance
            .collection('utenti')
            .doc(uid)
            .set({'referral_code': codice}, SetOptions(merge: true))
            .catchError((_) {});
      }

      // Conta invitati (con timeout, non bloccante)
      int count = 0;
      try {
        final snap = await FirebaseFirestore.instance
            .collection('utenti')
            .where('referral_da', isEqualTo: codice)
            .count()
            .get()
            .timeout(const Duration(seconds: 5));
        count = snap.count ?? 0;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _codice = codice;
          _amiciInvitati = count;
          _loading = false;
        });
      }
    } catch (_) {
      // Qualsiasi errore/timeout → usa codice locale
      if (mounted) {
        setState(() {
          _codice = _generateCode(uid);
          _amiciInvitati = 0;
          _loading = false;
        });
      }
    }
  }

  /// Genera codice da uid — formato RISE-XXXXXX
  String _generateCode(String uid) {
    final clean = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final base = clean.length >= 6 ? clean.substring(0, 6) : clean;
    if (base.length >= 4) return 'RISE-$base';
    // Fallback con numero casuale se uid è troppo corto
    final rnd = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'RISE-$rnd';
  }

  void _condividi() {
    if (_codice == null) return;
    Share.share(
      'Unisciti a RISE — la piattaforma competitiva per artisti indipendenti! '
      'Usa il mio codice $_codice per ottenere 3 voti bonus al primo accesso. '
      'Scarica l\'app: https://apps.apple.com/app/id6761341266',
    );
  }

  void _copia() {
    if (_codice == null) return;
    Clipboard.setData(ClipboardData(text: _codice!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Codice copiato!'),
        backgroundColor: AppColors.rankUp,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'INVITA AMICI',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Hero
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        'Invita i tuoi amici su RISE',
                        style: GoogleFonts.oswald(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu guadagni 2 voti extra per ogni amico che si registra. '
                        'Il tuo amico riceve 3 voti bonus al primo accesso.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // Il tuo codice
                Text(
                  'IL TUO CODICE',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _codice ?? '—',
                        style: GoogleFonts.robotoMono(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                      IconButton(
                        onPressed: _copia,
                        icon: const Icon(Icons.copy,
                            color: AppColors.textSecondary),
                        tooltip: 'Copia',
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // Pulsante condividi
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _condividi,
                    icon: const Icon(Icons.share),
                    label: const Text('CONDIVIDI IL TUO CODICE'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // Stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          value: '$_amiciInvitati',
                          label: 'Amici invitati',
                          icon: Icons.people_outlined,
                        ),
                      ),
                      const VerticalDivider(
                          color: Color(0xFF3A3A3A), width: 1),
                      Expanded(
                        child: _StatItem(
                          value: '${_amiciInvitati * 2}',
                          label: 'Voti guadagnati',
                          icon: Icons.how_to_vote_outlined,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // Come funziona
                Text(
                  'COME FUNZIONA',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _StepItem(
                  number: '1',
                  text: 'Condividi il tuo codice con i tuoi amici.',
                ),
                _StepItem(
                  number: '2',
                  text:
                      'Il tuo amico si registra su RISE e inserisce il tuo codice.',
                ),
                _StepItem(
                  number: '3',
                  text:
                      'Entrambi ricevete voti bonus automaticamente!',
                ),
              ],
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.oswald(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
