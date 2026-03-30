import 'package:cloud_firestore/cloud_firestore.dart';

class Vincitore {
  final String id;
  final String garaId;
  final int mese;
  final int anno;
  final String tema;
  final String artistaId;
  final String artistaNome;
  final String titoloCanzone;
  final String urlCover;
  final String urlAudio;
  final String genere;
  final int votiTotali;
  final int posizione; // 1, 2, 3
  final double premioVinto;

  const Vincitore({
    required this.id,
    required this.garaId,
    required this.mese,
    required this.anno,
    required this.tema,
    required this.artistaId,
    required this.artistaNome,
    required this.titoloCanzone,
    required this.urlCover,
    required this.urlAudio,
    required this.genere,
    required this.votiTotali,
    required this.posizione,
    required this.premioVinto,
  });

  factory Vincitore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vincitore(
      id: doc.id,
      garaId: data['gara_id'] ?? '',
      mese: data['mese'] ?? 0,
      anno: data['anno'] ?? 0,
      tema: data['tema'] ?? '',
      artistaId: data['artista_id'] ?? '',
      artistaNome: data['artista_nome'] ?? '',
      titoloCanzone: data['titolo'] ?? '',
      urlCover: data['url_cover'] ?? '',
      urlAudio: data['url_audio'] ?? '',
      genere: data['genere'] ?? '',
      votiTotali: data['voti_totali'] ?? 0,
      posizione: data['posizione'] ?? 1,
      premioVinto: (data['premio_vinto'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'gara_id': garaId,
        'mese': mese,
        'anno': anno,
        'tema': tema,
        'artista_id': artistaId,
        'artista_nome': artistaNome,
        'titolo': titoloCanzone,
        'url_cover': urlCover,
        'url_audio': urlAudio,
        'genere': genere,
        'voti_totali': votiTotali,
        'posizione': posizione,
        'premio_vinto': premioVinto,
      };

  String get meseAnnoLabel {
    const mesi = [
      '', 'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
      'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
    ];
    return '${mesi[mese]} $anno';
  }
}
