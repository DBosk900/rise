import 'package:cloud_firestore/cloud_firestore.dart';

class Artista {
  final String id;
  final String nome;
  final String email;
  final String? fotoProfilo;
  final String? bio;
  final bool abbonamentoAttivo;
  final DateTime? dataScadenzaAbbonamento;
  final int votiExtraDisponibili;
  final List<String> badge;
  final List<String> storicoGare;
  final DateTime createdAt;

  const Artista({
    required this.id,
    required this.nome,
    required this.email,
    this.fotoProfilo,
    this.bio,
    required this.abbonamentoAttivo,
    this.dataScadenzaAbbonamento,
    this.votiExtraDisponibili = 0,
    this.badge = const [],
    this.storicoGare = const [],
    required this.createdAt,
  });

  factory Artista.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Artista(
      id: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      fotoProfilo: data['foto_profilo'],
      bio: data['bio'],
      abbonamentoAttivo: data['abbonamento_attivo'] ?? false,
      dataScadenzaAbbonamento: (data['data_scadenza'] as Timestamp?)?.toDate(),
      votiExtraDisponibili: data['voti_extra_disponibili'] ?? 0,
      badge: List<String>.from(data['badge'] ?? []),
      storicoGare: List<String>.from(data['storico_gare'] ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nome': nome,
        'email': email,
        'foto_profilo': fotoProfilo,
        'bio': bio,
        'abbonamento_attivo': abbonamentoAttivo,
        'data_scadenza': dataScadenzaAbbonamento != null
            ? Timestamp.fromDate(dataScadenzaAbbonamento!)
            : null,
        'voti_extra_disponibili': votiExtraDisponibili,
        'badge': badge,
        'storico_gare': storicoGare,
        'created_at': Timestamp.fromDate(createdAt),
      };

  Artista copyWith({
    String? nome,
    String? bio,
    String? fotoProfilo,
    bool? abbonamentoAttivo,
    DateTime? dataScadenzaAbbonamento,
    int? votiExtraDisponibili,
    List<String>? badge,
    List<String>? storicoGare,
  }) =>
      Artista(
        id: id,
        nome: nome ?? this.nome,
        email: email,
        fotoProfilo: fotoProfilo ?? this.fotoProfilo,
        bio: bio ?? this.bio,
        abbonamentoAttivo: abbonamentoAttivo ?? this.abbonamentoAttivo,
        dataScadenzaAbbonamento:
            dataScadenzaAbbonamento ?? this.dataScadenzaAbbonamento,
        votiExtraDisponibili: votiExtraDisponibili ?? this.votiExtraDisponibili,
        badge: badge ?? this.badge,
        storicoGare: storicoGare ?? this.storicoGare,
        createdAt: createdAt,
      );
}
