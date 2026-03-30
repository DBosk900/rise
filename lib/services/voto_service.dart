import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voto.dart';

class VotoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int votiGratuiSettimanali = 5;

  // ── Settimana ISO ────────────────────────────────────────────────────

  /// Restituisce la settimana ISO corrente in formato "2026-W14"
  String getSettimanaCorrente() => _isoWeek(DateTime.now());

  String _isoWeek(DateTime dt) {
    // Il giovedì della settimana corrente determina l'anno ISO
    final thursday = dt.add(Duration(days: DateTime.thursday - dt.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(jan1).inDays + 1;
    final jan1Weekday = jan1.weekday;
    final weekNum = ((dayOfYear + jan1Weekday - 2) / 7).ceil();
    return '${thursday.year}-W${weekNum.toString().padLeft(2, '0')}';
  }

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
    return _statoVotiFromDoc(doc);
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
      return _statoVotiFromDoc(doc);
    });
  }

  // Alias richiesto dalla spec
  Stream<int> getVotiRimasti(String userId) {
    return statoVotiStream(userId).map((s) => s.votiGratuiRimasti);
  }

  StatoVoti _statoVotiFromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final settimanaReset = data['ultima_settimana_reset'] as String?;
    final settimanaCorrente = getSettimanaCorrente();

    // Reset automatico se cambia la settimana
    if (settimanaReset != settimanaCorrente) {
      // Esegue il reset in background senza attendere
      _db.collection('utenti').doc(doc.id).update({
        'voti_rimasti': votiGratuiSettimanali,
        'ultima_settimana_reset': settimanaCorrente,
      }).ignore();
      return StatoVoti(
        votiGratuiRimasti: votiGratuiSettimanali,
        votiExtraDisponibili: data['voti_extra'] ?? 0,
        prossimoReset: _prossimoLunedi(),
      );
    }

    return StatoVoti(
      votiGratuiRimasti: data['voti_rimasti'] ?? 0,
      votiExtraDisponibili: data['voti_extra'] ?? 0,
      prossimoReset: _prossimoLunedi(),
    );
  }

  // ── Invio voto ───────────────────────────────────────────────────────

  Future<VotoResult> votaBrano({
    required String userId,
    required String branoId,
    required String garaId,
  }) async {
    final settimana = getSettimanaCorrente();

    try {
      // Controllo anti-bot: max 1 voto per brano per settimana (fuori transazione
      // per evitare read+write non atomica che Firestore non supporta per query)
      final votoEsistente = await _db
          .collection('voti')
          .where('ascoltatore_id', isEqualTo: userId)
          .where('brano_id', isEqualTo: branoId)
          .where('settimana', isEqualTo: settimana)
          .limit(1)
          .get();

      if (votoEsistente.docs.isNotEmpty) {
        return VotoResult.errore('Hai già votato questo brano questa settimana');
      }

      return await _db.runTransaction<VotoResult>((txn) async {
        final utenteRef = _db.collection('utenti').doc(userId);
        final branoRef = _db.collection('brani_in_gara').doc(branoId);
        final utenteDoc = await txn.get(utenteRef);
        final branoDoc = await txn.get(branoRef);

        if (!utenteDoc.exists) return VotoResult.errore('Utente non trovato');
        if (!branoDoc.exists) return VotoResult.errore('Brano non trovato');

        final data = utenteDoc.data()!;
        final settimanaReset = data['ultima_settimana_reset'] as String?;

        int votiGratuiti = settimanaReset != settimana
            ? votiGratuiSettimanali
            : (data['voti_rimasti'] ?? 0);
        int votiExtra = data['voti_extra'] ?? 0;

        if (votiGratuiti <= 0 && votiExtra <= 0) {
          return VotoResult.errore('Voti esauriti — acquista voti extra');
        }

        // Usa i voti gratuiti prima degli extra
        if (votiGratuiti > 0) {
          txn.update(utenteRef, {
            'voti_rimasti': votiGratuiti - 1,
            'ultima_settimana_reset': settimana,
          });
        } else {
          txn.update(utenteRef, {
            'voti_extra': votiExtra - 1,
          });
        }

        // Incrementa voti brano (totali + settimanali)
        txn.update(branoRef, {
          'voti_totali': FieldValue.increment(1),
          'voti_settimana': FieldValue.increment(1),
        });

        // Registra il voto
        final votoRef = _db.collection('voti').doc();
        txn.set(votoRef, {
          'ascoltatore_id': userId,
          'brano_id': branoId,
          'gara_id': garaId,
          'settimana': settimana,
          'timestamp': Timestamp.now(),
        });

        return VotoResult.ok();
      });
    } catch (e) {
      return VotoResult.errore('Errore: $e');
    }
  }

  Future<void> aggiungiVotiExtra(String userId, int quantita) async {
    await _db.collection('utenti').doc(userId).update({
      'voti_extra': FieldValue.increment(quantita),
    });
  }

  // Alias per compatibilità
  Future<void> usaVotiExtra(String userId, int quantita) =>
      aggiungiVotiExtra(userId, quantita);

  // ── Helpers ───────────────────────────────────────────────────────────

  DateTime _prossimoLunedi() {
    final now = DateTime.now();
    final days = (DateTime.monday - now.weekday + 7) % 7;
    return DateTime(now.year, now.month, now.day + (days == 0 ? 7 : days));
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
