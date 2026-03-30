import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ComeFunzionaScreen extends StatefulWidget {
  const ComeFunzionaScreen({super.key});

  @override
  State<ComeFunzionaScreen> createState() => _ComeFunzionaScreenState();
}

class _ComeFunzionaScreenState extends State<ComeFunzionaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: Text(
            'COME FUNZIONA',
            style: GoogleFonts.oswald(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ASCOLTATORI'),
            Tab(text: 'ARTISTI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AscoltatorTab(),
          _ArtistaTab(),
        ],
      ),
    );
  }
}

class _AscoltatorTab extends StatelessWidget {
  const _AscoltatorTab();

  static const _steps = [
    (
      Icons.person_add_outlined,
      'Registrati',
      'Crea il tuo account gratuito su RISE in pochi secondi.',
    ),
    (
      Icons.music_note_outlined,
      'Ascolta i brani',
      'Ogni mese centinaia di artisti indipendenti si sfidano su un tema. Ascolta le loro canzoni.',
    ),
    (
      Icons.how_to_vote_outlined,
      'Vota i tuoi preferiti',
      'Hai 5 voti gratuiti a settimana. Vota i brani che ami di più — ogni voto conta!',
    ),
    (
      Icons.bar_chart_outlined,
      'Segui la classifica',
      'La classifica si aggiorna in tempo reale. Vedi chi sale e chi scende.',
    ),
    (
      Icons.emoji_events_outlined,
      'I vincitori ricevono il montepremi',
      'A fine mese, i 3 artisti più votati si dividono il montepremi. I tuoi voti decidono!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _HeroCard(
          icon: Icons.headphones,
          title: 'Scopri nuova musica indipendente',
          subtitle: 'e dai voce agli artisti che ami',
        ),
        const SizedBox(height: 32),
        ..._steps.asMap().entries.map(
              (e) => _StepCard(
                number: e.key + 1,
                icon: e.value.$1,
                title: e.value.$2,
                desc: e.value.$3,
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 100 * e.key),
                    duration: 400.ms,
                  ),
            ),
        const SizedBox(height: 24),
        _FaqSection(faqs: const [
          ('Quanto costano i voti extra?', 'Puoi acquistare pacchetti di voti aggiuntivi dall\'app: 5 voti a 0,99€, 15 voti a 1,99€, 50 voti a 4,99€.'),
          ('Posso votare lo stesso artista più volte?', 'No — ogni utente può dare un solo voto per brano a settimana. I voti si resettano ogni lunedì.'),
          ('Come viene calcolato il montepremi?', 'Il 70% delle entrate dai voti extra e abbonamenti va direttamente agli artisti. Il montepremi cresce con ogni acquisto.'),
        ]),
      ],
    );
  }
}

class _ArtistaTab extends StatelessWidget {
  const _ArtistaTab();

  static const _steps = [
    (
      Icons.app_registration_outlined,
      'Registrati come artista',
      'Crea il tuo profilo artista su RISE e completa la tua biografia.',
    ),
    (
      Icons.upload_outlined,
      'Carica il tuo brano',
      'Iscriviti alla gara del mese caricando audio (MP3/AAC) e copertina. Il tema viene svelato ogni 1° del mese.',
    ),
    (
      Icons.people_outlined,
      'Promuoviti',
      'Condividi il link al tuo brano con i fan. Ogni voto ti aiuta a salire in classifica.',
    ),
    (
      Icons.emoji_events_outlined,
      'Vinci il montepremi',
      '1° posto: 50% del montepremi\n2° posto: 30%\n3° posto: 20%',
    ),
    (
      Icons.payments_outlined,
      'Ricevi il tuo pagamento',
      'I vincitori ricevono il loro premio via bonifico entro 7 giorni dalla fine della gara.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _HeroCard(
          icon: Icons.mic_outlined,
          title: 'Porta la tua musica al pubblico',
          subtitle: 'e vinci ogni mese',
        ),
        const SizedBox(height: 32),
        ..._steps.asMap().entries.map(
              (e) => _StepCard(
                number: e.key + 1,
                icon: e.value.$1,
                title: e.value.$2,
                desc: e.value.$3,
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 100 * e.key),
                    duration: 400.ms,
                  ),
            ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: AppColors.gold, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Abbonamento Pro Artista',
                      style: GoogleFonts.oswald(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Partecipa a gare illimitate e ottieni visibilità extra.',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _FaqSection(faqs: const [
          ('Quante gare posso fare al mese?', 'Gratuitamente puoi partecipare a 1 gara al mese. Con il piano Pro non ci sono limiti.'),
          ('Che formato audio accettate?', 'MP3 o AAC, massimo 20MB. Durata consigliata: 2-4 minuti.'),
          ('Quando vengono pagati i premi?', 'Entro 7 giorni dalla chiusura della gara. Riceverai una notifica con i dettagli del pagamento.'),
        ]),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String desc;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numero step
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.oswald(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.oswald(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final List<(String, String)> faqs;

  const _FaqSection({required this.faqs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAQ',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ...faqs.map(
          (f) => Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              unselectedWidgetColor: AppColors.textSecondary,
            ),
            child: ExpansionTile(
              title: Text(
                f.$1,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Text(
                    f.$2,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
