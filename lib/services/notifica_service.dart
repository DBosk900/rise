import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestisce permessi, topic e preferenze notifiche push (Firebase Messaging).
class NotificaService {
  static final NotificaService _instance = NotificaService._internal();
  factory NotificaService() => _instance;
  NotificaService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ── Chiavi SharedPreferences ─────────────────────────────────────────
  static const _keyVotiEnabled = 'notif_voti';
  static const _keyGaraEnabled = 'notif_gara';
  static const _keyClassificaEnabled = 'notif_classifica';

  // ── Init (chiamato da main.dart dopo Firebase.initializeApp) ─────────

  Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
        'NotificaService: autorizzazione = ${settings.authorizationStatus}');

    // Gestione messaggi in foreground
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Notifica foreground: ${message.notification?.title}');
    });

    // Sottoscrivi automaticamente ai topic base
    await subscribeNuovaGara();
    await subscribeFinale();
  }

  Future<String?> getToken() => _messaging.getToken();

  // ── Topic base ────────────────────────────────────────────────────────

  /// Nuova gara mensile aperta
  Future<void> subscribeNuovaGara() =>
      _messaging.subscribeToTopic('nuova_gara');

  /// Inizio fase finale
  Future<void> subscribeFinale() =>
      _messaging.subscribeToTopic('finale');

  /// Aggiornamento classifica
  Future<void> subscribeClassifica() =>
      _messaging.subscribeToTopic('classifica_update');

  Future<void> unsubscribeClassifica() =>
      _messaging.unsubscribeFromTopic('classifica_update');

  // ── Topic per-utente ─────────────────────────────────────────────────

  /// Notifica eliminazione per un utente specifico
  Future<void> subscribeEliminazione(String userId) =>
      _messaging.subscribeToTopic('elim_$userId');

  Future<void> unsubscribeEliminazione(String userId) =>
      _messaging.unsubscribeFromTopic('elim_$userId');

  /// Notifica vittoria per un utente specifico
  Future<void> subscribeVincitore(String userId) =>
      _messaging.subscribeToTopic('vince_$userId');

  Future<void> unsubscribeVincitore(String userId) =>
      _messaging.unsubscribeFromTopic('vince_$userId');

  /// Notifica voti ricevuti per un artista
  Future<void> subscribeVotiArtista(String userId) =>
      _messaging.subscribeToTopic('voti_$userId');

  Future<void> unsubscribeVotiArtista(String userId) =>
      _messaging.unsubscribeFromTopic('voti_$userId');

  // ── Helper generico ──────────────────────────────────────────────────

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
      await subscribeNuovaGara();
    } else {
      await disiscriviTopic('nuova_gara');
    }
  }

  Future<void> setClassificaEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyClassificaEnabled, val);
    if (val) {
      await subscribeClassifica();
    } else {
      await unsubscribeClassifica();
    }
  }
}
