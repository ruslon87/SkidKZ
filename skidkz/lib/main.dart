import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:skidkz/app.dart';
import 'package:skidkz/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('UNCAUGHT (PlatformDispatcher): $error');
    debugPrint('$stack');
    return true;
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized OK');
  } catch (e, st) {
    debugPrint('Firebase initialize FAILED: $e');
    debugPrint('$st');
  }

  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: SkidKZApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('UNCAUGHT (Zone): $error');
    debugPrint('$stack');
  });
}
