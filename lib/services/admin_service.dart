import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gara.dart';
import '../models/brano.dart';

/// Servizio admin per operazioni di amministrazione e seed dati di test.
/// NON usare in produzione — solo per sviluppo e test.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _rnd = Random();

  // ── URL di test ────────────────────────────────────────────────────
  // MP3 pubblico di test (SoundHelix)
  static const _audioUrls = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  ];

  // Cover placeholder (picsum.photos — immagini diverse per ogni seed)
  String _coverUrl(int seed) =>
      'https://picsum.photos/seed/rise$seed/500/500';

  // ── Dati fittizi per genere ────────────────────────────────────────

  static const _brani = {
    'indie': [
      ('Marco Riva', 'Notte di Maggio', 'Indie-folk con chitarre acustiche e voci stratificate.'),
      ('Sofia Lenti', 'Confini', 'Un viaggio sonoro tra ricordi e aspettative.'),
      ('The Drifters IT', 'Oltre il Muro', 'Post-rock italiano con testi introspettivi.'),
      ('Luca Santi', 'Radici Profonde', 'Cantautorato indie con influenze folk.'),
      ('Elena Voss', 'Città di Vetro', 'Dream pop con synth eterei e liriche urbane.'),
    ],
    'hiphop': [
      ('MC Ferro', 'Freestyle Libertà', 'Rap conscio sulla libertà di espressione.'),
      ('Dario Flow', 'Strade di Notte', 'Trap italiana con beat cinematici.'),
      ('Kira Beats', 'Rise Up', 'Hip hop femminile con flow tecnico.'),
      ('Urban Kings', 'La Nostra Storia', 'Crew rap con storytelling di strada.'),
      ('Nino Spada', 'Zero a Cento', 'Drill italiana produzione dark.'),
    ],
    'pop': [
      ('Valentina Mori', 'Cuore Libero', 'Pop melodico con arrangiamenti orchestrali.'),
      ('Fabio Stelle', 'Domani', 'Ballad pop con piano e voce.'),
      ('Luna Nova', 'Brillare', 'Synth-pop con energia estiva.'),
      ('Alex Romano', 'Per Sempre', 'Pop romantico con chorus potente.'),
      ('Sara Fiore', 'Nuova Luce', 'Pop elettronico con sfumature R&B.'),
    ],
    'rock': [
      ('The Iron Fist', 'Rompi le Catene', 'Hard rock con riff distorto e voce graffiante.'),
      ('Rebel Storm', 'Fuoco Vivo', 'Alternative rock con energia live.'),
      ('Carlo Nero', 'Ribelle', 'Rock classico con assoli di chitarra.'),
      ('Voltage', 'Tempesta', 'Heavy rock con batteria potente.'),
      ('Marta Ferro', 'Senza Paura', 'Punk rock femminile con testi diretti.'),
    ],
    'elettronica': [
      ('DJ Nexus', 'Frequenze Libere', 'Techno minimalista con bassline ipnotica.'),
      ('Syntwave IT', 'Neon Dreams', 'Synthwave con estetica retrofuturistica.'),
      ('Elara', 'Algoritmo', 'Ambient elettronica con field recordings.'),
      ('BassCore', 'Drop Zero', 'Bass music con influenze dubstep.'),
      ('NightPulse', 'After Dark', 'House music con atmosfera notturna.'),
    ],
    'world': [
      ('Afro Roma', 'Tamburi del Sud', 'Fusion afrobeat e tradizione italiana.'),
      ('Tarantella Nova', 'Terra Mia', 'Folk del sud rivisitato in chiave moderna.'),
      ('Giulia Medina', 'Flamenco Libero', 'Fusione flamenco-jazz con voce italiana.'),
      ('Orient Express IT', 'Via della Seta', 'World music con strumenti mediorientali.'),
      ('Bossa Nova Roma', 'Carioca', 'Bossa nova cantata in italiano.'),
    ],
  };

  // ── Seed gara di test ─────────────────────────────────────────────

  /// Crea una gara di test per Aprile 2026 con 30 brani (5 per genere).
  /// Lancia eccezione se la gara esiste già.
  Future<String> seedGaraTest() async {
    const mese = 4;
    const anno = 2026;

    // Rimuovi gara esistente se presente
    final esistente = await _db
        .collection('gare')
        .where('mese', isEqualTo: mese)
        .where('anno', isEqualTo: anno)
        .get();

    for (final doc in esistente.docs) {
      // Elimina brani associati
      final brani = await _db
          .collection('brani_in_gara')
          .where('gara_id', isEqualTo: doc.id)
          .get();
      final batch = _db.batch();
      for (final b in brani.docs) {
        batch.delete(b.reference);
      }
      batch.delete(doc.reference);
      await batch.commit();
    }

    // Crea gara
    final garaRef = _db.collection('gare').doc();
    final gara = Gara(
      id: garaRef.id,
      mese: mese,
      anno: anno,
      tema: 'Libertà',
      temaDescrizione:
          'Esprimi il tuo significato di libertà attraverso la musica.',
      stato: StatoGara.gironi,
      montepremitotale: 0,
      numeroIscritti: 0,
      dataInizio: DateTime(anno, mese, 1),
      dataFine: DateTime(anno, mese, 30, 23, 59),
      dataInizioIscrizioni: DateTime(anno, mese, 1),
      dataFineIscrizioni: DateTime(anno, mese, 7, 23, 59),
      dataInizioGironi: DateTime(anno, mese, 8),
    );
    await garaRef.set(gara.toFirestore());

    // Crea 30 brani (5 per genere)
    int seed = 1;
    int totalIscritti = 0;
    final batch = _db.batch();

    for (final entry in _brani.entries) {
      final genere = entry.key;
      final lista = entry.value;
      for (final (artista, titolo, bio) in lista) {
        final voti = 100 + _rnd.nextInt(4901); // 100–5000
        final branoRef = _db.collection('brani_in_gara').doc();
        final brano = Brano(
          id: branoRef.id,
          garaId: garaRef.id,
          artistaId: 'test_${artista.replaceAll(' ', '_').toLowerCase()}',
          artistaNome: artista,
          titolo: titolo,
          urlAudio: _audioUrls[seed % _audioUrls.length],
          urlCover: _coverUrl(seed),
          bio: bio,
          genere: genere,
          faseAttuale: 'gironi',
          votiTotali: voti,
          posizioneAttuale: 0,
          posizionePrecedente: 0,
          eliminato: false,
          dataIscrizione: DateTime(anno, mese, 1 + _rnd.nextInt(7)),
        );
        batch.set(branoRef, brano.toFirestore());
        seed++;
        totalIscritti++;
      }
    }

    // Aggiorna n_iscritti e montepremi
    batch.update(garaRef, {
      'n_iscritti': totalIscritti,
      'montepremi_totale': totalIscritti * 2.0 * 0.70,
    });

    await batch.commit();

    // Aggiorna posizioni classifica
    await _aggiornaPosizioniSeed(garaRef.id);

    return garaRef.id;
  }

  Future<void> _aggiornaPosizioniSeed(String garaId) async {
    final snap = await _db
        .collection('brani_in_gara')
        .where('gara_id', isEqualTo: garaId)
        .get();

    final brani = snap.docs.map(Brano.fromFirestore).toList();
    brani.sort((a, b) => b.votiTotali.compareTo(a.votiTotali));

    final batch = _db.batch();
    for (int i = 0; i < brani.length; i++) {
      batch.update(
        _db.collection('brani_in_gara').doc(brani[i].id),
        {
          'posizione_attuale': i + 1,
          'posizione_precedente': i + 1,
        },
      );
    }
    await batch.commit();
  }
}
