import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message received while app is terminated or in background
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'taj_reminders',
    'تذكيرات تاج دنتكس',
    description: 'إشعارات تذكير الجلسات والاستبيانات ومستحقات الدفع',
    importance: Importance.max,
    playSound: true,
  );

  bool _initialized = false;
  bool _firebaseAvailable = false;
  String? _currentToken;

  bool get isAvailable => _firebaseAvailable;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Safe Firebase initialization (Graceful fallback if google-services.json not yet dropped)
    try {
      await Firebase.initializeApp();
      _firebaseAvailable = true;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Firebase initialize skipped or pending configuration: $e');
      _initialized = true;
      return;
    }

    // 2. Initialize Flutter Local Notifications for foreground heads-up banner
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleNavigation(payload);
        }
      },
    );

    // Create high importance notification channel on Android
    final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(_channel);
    }

    // 3. Request permissions from user
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Listen to token registration stream
    messaging.onRegistered.listen((token) {
      _currentToken = token;
      _sendTokenToBackend(token);
    });

    // 4. Foreground notifications handler (show local notification when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        final route = message.data['route'] as String? ?? '/home';
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
            ),
          ),
          payload: route,
        );
      }
    });

    // 5. Handle notification click when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data['route'] as String?;
      if (route != null) {
        _handleNavigation(route);
      }
    });

    // 6. Handle cold start notification tap
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      final route = initialMessage.data['route'] as String?;
      if (route != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNavigation(route);
        });
      }
    }

    _initialized = true;
  }

  /// Register or refresh device FCM token with Supabase backend
  Future<void> registerDeviceToken() async {
    if (!_firebaseAvailable) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.register();
    } catch (e) {
      debugPrint('Failed to register FCM: $e');
    }
  }

  /// Cleanly unregister device token on logout
  Future<void> unregisterDeviceToken() async {
    if (!_firebaseAvailable) return;

    try {
      final messaging = FirebaseMessaging.instance;
      if (_currentToken != null) {
        final client = Supabase.instance.client;
        await client
            .from('user_fcm_tokens')
            .delete()
            .eq('fcm_token', _currentToken!);
      }

      await messaging.unregister();
      _currentToken = null;
    } catch (e) {
      debugPrint('Failed to unregister FCM token on logout: $e');
    }
  }

  Future<void> _sendTokenToBackend(String fcmToken) async {
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return;

    final deviceType = kIsWeb
        ? 'web'
        : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'android'));

    await client.rpc('register_fcm_token', params: {
      'p_fcm_token': fcmToken,
      'p_device_type': deviceType,
      'p_device_id': null,
    });
  }

  void _handleNavigation(String route) {
    const allowedRoutes = [
      '/home',
      '/payments',
      '/surveys',
      '/courses',
      '/course-materials',
    ];

    if (allowedRoutes.contains(route)) {
      AppRouter.router.push(route);
    }
  }
}
