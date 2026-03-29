import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAudio({
    required File file,
    required String artistaId,
    required String garaId,
    void Function(double progress)? onProgress,
  }) async {
    final ext = p.extension(file.path);
    final ref = _storage.ref('brani/$garaId/$artistaId$ext');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/mpeg'),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        final progress = snap.bytesTransferred / snap.totalBytes;
        onProgress(progress);
      });
    }

    await task;
    return ref.getDownloadURL();
  }

  Future<String> uploadCover({
    required File file,
    required String artistaId,
    required String garaId,
    void Function(double progress)? onProgress,
  }) async {
    final ext = p.extension(file.path);
    final ref = _storage.ref('covers/$garaId/$artistaId$ext');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        final progress = snap.bytesTransferred / snap.totalBytes;
        onProgress(progress);
      });
    }

    await task;
    return ref.getDownloadURL();
  }

  Future<String> uploadFotoProfilo({
    required File file,
    required String userId,
  }) async {
    final ext = p.extension(file.path);
    final ref = _storage.ref('profili/$userId$ext');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }

  static const int maxAudioBytes = 20 * 1024 * 1024; // 20 MB
  static const int maxImageBytes = 5 * 1024 * 1024;  // 5 MB

  Future<bool> validateAudioFile(File file) async {
    final size = await file.length();
    return size <= maxAudioBytes;
  }

  Future<bool> validateImageFile(File file) async {
    final size = await file.length();
    return size <= maxImageBytes;
  }
}
