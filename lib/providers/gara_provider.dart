import 'package:flutter/foundation.dart';
import '../models/gara.dart';
import '../models/brano.dart';
import '../services/gara_service.dart';

class GaraProvider extends ChangeNotifier {
  final GaraService _service = GaraService();

  Gara? _garaAttiva;
  List<Brano> _brani = [];
  List<String> _generi = [];
  String? _genereSelezionato;
  bool _loading = false;
  String? _error;

  Gara? get garaAttiva => _garaAttiva;
  List<Brano> get brani => _brani;
  List<String> get generi => _generi;
  String? get genereSelezionato => _genereSelezionato;
  bool get loading => _loading;
  String? get error => _error;

  List<Brano> get top3 {
    final sorted = [..._brani]
      ..sort((a, b) => b.votiTotali.compareTo(a.votiTotali));
    return sorted.take(3).toList();
  }

  Future<void> caricaGaraAttiva() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _garaAttiva = await _service.getGaraAttiva();
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

  void selezionaGenere(String? genere) {
    _genereSelezionato = genere;
    caricaBrani(genere: genere);
  }

  Stream<List<Brano>> braniStream({String? genere}) {
    if (_garaAttiva == null) return const Stream.empty();
    return _service.braniPerGaraStream(_garaAttiva!.id, genere: genere);
  }

  Stream<Gara?> garaAttivaStream() => _service.garaAttivaStream();
}
