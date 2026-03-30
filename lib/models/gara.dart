import 'package:cloud_firestore/cloud_firestore.dart';

enum StatoGara {
  iscrizioni,
  gironi,
  quarti,
  semifinale,
  finale,
  chiusa,
}

extension StatoGaraExt on StatoGara {
  String get label {
    switch (this) {
      case StatoGara.iscrizioni:
        return 'Iscrizioni Aperte';
      case StatoGara.gironi:
        return 'Gironi';
      case StatoGara.quarti:
        return 'Quarti di Finale';
      case StatoGara.semifinale:
        return 'Semifinale';
      case StatoGara.finale:
        return 'Finale';
      case StatoGara.chiusa:
        return 'Chiusa';
    }
  }

  static StatoGara fromString(String s) {
    return StatoGara.values.firstWhere(
      (e) => e.name == s,
      orElse: () => StatoGara.iscrizioni,
    );
  }
}

class Gara {
  final String id;
  final int mese;
  final int anno;
  final String tema;
  final String temaDescrizione;
  final StatoGara stato;
  final double montepremitotale;
  final int numeroIscritti;
  final DateTime dataInizio;
  final DateTime dataFine;
  final DateTime? dataInizioIscrizioni;
  final DateTime? dataFineIscrizioni;
  final DateTime? dataInizioGironi;

  const Gara({
    required this.id,
    required this.mese,
    required this.anno,
    required this.tema,
    this.temaDescrizione = '',
    required this.stato,
    required this.montepremitotale,
    required this.numeroIscritti,
    required this.dataInizio,
    required this.dataFine,
    this.dataInizioIscrizioni,
    this.dataFineIscrizioni,
    this.dataInizioGironi,
  });

  /// 70% delle iscrizioni (2€ ciascuna) va al montepremi
  double get montepremiCalcolato => numeroIscritti * 2.0 * 0.70;

  factory Gara.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime parseTs(String key) {
      final ts = data[key];
      if (ts is Timestamp) return ts.toDate();
      return DateTime.now();
    }

    DateTime? parseTsOpt(String key) {
      final ts = data[key];
      if (ts is Timestamp) return ts.toDate();
      return null;
    }

    return Gara(
      id: doc.id,
      mese: data['mese'] ?? 1,
      anno: data['anno'] ?? DateTime.now().year,
      tema: data['tema'] ?? '',
      temaDescrizione: data['tema_descrizione'] ?? '',
      stato: StatoGaraExt.fromString(data['stato'] ?? 'iscrizioni'),
      montepremitotale: (data['montepremi_totale'] ?? 0.0).toDouble(),
      // Accept both n_iscritti (new) and numero_iscritti (legacy)
      numeroIscritti:
          data['n_iscritti'] ?? data['numero_iscritti'] ?? 0,
      dataInizio: parseTs('data_inizio'),
      dataFine: parseTs('data_fine'),
      dataInizioIscrizioni: parseTsOpt('data_inizio_iscrizioni'),
      dataFineIscrizioni: parseTsOpt('data_fine_iscrizioni'),
      dataInizioGironi: parseTsOpt('data_inizio_gironi'),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'mese': mese,
        'anno': anno,
        'tema': tema,
        'tema_descrizione': temaDescrizione,
        'stato': stato.name,
        'montepremi_totale': montepremitotale,
        'n_iscritti': numeroIscritti,
        'data_inizio': Timestamp.fromDate(dataInizio),
        'data_fine': Timestamp.fromDate(dataFine),
        if (dataInizioIscrizioni != null)
          'data_inizio_iscrizioni': Timestamp.fromDate(dataInizioIscrizioni!),
        if (dataFineIscrizioni != null)
          'data_fine_iscrizioni': Timestamp.fromDate(dataFineIscrizioni!),
        if (dataInizioGironi != null)
          'data_inizio_gironi': Timestamp.fromDate(dataInizioGironi!),
      };

  Duration get tempoRimanente {
    final now = DateTime.now();
    if (dataFine.isBefore(now)) return Duration.zero;
    return dataFine.difference(now);
  }

  bool get isAttiva =>
      stato != StatoGara.chiusa && dataFine.isAfter(DateTime.now());
}
