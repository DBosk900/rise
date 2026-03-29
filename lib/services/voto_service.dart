import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voto.dart';

class VotoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int votiGratuiSettimanali = 5;

  // ── Stato voti utente ────────────────────────────────────────────────

  Future<StatoVoti> getStatoVoti(String userId) async {
    final doc = await _db.collection('utenti').doc(userId).get();
    if (!doc.exists) {
      return StatoVoti(
        votiGratuiRimasti: votiGratuiSettimanali,
        votiExtraDisponibili: 0,
        prossimoReset: _prossimoLunedi(),
      );
    }
    final data = doc.data()!;
    final resetStr = data['settimana_reset'] as String?;
    final reset = resetStr != null ? DateTime.parse(resetStr) : _prossimoLunedi();

    // Se il reset è passato, ripristina i voti gratuiti
    if (DateTime.now().isAfter(reset)) {
      await _db.collection('utenti').doc(userId).update({
        'voti_gratuiti_rimasti': votiGratuiSettimanali,
        'settimana_reset': _prossimoLunedi().toIso8601String(),
      });
      return StatoVoti(
        votiGratuiRimasti: votiGratuiSettimanali,
        votiExtraDisponibili: data['voti_extra_disponibili'] ?? 0,
        prossimoReset: _prossimoLunedi(),
      );
    }

    return StatoVoti(
      votiGratuiRimasti: data['voti_gratuiti_rimasti'] ?? 0,
      votiExtraDisponibili: data['voti_extra_disponibili'] ?? 0,
      prossimoReset: reset,
    );
  }

  Stream<StatoVoti> statoVotiStream(String userId) {
    return _db.collection('utenti').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return StatoVoti(
          votiGratuiRimasti: votiGratuiSettimanali,
          votiExtraDisponibili: 0,
          prossimoReset: _prossimoLunedi(),
        );
      }
      final data = doc.data()!;
      return StatoVoti(
        votiGratuiRimasti: data['voti_gratuiti_rimasti'] ?? 0,
        votiExtraDisponibili: data['voti_extra_disponibili'] ?? 0,
        prossimoReset: DateTime.tryParse(data['settimana_reset'] ?? '') ??
            _prossimoLunedi(),
      );
    });
  }

  // ── Invio voto ───────────────────────────────────────────────────────

  Future<VotoResult> votaBrano({
    required String userId,
    required String branoId,
    required String garaId,
  }) async {
    return _db.runTransaction<VotoResult>((txn) async {
      final utenteRef = _db.collection('utenti').doc(userId);
      final branoRef = _db.collection('brani_in_gara').doc(branoId);
      final utenteDoc = await txn.get(utenteRef);
      final branoDoc = await txn.get(branoRef);

      if (!utenteDoc.exists) return VotoResult.errore('Utente non trovato');
      if (!branoDoc.exists) return VotoResult.errore('Brano non trovato');

      final data = utenteDoc.data()!;

      // Controllo reset settimanale
      final resetStr = data['settimana_reset'] as String?;
      final reset = resetStr != null ? DateTime.parse(resetStr) : _prossimoLunedi();
      int votiGratuiti = data['voti_gratuiti_rimasti'] ?? 0;
      int votiExtra = data['voti_extra_disponibili'] ?? 0;

      if (DateTime.now().isAfter(reset)) {
        votiGratuiti = votiGratuiSettimanali;
      }

      if (votiGratuiti <= 0 && votiExtra <= 0) {
        return VotoResult.errore('Nessun voto disponibile');
      }

      // Controllo anti-bot: max 1 voto per brano per settimana
      final weekKey = _weekKey(DateTime.now());
      final votoExistenteSnap = await _db
          .collection('voti')
          .where('ascoltatore_id', isEqualTo: userId)
          .where('brano_id', isEqualTo: branoId)
          .where('week_key', isEqualTo: weekKey)
          .limit(1)
          .get();

      if (votoExistenteSnap.docs.isNotEmpty) {
        return VotoResult.errore('Hai già votato questo brano questa settimana');
      }

      // Scala i voti gratuiti prima degli extra
      if (votiGratuiti > 0) {
        txn.update(utenteRef, {
          'voti_gratuiti_rimasti': votiGratuiti - 1,
          'settimana_reset': reset.toIso8601String(),
        });
      } else {
        txn.update(utenteRef, {
          'voti_extra_disponibili': votiExtra - 1,
        });
      }

      // Incrementa voti brano
      txn.update(branoRef, {
        'voti_totali': FieldValue.increment(1),
      });

      // Registra voto
      final votoRef = _db.collection('voti').doc();
      txn.set(votoRef, {
        'ascoltatore_id': userId,
        'brano_id': branoId,
        'gara_id': garaId,
        'timestamp': Timestamp.now(),
        'week_key': weekKey,
      });

      return VotoResult.ok();
    });
  }

  Future<void> aggiungiVotiExtra(String userId, int quantita) async {
    await _db.collection('utenti').doc(userId).update({
      'voti_extra_disponibili': FieldValue.increment(quantita),
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  DateTime _prossimoLunedi() {
    final now = DateTime.now();
    final days = (DateTime.monday - now.weekday + 7) % 7;
    return DateTime(now.year, now.month, now.day + (days == 0 ? 7 : days));
  }

  String _weekKey(DateTime dt) {
    final startOfYear = DateTime(dt.year, 1, 1);
    final week = ((dt.difference(startOfYear).inDays) / 7).floor();
    return '${dt.year}_$week';
  }
}

class VotoResult {
  final bool success;
  final String? error;

  const VotoResult._({required this.success, this.error});

  factory VotoResult.ok() => const VotoResult._(success: true);
  factory VotoResult.errore(String msg) =>
      VotoResult._(success: false, error: msg);
}
