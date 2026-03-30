import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/voto.dart';
import '../services/voto_service.dart';

class VotiProvider extends ChangeNotifier {
  final VotoService _service = VotoService();

  StatoVoti? _stato;
  bool _loading = false;
  String? _lastError;
  int _votiConsecutivi = 0;

  StreamSubscription<StatoVoti>? _statoSubscription;

  StatoVoti? get stato => _stato;
  bool get loading => _loading;
  String? get lastError => _lastError;
  int get votiConsecutivi => _votiConsecutivi;

  @override
  void dispose() {
    _statoSubscription?.cancel();
    super.dispose();
  }

  Future<void> caricaStato(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      _stato = await _service.getStatoVoti(userId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Avvia ascolto real-time dello stato voti. Cancella la subscription
  /// precedente se esistente.
  void ascoltaStato(String userId) {
    _statoSubscription?.cancel();
    _statoSubscription = _service.statoVotiStream(userId).listen(
      (stato) {
        _stato = stato;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('VotiProvider: stream error: $e');
      },
    );
  }

  Future<VotoResult> vota({
    required String userId,
    required String branoId,
    required String garaId,
  }) async {
    _lastError = null;

    final result = await _service.votaBrano(
      userId: userId,
      branoId: branoId,
      garaId: garaId,
    );

    if (result.success) {
      _votiConsecutivi++;
      // Aggiornamento ottimistico locale in attesa del listener
      if (_stato != null) {
        final gratuiti = _stato!.votiGratuiRimasti;
        if (gratuiti > 0) {
          _stato = StatoVoti(
            votiGratuiRimasti: gratuiti - 1,
            votiExtraDisponibili: _stato!.votiExtraDisponibili,
            prossimoReset: _stato!.prossimoReset,
          );
        } else {
          _stato = StatoVoti(
            votiGratuiRimasti: 0,
            votiExtraDisponibili: _stato!.votiExtraDisponibili - 1,
            prossimoReset: _stato!.prossimoReset,
          );
        }
      }
    } else {
      _lastError = result.error;
    }

    notifyListeners();
    return result;
  }

  void resetVotiConsecutivi() {
    _votiConsecutivi = 0;
  }

  bool get deveMonstrareInterstitial =>
      _votiConsecutivi > 0 && _votiConsecutivi % 3 == 0;
}
