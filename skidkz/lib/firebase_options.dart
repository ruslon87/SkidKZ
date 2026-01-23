// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for this project.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS is not configured for this project.');
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS is not configured for this project.');
      case TargetPlatform.windows:
        throw UnsupportedError('windows is not configured for this project.');
      case TargetPlatform.linux:
        throw UnsupportedError('linux is not configured for this project.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  /// Заполни значениями из android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PASTE_API_KEY_HERE',
    appId: 'PASTE_MOBILESDK_APP_ID_HERE',
    messagingSenderId: 'PASTE_PROJECT_NUMBER_HERE',
    projectId: 'PASTE_PROJECT_ID_HERE',
    storageBucket: 'PASTE_STORAGE_BUCKET_HERE',
  );
}
