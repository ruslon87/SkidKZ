// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBBSeBp5ZGxJrcryDofRPR1J2J8l0KNkPg',
    appId: '1:793305921663:android:680dbd80f9ceb67a82a74a',
    messagingSenderId: '793305921663',
    projectId: 'skidkz',
    storageBucket: 'skidkz.firebasestorage.app',
  );
}
