import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notifica_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../artista/dashboard_artista_screen.dart';
import '../referral/referral_screen.dart';

class ImpostazioniScreen extends StatefulWidget {
  const ImpostazioniScreen({super.key});

  @override
  State<ImpostazioniScreen> createState() => _ImpostazioniScreenState();
}

class _ImpostazioniScreenState extends State<ImpostazioniScreen> {
  final _notificaService = NotificaService();
  bool _notifVoti = true;
  bool _notifGara = true;
  bool _notifClassifica = true;
  bool _loadingNotif = true;

  @override
  void initState() {
    super.initState();
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final v = await _notificaService.isVotiEnabled();
    final g = await _notificaService.isGaraEnabled();
    final c = await _notificaService.isClassificaEnabled();
    if (mounted) {
      setState(() {
        _notifVoti = v;
        _notifGara = g;
        _notifClassifica = c;
        _loadingNotif = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Esci', style: GoogleFonts.oswald(color: Colors.white)),
        content: Text(
          'Sei sicuro di voler uscire dall\'account?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ESCI',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'IMPOSTAZIONI',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── ACCOUNT ─────────────────────────────────────────────────────
          if (auth.isAuthenticated) ...[
            _SectionHeader(title: 'ACCOUNT'),
            _UserCard(auth: auth),
            if (auth.isArtista)
              _Tile(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard Artista',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const DashboardArtistaScreen()),
                ),
              ),
            _Tile(
              icon: Icons.card_giftcard_outlined,
              label: 'Invita amici',
              subtitle: 'Ottieni voti bonus',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReferralScreen()),
              ),
            ),
            const _Divider(),
          ],

          // ── PREFERENZE ──────────────────────────────────────────────────
          _SectionHeader(title: 'PREFERENZE'),
          _SwitchTile(
            icon: Icons.dark_mode_outlined,
            label: 'Tema scuro',
            value: theme.isDark,
            onChanged: (_) => theme.toggle(),
          ),
          const _Divider(),

          // ── NOTIFICHE ───────────────────────────────────────────────────
          _SectionHeader(title: 'NOTIFICHE'),
          if (_loadingNotif)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else ...[
            _SwitchTile(
              icon: Icons.how_to_vote_outlined,
              label: 'Notifiche voti',
              subtitle: 'Quando ricevi nuovi voti',
              value: _notifVoti,
              onChanged: (val) async {
                await _notificaService.setVotiEnabled(val);
                setState(() => _notifVoti = val);
              },
            ),
            _SwitchTile(
              icon: Icons.emoji_events_outlined,
              label: 'Notifiche gare',
              subtitle: 'Inizio e fine gara mensile',
              value: _notifGara,
              onChanged: (val) async {
                await _notificaService.setGaraEnabled(val);
                setState(() => _notifGara = val);
              },
            ),
            _SwitchTile(
              icon: Icons.bar_chart_outlined,
              label: 'Aggiornamenti classifica',
              subtitle: 'Variazioni di posizione',
              value: _notifClassifica,
              onChanged: (val) async {
                await _notificaService.setClassificaEnabled(val);
                setState(() => _notifClassifica = val);
              },
            ),
          ],
          const _Divider(),

          // ── SUPPORTO ────────────────────────────────────────────────────
          _SectionHeader(title: 'SUPPORTO'),
          _Tile(
            icon: Icons.help_outline,
            label: 'Come funziona RISE',
            onTap: () => _launchUrl('https://rise-app.it/come-funziona'),
          ),
          _Tile(
            icon: Icons.mail_outline,
            label: 'Contattaci',
            onTap: () => _launchUrl('mailto:support@rise-app.it'),
          ),
          _Tile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => _launchUrl('https://rise-app.it/privacy'),
          ),
          _Tile(
            icon: Icons.description_outlined,
            label: 'Termini di servizio',
            onTap: () => _launchUrl('https://rise-app.it/terms'),
          ),
          const _Divider(),

          // ── VERSIONE ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'RISE v1.1.0',
              style: GoogleFonts.inter(
                  color: AppColors.textDim,
                  fontSize: 12,
                  letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 8),

          // ── LOGOUT ──────────────────────────────────────────────────────
          if (auth.isAuthenticated)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'ESCI DALL\'ACCOUNT',
                    style: GoogleFonts.oswald(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

          if (!auth.isAuthenticated)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('ACCEDI'),
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}

// ── Componenti ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.textDim,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.inter(
                  color: AppColors.textDim, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textDim, size: 20),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.inter(
                  color: AppColors.textDim, fontSize: 12),
            )
          : null,
      trailing: Switch(
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Color(0xFF2A2A2A),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}

class _UserCard extends StatelessWidget {
  final AuthProvider auth;
  const _UserCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final nome = auth.user?.displayName ?? auth.user?.email ?? 'Utente';
    final email = auth.user?.email ?? '';
    final isArtista = auth.isArtista;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                style: GoogleFonts.oswald(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isArtista
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isArtista
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.textDim.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isArtista ? 'ARTISTA' : 'ASCOLTATORE',
                      style: GoogleFonts.inter(
                        color: isArtista
                            ? AppColors.primary
                            : AppColors.textDim,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
