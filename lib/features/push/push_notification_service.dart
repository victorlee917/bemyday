import 'dart:io';

import 'package:bemyday/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 백그라운드 메시지 핸들러 (top-level 필수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// FCM 초기화, 토큰 등록, 메시지 핸들러
class PushNotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'bemyday_push';
  static const _channelName = 'Be My Day';

  static Future<void> initialize() async {
    // main()에서 이미 초기화됨. 백그라운드 핸들러는 별도 isolate에서 자체 초기화.

    // 포그라운드 메시지 표시용 로컬 알림
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.high,
            ),
          );
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 권한 요청
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 포그라운드 메시지 핸들러
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드/종료 상태에서 탭하여 열림
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 앱 종료 상태에서 알림 탭으로 실행된 경우
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen(_registerToken);

    // 초기 토큰 등록 (iOS: APNS 토큰 대기 후 getToken)
    final token = await _getFcmToken();
    if (token != null) await _registerToken(token);
  }

  static Future<String?> _getFcmToken() async {
    try {
      if (Platform.isIOS) {
        // iOS: APNS 토큰이 준비될 때까지 대기 (시뮬레이터에서는 미지원)
        for (var i = 0; i < 5; i++) {
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      return _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // payload로 화면 이동 등 처리 가능
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'Be My Day',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    // data.payload 등으로 딥링크 처리 가능
  }

  static Future<void> _registerToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await Supabase.instance.client.from('device_tokens').upsert(
            {
              'user_id': userId,
              'token': token,
              'platform': platform,
            },
            onConflict: 'token',
          );
    } catch (_) {
      // RLS 등으로 실패 시 무시
    }
  }

  /// 로그인 시 호출 (토큰 재등록)
  static Future<void> registerTokenIfNeeded() async {
    final token = await _getFcmToken();
    if (token != null) await _registerToken(token);
  }

  /// 로그아웃 시 호출 (토큰 삭제)
  static Future<void> unregisterToken() async {
    final token = await _getFcmToken();
    if (token == null) return;

    try {
      await Supabase.instance.client
          .from('device_tokens')
          .delete()
          .eq('token', token);
    } catch (_) {}
  }
}
