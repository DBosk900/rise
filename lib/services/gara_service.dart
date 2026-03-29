import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gara.dart';
import '../models/brano.dart';

class GaraService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Gare ──────────────────────────────────────────────────────────────

  Stream<Gara?> garaAttivaStream() {
    return _db
        .collection('gare')
        .where('stato', whereNotIn: ['chiusa'])
        .orderBy('data_inizio', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : Gara.fromFirestore(snap.docs.first));
  }

  Future<Gara?> getGaraAttiva() async {
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

    // Incrementa numero iscritti nella gara
    await _db.collection('gare').doc(garaId).update({
      'numero_iscritti': FieldValue.increment(1),
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
}
