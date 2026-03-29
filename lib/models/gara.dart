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
  final StatoGara stato;
  final double montepremitotale;
  final int numeroIscritti;
  final DateTime dataInizio;
  final DateTime dataFine;

  const Gara({
    required this.id,
    required this.mese,
    required this.anno,
    required this.tema,
    required this.stato,
    required this.montepremitotale,
    required this.numeroIscritti,
    required this.dataInizio,
    required this.dataFine,
  });

  /// 70% delle iscrizioni (2€ ciascuna) va al montepremi
  double get montepremiCalcolato => numeroIscritti * 2.0 * 0.70;

  factory Gara.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gara(
      id: doc.id,
      mese: data['mese'] ?? 1,
      anno: data['anno'] ?? DateTime.now().year,
      tema: data['tema'] ?? '',
      stato: StatoGaraExt.fromString(data['stato'] ?? 'iscrizioni'),
      montepremitotale: (data['montepremi_totale'] ?? 0.0).toDouble(),
      numeroIscritti: data['numero_iscritti'] ?? 0,
      dataInizio: (data['data_inizio'] as Timestamp).toDate(),
      dataFine: (data['data_fine'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'mese': mese,
        'anno': anno,
        'tema': tema,
        'stato': stato.name,
        'montepremi_totale': montepremitotale,
        'numero_iscritti': numeroIscritti,
        'data_inizio': Timestamp.fromDate(dataInizio),
        'data_fine': Timestamp.fromDate(dataFine),
      };

  Duration get tempoRimanente {
    final now = DateTime.now();
    if (dataFine.isBefore(now)) return Duration.zero;
    return dataFine.difference(now);
  }

  bool get isAttiva => stato != StatoGara.chiusa && dataFine.isAfter(DateTime.now());
}
