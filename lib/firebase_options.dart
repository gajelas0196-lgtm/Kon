import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Konfigurasi Firebase untuk Project: manta-app-4b648
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBq15TvFR_R1oKQBCm2Y-6xRqDVDpQQ1qI',
    appId: '1:724138431204:android:38564c43def3cb68c692f1',
    messagingSenderId: '724138431204',
    projectId: 'manta-app-4b648',
    storageBucket: 'manta-app-4b648.firebasestorage.app',
    databaseURL: 'https://manta-app-4b648-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBq15TvFR_R1oKQBCm2Y-6xRqDVDpQQ1qI',
    appId: '1:724138431204:android:38564c43def3cb68c692f1',
    messagingSenderId: '724138431204',
    projectId: 'manta-app-4b648',
    storageBucket: 'manta-app-4b648.firebasestorage.app',
    databaseURL: 'https://manta-app-4b648-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}