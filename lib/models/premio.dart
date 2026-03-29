import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoBadge {
  top1,
  top3,
  top10,
  primaGara,
  cinqueGare,
  preferitoPubblico,
}

extension TipoBadgeExt on TipoBadge {
  String get label {
    switch (this) {
      case TipoBadge.top1:
        return '🥇 Vincitore';
      case TipoBadge.top3:
        return '🥈 Podio';
      case TipoBadge.top10:
        return 'Top 10';
      case TipoBadge.primaGara:
        return 'Debutto';
      case TipoBadge.cinqueGare:
        return '5 Gare';
      case TipoBadge.preferitoPubblico:
        return '❤️ Favorito';
    }
  }

  String get emoji {
    switch (this) {
      case TipoBadge.top1:
        return '🏆';
      case TipoBadge.top3:
        return '🥈';
      case TipoBadge.top10:
        return '⭐';
      case TipoBadge.primaGara:
        return '🎤';
      case TipoBadge.cinqueGare:
        return '🔥';
      case TipoBadge.preferitoPubblico:
        return '❤️';
    }
  }
}

class Premio {
  final String id;
  final String garaId;
  final String artistaId;
  final int posizione;
  final double importo;
  final DateTime dataAssegnazione;
  final bool pagato;

  const Premio({
    required this.id,
    required this.garaId,
    required this.artistaId,
    required this.posizione,
    required this.importo,
    required this.dataAssegnazione,
    required this.pagato,
  });

  factory Premio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Premio(
      id: doc.id,
      garaId: data['gara_id'] ?? '',
      artistaId: data['artista_id'] ?? '',
      posizione: data['posizione'] ?? 0,
      importo: (data['importo'] ?? 0.0).toDouble(),
      dataAssegnazione:
          (data['data_assegnazione'] as Timestamp).toDate(),
      pagato: data['pagato'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'gara_id': garaId,
        'artista_id': artistaId,
        'posizione': posizione,
        'importo': importo,
        'data_assegnazione': Timestamp.fromDate(dataAssegnazione),
        'pagato': pagato,
      };
}
