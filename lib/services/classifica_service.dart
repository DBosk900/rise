import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brano.dart';

class ClassificaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Aggiorna posizione_attuale e posizione_precedente per tutti i brani della gara.
  /// Va chiamata periodicamente (ogni 24h o manualmente dall'admin).
  Future<void> aggiornaClassifica(String garaId) async {
    final snap = await _db
        .collection('brani_in_gara')
        .where('gara_id', isEqualTo: garaId)
        .where('eliminato', isEqualTo: false)
        .get();

    final brani = snap.docs.map(Brano.fromFirestore).toList();

    // Ordina per voti_totali decrescente
    brani.sort((a, b) => b.votiTotali.compareTo(a.votiTotali));

    // Aggiorna in batch (max 500 op per batch)
    final batch = _db.batch();
    for (int i = 0; i < brani.length; i++) {
      final brano = brani[i];
      final nuovaPosizione = i + 1;
      final ref = _db.collection('brani_in_gara').doc(brano.id);
      batch.update(ref, {
        'posizione_precedente': brano.posizioneAttuale,
        'posizione_attuale': nuovaPosizione,
      });
    }
    await batch.commit();
  }

  /// Ritorna la variazione di posizione del brano:
  /// positivo = salito, negativo = sceso, 0 = stabile
  int getVariazionePosizione(Brano brano) {
    if (brano.posizionePrecedente == 0) return 0;
    return brano.posizionePrecedente - brano.posizioneAttuale;
  }

  /// Stream della classifica con aggiornamenti real-time
  Stream<List<Brano>> classificaStream(String garaId) {
    return _db
        .collection('brani_in_gara')
        .where('gara_id', isEqualTo: garaId)
        .where('eliminato', isEqualTo: false)
        .orderBy('voti_totali', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Brano.fromFirestore).toList());
  }
}
