import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/gara.dart';
import '../models/brano.dart';
import '../services/gara_service.dart';

class GaraProvider extends ChangeNotifier {
  final GaraService _service = GaraService();

  Gara? _garaAttiva;
  List<Brano> _brani = [];
  List<String> _generi = [];
  bool _loading = false;
  String? _error;

  StreamSubscription<Gara?>? _garaSubscription;
  StreamSubscription<List<Brano>>? _braniSubscription;

  Gara? get garaAttiva => _garaAttiva;
  List<Brano> get brani => _brani;
  List<String> get generi => _generi;
  bool get loading => _loading;
  String? get error => _error;

  List<Brano> get top3 {
    final sorted = [..._brani]
      ..sort((a, b) => b.votiTotali.compareTo(a.votiTotali));
    return sorted.take(3).toList();
  }

  @override
  void dispose() {
    _garaSubscription?.cancel();
    _braniSubscription?.cancel();
    super.dispose();
  }

  /// Avvia ascolto real-time della gara attiva e dei suoi brani.
  void ascoltaGaraAttiva() {
    _loading = true;
    _error = null;
    notifyListeners();

    _garaSubscription?.cancel();
    _garaSubscription = _service.getGaraAttiva().listen(
      (gara) async {
        _garaAttiva = gara;
        _loading = false;
        if (gara != null) {
          _ascoltaBrani(gara.id);
          try {
            _generi = await _service.getGeneriDisponibili(gara.id);
          } catch (_) {}
        } else {
          _brani = [];
          _generi = [];
        }
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  void _ascoltaBrani(String garaId, {String? genere}) {
    _braniSubscription?.cancel();
    _braniSubscription = _service.braniPerGaraStream(garaId, genere: genere).listen(
      (brani) {
        _brani = brani;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  /// Caricamento one-shot (per compatibilità con codice esistente)
  Future<void> caricaGaraAttiva() async {
    if (_garaSubscription != null) return; // già in ascolto
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _garaAttiva = await _service.getGaraAttivaOnce();
      if (_garaAttiva != null) {
        _generi = await _service.getGeneriDisponibili(_garaAttiva!.id);
        await caricaBrani();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> caricaBrani({String? genere}) async {
    if (_garaAttiva == null) return;
    try {
      _brani = await _service.getBraniPerGara(
        _garaAttiva!.id,
        genere: genere,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Stream<List<Brano>> braniStream({String? genere}) {
    if (_garaAttiva == null) return const Stream.empty();
    return _service.braniPerGaraStream(_garaAttiva!.id, genere: genere);
  }

  Stream<Gara?> garaAttivaStream() => _service.getGaraAttiva();
}
