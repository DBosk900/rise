import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../models/brano.dart';
import '../../models/classifica.dart';
import '../../services/gara_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/classifica_row.dart';
import '../gare/schermata_brano_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassificaScreen extends StatefulWidget {
  const ClassificaScreen({super.key});

  @override
  State<ClassificaScreen> createState() => _ClassificaScreenState();
}

class _ClassificaScreenState extends State<ClassificaScreen>
    with SingleTickerProviderStateMixin {
  final _garaService = GaraService();
  List<String> _generi = [];
  TabController? _tabController;
  String? _garaId;
  bool _loading = true;
  final _aggiornamento = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    final gara = await _garaService.getGaraAttivaOnce();
    if (gara == null) {
      setState(() => _loading = false);
      return;
    }
    final generi = await _garaService.getGeneriDisponibili(gara.id);
    final allGeneri = ['Tutti', ...generi];

    setState(() {
      _garaId = gara.id;
      _generi = allGeneri;
      _tabController = TabController(length: allGeneri.length, vsync: this);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: Text(
            'CLASSIFICA',
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: _tabController != null && _generi.length > 1
            ? TabBar(
                controller: _tabController!,
                isScrollable: true,
                tabs: _generi.map((g) => Tab(text: g)).toList(),
              )
            : null,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _garaId == null
              ? Center(
                  child: Text('Nessuna gara attiva',
                      style: AppTextStyles.bodyMedium(context)))
              : Column(
                  children: [
                    // Timestamp aggiornamento
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.update,
                              size: 12, color: AppColors.textDim),
                          const SizedBox(width: 4),
                          Text(
                            'Agg. ${DateFormat('dd/MM HH:mm').format(_aggiornamento)}',
                            style: AppTextStyles.bodySmall(context),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _generi.length <= 1
                          ? _ClassificaList(
                              garaId: _garaId!,
                              genere: null,
                            )
                          : TabBarView(
                              controller: _tabController!,
                              children: _generi.map((g) {
                                return _ClassificaList(
                                  garaId: _garaId!,
                                  genere: g == 'Tutti' ? null : g,
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _ClassificaList extends StatelessWidget {
  final String garaId;
  final String? genere;

  const _ClassificaList({required this.garaId, this.genere});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Brano>>(
      stream: GaraService().braniPerGaraStream(garaId, genere: genere),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final brani = snap.data ?? [];
        if (brani.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎵', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Nessun brano in classifica',
                    style: AppTextStyles.bodyMedium(context)),
              ],
            ),
          );
        }

        final classifica = Classifica.fromBrani(
          garaId,
          genere ?? 'Tutti',
          brani,
          DateTime.now(),
        );

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: classifica.righe.length.clamp(0, 10),
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: Color(0xFF2A2A2A),
            indent: 80,
          ),
          itemBuilder: (ctx, i) {
            return ClassificaRow(
              riga: classifica.righe[i],
              onTap: () => Navigator.of(ctx).push(
                MaterialPageRoute(
                  builder: (_) => SchermataBranoScreen(branoId: classifica.righe[i].brano.id),
                ),
              ),
            ).animate().fadeIn(
                  delay: Duration(milliseconds: 50 * i),
                  duration: 300.ms,
                );
          },
        );
      },
    );
  }
}
