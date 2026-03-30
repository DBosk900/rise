import 'package:cloud_firestore/cloud_firestore.dart';

class Brano {
  final String id;
  final String garaId;
  final String artistaId;
  final String artistaNome;
  final String titolo;
  final String urlAudio;
  final String urlCover;
  final String bio;
  final String genere;
  final String faseAttuale;
  final int votiTotali;
  final int votiSettimana;
  final int posizioneAttuale;
  final int posizionePrecedente;
  final bool eliminato;
  final DateTime dataIscrizione;

  const Brano({
    required this.id,
    required this.garaId,
    required this.artistaId,
    required this.artistaNome,
    required this.titolo,
    required this.urlAudio,
    required this.urlCover,
    required this.bio,
    required this.genere,
    required this.faseAttuale,
    this.votiTotali = 0,
    this.votiSettimana = 0,
    this.posizioneAttuale = 0,
    this.posizionePrecedente = 0,
    this.eliminato = false,
    required this.dataIscrizione,
  });

  int get variazioneRank => posizionePrecedente - posizioneAttuale;

  factory Brano.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Brano(
      id: doc.id,
      garaId: data['gara_id'] ?? '',
      artistaId: data['artista_id'] ?? '',
      artistaNome: data['artista_nome'] ?? '',
      titolo: data['titolo'] ?? '',
      urlAudio: data['url_audio'] ?? '',
      urlCover: data['url_cover'] ?? '',
      bio: data['bio'] ?? '',
      genere: data['genere'] ?? '',
      faseAttuale: data['fase_attuale'] ?? 'gironi',
      votiTotali: data['voti_totali'] ?? 0,
      votiSettimana: data['voti_settimana'] ?? 0,
      posizioneAttuale: data['posizione_attuale'] ?? 0,
      posizionePrecedente: data['posizione_precedente'] ?? 0,
      eliminato: data['eliminato'] ?? false,
      dataIscrizione:
          (data['data_iscrizione'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'gara_id': garaId,
        'artista_id': artistaId,
        'artista_nome': artistaNome,
        'titolo': titolo,
        'url_audio': urlAudio,
        'url_cover': urlCover,
        'bio': bio,
        'genere': genere,
        'fase_attuale': faseAttuale,
        'voti_totali': votiTotali,
        'voti_settimana': votiSettimana,
        'posizione_attuale': posizioneAttuale,
        'posizione_precedente': posizionePrecedente,
        'eliminato': eliminato,
        'data_iscrizione': Timestamp.fromDate(dataIscrizione),
      };

  Brano copyWith({
    int? votiTotali,
    int? votiSettimana,
    int? posizioneAttuale,
    int? posizionePrecedente,
    bool? eliminato,
    String? faseAttuale,
  }) =>
      Brano(
        id: id,
        garaId: garaId,
        artistaId: artistaId,
        artistaNome: artistaNome,
        titolo: titolo,
        urlAudio: urlAudio,
        urlCover: urlCover,
        bio: bio,
        genere: genere,
        faseAttuale: faseAttuale ?? this.faseAttuale,
        votiTotali: votiTotali ?? this.votiTotali,
        votiSettimana: votiSettimana ?? this.votiSettimana,
        posizioneAttuale: posizioneAttuale ?? this.posizioneAttuale,
        posizionePrecedente: posizionePrecedente ?? this.posizionePrecedente,
        eliminato: eliminato ?? this.eliminato,
        dataIscrizione: dataIscrizione,
      );
}
