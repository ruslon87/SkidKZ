// lib/data/services/notification_service.dart
// Сервис FCM push-уведомлений для SkidKZ
// Отвечает за:
//  1. Инициализацию firebase_messaging
//  2. Запрос разрешений (Android 13+ / iOS)
//  3. Сохранение FCM-токена устройства в Firestore
//  4. Обработку foreground-уведомлений через flutter_local_notifications
//  5. Запись входящих уведомлений в Firestore (in-app центр)
//  6. Отправку уведомлений конкретному пользователю (через Firestore-триггер)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── Background message handler (top-level, вне класса) ──────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase уже инициализирован к этому моменту
  debugPrint('[FCM] Background message: ${message.messageId}');
  // Сохраняем в Firestore чтобы in-app центр тоже обновился
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    await _saveNotificationToFirestore(uid, message);
  }
}

// ─── Вспомогательная функция сохранения (top-level для background handler) ───
Future<void> _saveNotificationToFirestore(
    String uid, RemoteMessage message) async {
  try {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .add({
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('[FCM] Ошибка сохранения уведомления: $e');
  }
}

// ─── NotificationService ──────────────────────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'skidkz_notifications';
  static const String _channelName = 'SkidKZ Уведомления';
  static const String _channelDesc =
      'Заказы, статусы, начисления и системные уведомления';

  // ── Инициализация (вызывается в main() после Firebase.initializeApp) ────────
  Future<void> initialize() async {
    // 1. Регистрируем background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Запрашиваем разрешения
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint(
        '[FCM] Статус разрешений: ${settings.authorizationStatus}');

    // 3. Инициализируем flutter_local_notifications (для foreground)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotif.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 4. Создаём Android-канал уведомлений
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

    // 5. Обработка foreground-сообщений
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Обработка нажатия на уведомление (приложение было в фоне)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // 7. Сохраняем токен текущего пользователя
    await saveTokenForCurrentUser();

    // 8. Обновляем токен при его обновлении
    _fcm.onTokenRefresh.listen((newToken) {
      _saveToken(newToken);
    });
  }

  // ── Сохранение FCM-токена в Firestore ────────────────────────────────────────
  Future<void> saveTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveToken(token);
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] Токен сохранён для uid=$uid');
    } catch (e) {
      debugPrint('[FCM] Ошибка сохранения токена: $e');
    }
  }

  // ── Удаление токена при выходе ────────────────────────────────────────────────
  Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('[FCM] Ошибка удаления токена: $e');
    }
  }

  // ── Обработка foreground-уведомления ─────────────────────────────────────────
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _saveNotificationToFirestore(uid, message);
    }

    final notification = message.notification;
    if (notification == null) return;

    await _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'],
    );
  }

  // ── Обработка нажатия на уведомление ─────────────────────────────────────────
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('[FCM] Открыто из фона: ${message.data}');
    // Навигация по route из data payload
    // Реализуется через глобальный navigatorKey если нужно
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Нажатие на local notification: ${response.payload}');
  }

  // ── Отправка уведомления конкретному пользователю ────────────────────────────
  // Записывает задачу в Firestore коллекцию fcm_tasks.
  // Cloud Function (или серверный код) читает её и отправляет через FCM Admin SDK.
  // Если Cloud Functions нет — уведомление всё равно появится в in-app центре.
  static Future<void> sendToUser({
    required String targetUid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Сохраняем в in-app центр уведомлений
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(targetUid)
          .collection('items')
          .add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Создаём задачу для Cloud Function / серверного отправщика
      await FirebaseFirestore.instance.collection('fcm_tasks').add({
        'targetUid': targetUid,
        'title': title,
        'body': body,
        'data': data ?? {},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FCM] Ошибка sendToUser: $e');
    }
  }

  // ── Отправка уведомления по теме (topic) — для рассылки всем ─────────────────
  // Подписка на топик выполняется при инициализации по роли пользователя.
  static Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('[FCM] Подписан на топик: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Отписан от топика: $topic');
  }

  // ── Подписка на топики по роли ────────────────────────────────────────────────
  static Future<void> subscribeByRoles(List<String> roles) async {
    // Все пользователи получают общие уведомления
    await subscribeToTopic('all_users');

    for (final role in roles) {
      switch (role) {
        case 'buyer':
          await subscribeToTopic('buyers');
          break;
        case 'seller':
          await subscribeToTopic('sellers');
          break;
        case 'wanghong':
          await subscribeToTopic('wanghong');
          break;
        case 'admin':
          await subscribeToTopic('admins');
          break;
      }
    }
  }

  // ── Отписка от всех топиков (при выходе) ─────────────────────────────────────
  static Future<void> unsubscribeAll(List<String> roles) async {
    await unsubscribeFromTopic('all_users');
    for (final role in roles) {
      await unsubscribeFromTopic(role == 'wanghong' ? 'wanghong' : '${role}s');
    }
  }
}
