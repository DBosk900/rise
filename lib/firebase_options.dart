// Generato manualmente da GoogleService-Info.plist (iOS) e google-services.json (Android)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web non è una piattaforma supportata da RISE.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Piattaforma $defaultTargetPlatform non supportata.',
        );
    }
  }

  // Valori da ios/Runner/GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-2f1Kv8vmZT8Xo33F0XObNSEgtCivQxE',
    appId: '1:248112652755:ios:5a2fe52f4ef48c43870f26',
    messagingSenderId: '248112652755',
    projectId: 'rise-2cc37',
    storageBucket: 'rise-2cc37.firebasestorage.app',
    iosClientId:
        '248112652755-4kk5c65u7at2r7snb759or4mrrc2p720.apps.googleusercontent.com',
    iosBundleId: 'com.dbosk.rise',
  );

  // Valori da android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCVRN3bY5c6Y8YoaV2veR6KJy01fKdEzlw',
    appId: '1:248112652755:android:24d7f12da5b99716870f26',
    messagingSenderId: '248112652755',
    projectId: 'rise-2cc37',
    storageBucket: 'rise-2cc37.firebasestorage.app',
  );
}
