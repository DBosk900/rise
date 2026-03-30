import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vincitore.dart';

class HallOfFameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Vincitore>> vincitoriStream() {
    return _db
        .collection('vincitori')
        .orderBy('anno', descending: true)
        .orderBy('mese', descending: true)
        .orderBy('posizione')
        .snapshots()
        .map((s) => s.docs.map(Vincitore.fromFirestore).toList());
  }

  Future<List<Vincitore>> getVincitori({int? anno}) async {
    Query query = _db
        .collection('vincitori')
        .orderBy('anno', descending: true)
        .orderBy('mese', descending: true)
        .orderBy('posizione');

    if (anno != null) {
      query = query.where('anno', isEqualTo: anno);
    }

    final snap = await query.get();
    return snap.docs.map(Vincitore.fromFirestore).toList();
  }

  Future<List<Vincitore>> getTopArtisti({int limit = 10}) async {
    // Raggruppa per artista_id e conta vittorie
    final snap = await _db
        .collection('vincitori')
        .where('posizione', isEqualTo: 1)
        .orderBy('anno', descending: true)
        .get();
    return snap.docs.map(Vincitore.fromFirestore).toList();
  }
}
