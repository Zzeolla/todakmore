import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmTokenService {
  FcmTokenService(this._supabase);
  final SupabaseClient _supabase;

  StreamSubscription<String>? _refreshSub;

  Future<void> register(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await _supabase.from('user_device_tokens').upsert({
      'user_id': userId,
      'fcm_token': token,
      'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web'),
      'last_seen_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,fcm_token');
  }

  void listenRefresh(String userId) {
    // 중복 등록 방지: 기존 구독이 있으면 유지 (또는 cancel 후 재구독)
    _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _supabase.from('user_device_tokens').upsert({
        'user_id': userId,
        'fcm_token': newToken,
        'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web'),
        'last_seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,fcm_token');
    });
  }

  Future<void> unregister(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await _supabase
        .from('user_device_tokens')
        .delete()
        .match({'user_id': userId, 'fcm_token': token});
  }

  Future<void> stop() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
  }
}
