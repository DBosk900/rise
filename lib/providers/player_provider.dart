import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/brano.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Brano? _branoCorrente;
  bool _playing = false;
  bool _loading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Brano? get branoCorrente => _branoCorrente;
  bool get playing => _playing;
  bool get loading => _loading;
  bool get hasBrano => _branoCorrente != null;
  Duration get position => _position;
  Duration get duration => _duration;
  AudioPlayer get player => _player;

  PlayerProvider() {
    _player.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    _player.durationStream.listen((d) {
      if (d != null) {
        _duration = d;
        notifyListeners();
      }
    });
    _player.playerStateStream.listen((s) {
      _playing = s.playing;
      _loading = s.processingState == ProcessingState.loading ||
          s.processingState == ProcessingState.buffering;
      notifyListeners();
    });
  }

  Future<void> play(Brano brano) async {
    if (_branoCorrente?.id == brano.id) {
      // Stesso brano: toggle play/pause
      if (_playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    _branoCorrente = brano;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();

    try {
      await _player.stop();
      await _player.setUrl(brano.urlAudio);
      await _player.play();
    } catch (e) {
      debugPrint('PlayerProvider: errore audio $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void stop() {
    _player.stop();
    _branoCorrente = null;
    _playing = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
