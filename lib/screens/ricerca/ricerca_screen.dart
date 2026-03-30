import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/brano.dart';
import '../../theme/app_theme.dart';
import '../gare/schermata_brano_screen.dart';

class RicercaScreen extends StatefulWidget {
  const RicercaScreen({super.key});

  @override
  State<RicercaScreen> createState() => _RicercaScreenState();
}

class _RicercaScreenState extends State<RicercaScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = _controller.text.trim().toLowerCase());
    });
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
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Cerca brani o artisti...',
            hintStyle: GoogleFonts.inter(
                color: AppColors.textDim, fontSize: 16),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        color: AppColors.textSecondary),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'BRANI'),
            Tab(text: 'ARTISTI'),
          ],
        ),
      ),
      body: _query.isEmpty
          ? _buildEmpty()
          : TabBarView(
              controller: _tabController,
              children: [
                _BraniSearch(query: _query),
                _ArtistiSearch(query: _query),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 64, color: AppColors.textDim),
          const SizedBox(height: 16),
          Text(
            'Cerca brani o artisti',
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _BraniSearch extends StatelessWidget {
  final String query;

  const _BraniSearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('brani_in_gara')
          .where('eliminato', isEqualTo: false)
          .orderBy('voti_totali', descending: true)
          .limit(100)
          .get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final all = snap.data?.docs.map(Brano.fromFirestore).toList() ?? [];
        final results = all
            .where((b) =>
                b.titolo.toLowerCase().contains(query) ||
                b.artistaNome.toLowerCase().contains(query) ||
                b.genere.toLowerCase().contains(query))
            .toList();

        if (results.isEmpty) {
          return Center(
            child: Text(
              'Nessun brano trovato per "$query"',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: Color(0xFF2A2A2A),
            indent: 72,
          ),
          itemBuilder: (ctx, i) {
            final brano = results[i];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: brano.urlCover,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.cardDark,
                    child: const Icon(Icons.music_note,
                        color: AppColors.textDim),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.cardDark,
                    child: const Icon(Icons.music_note,
                        color: AppColors.textDim),
                  ),
                ),
              ),
              title: Text(
                brano.titolo,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              subtitle: Text(
                '${brano.artistaNome} · ${brano.genere}',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.how_to_vote,
                      size: 14, color: AppColors.textDim),
                  const SizedBox(width: 4),
                  Text(
                    '${brano.votiTotali}',
                    style: GoogleFonts.inter(
                        color: AppColors.textDim, fontSize: 12),
                  ),
                ],
              ),
              onTap: () => Navigator.of(ctx).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SchermataBranoScreen(branoId: brano.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ArtistiSearch extends StatelessWidget {
  final String query;

  const _ArtistiSearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('artisti')
          .orderBy('nome')
          .limit(200)
          .get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snap.data?.docs ?? [];
        final results = docs.where((d) {
          final nome =
              (d.data() as Map<String, dynamic>)['nome']?.toString().toLowerCase() ?? '';
          final bio =
              (d.data() as Map<String, dynamic>)['bio']?.toString().toLowerCase() ?? '';
          return nome.contains(query) || bio.contains(query);
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text(
              'Nessun artista trovato per "$query"',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: Color(0xFF2A2A2A),
            indent: 72,
          ),
          itemBuilder: (ctx, i) {
            final data = results[i].data() as Map<String, dynamic>;
            final urlFoto = data['url_foto'] as String? ?? '';
            final nome = data['nome'] as String? ?? '';
            final genere = data['genere'] as String? ?? '';
            final bio = data['bio'] as String? ?? '';

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.cardDark,
                backgroundImage: urlFoto.isNotEmpty
                    ? CachedNetworkImageProvider(urlFoto)
                    : null,
                child: urlFoto.isEmpty
                    ? Text(
                        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                        style: GoogleFonts.oswald(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              title: Text(
                nome,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              subtitle: Text(
                genere.isNotEmpty ? genere : bio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textDim),
            );
          },
        );
      },
    );
  }
}
