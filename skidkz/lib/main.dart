import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:skidkz/app.dart';
import 'package:skidkz/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Ловим все Flutter-ошибки
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // 2) Ловим все async-ошибки (включая те, что до первого кадра)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('UNCAUGHT (PlatformDispatcher): $error');
    debugPrint('$stack');
    return true; // ошибка обработана, чтобы не убивало процесс молча
  };

  // 3) Инициализация Firebase (частая причина "висит на сплеше")
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized OK');
  } catch (e, st) {
    debugPrint('Firebase initialize FAILED: $e');
    debugPrint('$st');
  }

  // 4) Запуск приложения
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
