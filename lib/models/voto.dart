import 'package:cloud_firestore/cloud_firestore.dart';

class Voto {
  final String id;
  final String ascoltatoreid;
  final String branoId;
  final String garaId;
  final DateTime timestamp;

  const Voto({
    required this.id,
    required this.ascoltatoreid,
    required this.branoId,
    required this.garaId,
    required this.timestamp,
  });

  factory Voto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Voto(
      id: doc.id,
      ascoltatoreid: data['ascoltatore_id'] ?? '',
      branoId: data['brano_id'] ?? '',
      garaId: data['gara_id'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ascoltatore_id': ascoltatoreid,
        'brano_id': branoId,
        'gara_id': garaId,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  /// Settimana ISO (lunedì → domenica) del voto
  int get settimana {
    final t = timestamp;
    final dayOfYear = int.parse(
        '${t.difference(DateTime(t.year, 1, 1)).inDays}');
    return ((dayOfYear - t.weekday + 10) / 7).floor();
  }
}

class StatoVoti {
  final int votiGratuiRimasti;
  final int votiExtraDisponibili;
  final DateTime prossimoReset;

  const StatoVoti({
    required this.votiGratuiRimasti,
    required this.votiExtraDisponibili,
    required this.prossimoReset,
  });

  int get totaleDisponibili => votiGratuiRimasti + votiExtraDisponibili;

  bool get haVoti => totaleDisponibili > 0;
}
