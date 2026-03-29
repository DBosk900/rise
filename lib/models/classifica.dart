import 'brano.dart';

class RigaClassifica {
  final int posizione;
  final Brano brano;
  final int variazioneRank;

  const RigaClassifica({
    required this.posizione,
    required this.brano,
    required this.variazioneRank,
  });
}

class Classifica {
  final String garaId;
  final String genere;
  final List<RigaClassifica> righe;
  final DateTime ultimoAggiornamento;

  const Classifica({
    required this.garaId,
    required this.genere,
    required this.righe,
    required this.ultimoAggiornamento,
  });

  static Classifica fromBrani(
    String garaId,
    String genere,
    List<Brano> brani,
    DateTime aggiornamento,
  ) {
    final sorted = [...brani]
      ..sort((a, b) => b.votiTotali.compareTo(a.votiTotali));

    final righe = sorted.asMap().entries.map((e) {
      return RigaClassifica(
        posizione: e.key + 1,
        brano: e.value,
        variazioneRank: e.value.variazioneRank,
      );
    }).toList();

    return Classifica(
      garaId: garaId,
      genere: genere,
      righe: righe,
      ultimoAggiornamento: aggiornamento,
    );
  }
}
