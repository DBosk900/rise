import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class PagamentoService {
  static const String _abbonamentoId = 'rise_artista_monthly_599';
  static const String _votiExtra5Id = 'rise_voti_extra_5_099';

  Future<void> initialize() async {
    final apiKey = Platform.isIOS
        ? dotenv.env['REVENUECAT_API_KEY_IOS'] ?? ''
        : dotenv.env['REVENUECAT_API_KEY_ANDROID'] ?? '';

    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  Future<bool> acquistaAbbonamentoArtista() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;
      if (offering == null) return false;

      final package = offering.availablePackages.firstWhere(
        (p) => p.storeProduct.identifier == _abbonamentoId,
        orElse: () => offering.monthly ?? offering.availablePackages.first,
      );

      final info = await Purchases.purchasePackage(package);
      return info.entitlements.active.containsKey('artista');
    } on PurchasesErrorCode catch (_) {
      return false;
    }
  }

  Future<bool> acquistaVotiExtra5() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;
      if (offering == null) return false;

      final package = offering.availablePackages.firstWhere(
        (p) => p.storeProduct.identifier == _votiExtra5Id,
      );

      await Purchases.purchasePackage(package);
      return true;
    } on PurchasesErrorCode catch (_) {
      return false;
    }
  }

  Future<bool> haAbbonamentoAttivo() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('artista');
    } catch (_) {
      return false;
    }
  }

  Future<void> restoreAcquisti() async {
    await Purchases.restorePurchases();
  }

  Future<void> identificaUtente(String userId) async {
    await Purchases.logIn(userId);
  }

  Future<void> logout() async {
    await Purchases.logOut();
  }
}
