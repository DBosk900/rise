import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificaService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const _keyVotiEnabled = 'notif_voti';
  static const _keyGaraEnabled = 'notif_gara';
  static const _keyClassificaEnabled = 'notif_classifica';

  Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
        'NotificaService: autorizzazione = ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
          'Notifica in foreground: ${message.notification?.title}');
    });
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<void> iscriviTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('NotificaService: iscritto a $topic');
  }

  Future<void> disiscriviTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('NotificaService: disinscritto da $topic');
  }

  // ── Preferenze notifiche (persistite in SharedPreferences) ──────────

  Future<bool> isVotiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVotiEnabled) ?? true;
  }

  Future<bool> isGaraEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGaraEnabled) ?? true;
  }

  Future<bool> isClassificaEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyClassificaEnabled) ?? true;
  }

  Future<void> setVotiEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVotiEnabled, val);
    if (val) {
      await iscriviTopic('voti');
    } else {
      await disiscriviTopic('voti');
    }
  }

  Future<void> setGaraEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGaraEnabled, val);
    if (val) {
      await iscriviTopic('gara');
    } else {
      await disiscriviTopic('gara');
    }
  }

  Future<void> setClassificaEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyClassificaEnabled, val);
    if (val) {
      await iscriviTopic('classifica');
    } else {
      await disiscriviTopic('classifica');
    }
  }
}
