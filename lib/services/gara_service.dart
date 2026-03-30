import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gara.dart';
import '../models/brano.dart';

class GaraService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Gare ──────────────────────────────────────────────────────────────

  /// Stream della gara attiva (stato != chiusa)
  Stream<Gara?> getGaraAttiva() {
    return _db
        .collection('gare')
        .where('stato', whereNotIn: ['chiusa'])
        .orderBy('data_inizio', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : Gara.fromFirestore(snap.docs.first));
  }

  // Alias per compatibilità con codice esistente
  Stream<Gara?> garaAttivaStream() => getGaraAttiva();

  Future<Gara?> getGaraAttivaOnce() async {
    final snap = await _db
        .collection('gare')
        .where('stato', whereNotIn: ['chiusa'])
        .orderBy('data_inizio', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Gara.fromFirestore(snap.docs.first);
  }

  Future<List<Gara>> getAllGare() async {
    final snap = await _db
        .collection('gare')
        .orderBy('data_inizio', descending: true)
        .get();
    return snap.docs.map(Gara.fromFirestore).toList();
  }

  // ── Montepremi ────────────────────────────────────────────────────────

  Stream<double> getMontepremiAttuale(String garaId) {
    return _db.collection('gare').doc(garaId).snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      return (doc.data()?['montepremi_totale'] ?? 0.0).toDouble();
    });
  }

  // ── Brani ─────────────────────────────────────────────────────────────

  Stream<List<Brano>> braniPerGaraStream(String garaId, {String? genere}) {
    Query query = _db
        .collection('brani_in_gara')
        .where('gara_id', isEqualTo: garaId)
        .where('eliminato', isEqualTo: false);

    if (genere != null) {
      query = query.where('genere', isEqualTo: genere);
    }

    return query
        .orderBy('voti_totali', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Brano.fromFirestore).toList());
  }

  // Alias richiesto dalla spec
  Stream<List<Brano>> getBraniPerGenere(String garaId, String? genere) =>
      braniPerGaraStream(garaId, genere: genere);

  /// Stream classifica generale ordinata per voti
  Stream<List<Brano>> getClassificaGenerale(String garaId) {
    return _db
        .collection('brani_in_gara')
        .where('gara_id', isEqualTo: garaId)
        .where('eliminato', isEqualTo: false)
        .orderBy('voti_totali', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Brano.fromFirestore).toList());
  }

  Future<List<Brano>> getBraniPerGara(String garaId, {String? genere}) async {
    Query query = _db
        .collection('brani_in_gara')
        .where('gara_id', isEqualTo: garaId)
        .where('eliminato', isEqualTo: false);

    if (genere != null) {
      query = query.where('genere', isEqualTo: genere);
    }

    final snap = await query.orderBy('voti_totali', descending: true).get();
    return snap.docs.map(Brano.fromFirestore).toList();
  }

  Future<Brano?> getBranoArtista(String artistaId, String garaId) async {
    final snap = await _db
        .collection('brani_in_gara')
        .where('artista_id', isEqualTo: artistaId)
        .where('gara_id', isEqualTo: garaId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Brano.fromFirestore(snap.docs.first);
  }

  Future<String> iscriviBrano({
    required String garaId,
    required String artistaId,
    required String artistaNome,
    required String titolo,
    required String urlAudio,
    required String urlCover,
    required String bio,
    required String genere,
  }) async {
    final ref = _db.collection('brani_in_gara').doc();
    final brano = Brano(
      id: ref.id,
      garaId: garaId,
      artistaId: artistaId,
      artistaNome: artistaNome,
      titolo: titolo,
      urlAudio: urlAudio,
      urlCover: urlCover,
      bio: bio,
      genere: genere,
      faseAttuale: 'gironi',
      dataIscrizione: DateTime.now(),
    );
    await ref.set(brano.toFirestore());

    // Incrementa numero iscritti e montepremi nella gara
    await _db.collection('gare').doc(garaId).update({
      'n_iscritti': FieldValue.increment(1),
      'montepremi_totale': FieldValue.increment(2.0 * 0.70),
    });

    return ref.id;
  }

  Future<List<String>> getGeneriDisponibili(String garaId) async {
    final snap = await _db
        .collection('brani_in_gara')
        .where('gara_id', isEqualTo: garaId)
        .get();
    final generi = snap.docs
        .map((d) => d.data()['genere'] as String? ?? '')
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return generi;
  }

  // ── Crea nuova gara ───────────────────────────────────────────────────

  static const _temiPredefiniti = [
    'Libertà',
    'Notte',
    'Rinascita',
    'Viaggio',
    'Amore',
    'Città',
    'Sogni',
    'Confini',
    'Fuoco',
    'Radici',
  ];

  Future<String> creaGaraMese({
    String? tema,
    String? temaDescrizione,
  }) async {
    final now = DateTime.now();

    // Controlla se esiste già una gara per questo mese
    final esistente = await _db
        .collection('gare')
        .where('mese', isEqualTo: now.month)
        .where('anno', isEqualTo: now.year)
        .limit(1)
        .get();

    if (esistente.docs.isNotEmpty) {
      throw Exception('Esiste già una gara per ${now.month}/${now.year}');
    }

    // Tema: parametro > tema casuale dalla lista predefinita
    final temaFinale = tema ??
        _temiPredefiniti[now.month % _temiPredefiniti.length];

    final inizioIscrizioni = DateTime(now.year, now.month, 1);
    final fineIscrizioni = DateTime(now.year, now.month, 7, 23, 59);
    final inizioGironi = DateTime(now.year, now.month, 8);
    final fineMese = DateTime(now.year, now.month + 1, 0, 23, 59); // ultimo giorno

    final ref = _db.collection('gare').doc();
    final gara = Gara(
      id: ref.id,
      mese: now.month,
      anno: now.year,
      tema: temaFinale,
      temaDescrizione: temaDescrizione ?? 'Gara mensile RISE — $temaFinale',
      stato: StatoGara.iscrizioni,
      montepremitotale: 0,
      numeroIscritti: 0,
      dataInizio: inizioIscrizioni,
      dataFine: fineMese,
      dataInizioIscrizioni: inizioIscrizioni,
      dataFineIscrizioni: fineIscrizioni,
      dataInizioGironi: inizioGironi,
    );

    await ref.set(gara.toFirestore());
    return ref.id;
  }
}
