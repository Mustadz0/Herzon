import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.messageId} ${message.notification?.title}');
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _getAndSaveToken();
    _fcm.onTokenRefresh.listen(_saveToken);
  }

  Future<void> _requestPermission() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _getAndSaveToken() async {
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final platform = Platform.isIOS ? 'ios' : 'android';
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'platform': platform,
      });
    } catch (e) { debugPrint('NotificationService: $e'); }
  }

  Future<void> deleteToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('device_tokens')
            .delete()
            .eq('user_id', user.id);
      }
    } catch (e) { debugPrint('NotificationService: $e'); }
  }
}

class NotificationTapHandler extends StatefulWidget {
  final Widget child;
  const NotificationTapHandler({super.key, required this.child});

  @override
  State<NotificationTapHandler> createState() => _NotificationTapHandlerState();
}

class _NotificationTapHandlerState extends State<NotificationTapHandler> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _handleTap(message);
  }

  void _handleTap(RemoteMessage message) {
    final data = message.data;
    if (!mounted) return;
    if (data['post_id'] != null) {
      Navigator.of(context).pushNamed('/comments', arguments: data['post_id']);
    } else if (data['follower_id'] != null) {
      Navigator.of(context).pushNamed('/profile', arguments: data['follower_id']);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
