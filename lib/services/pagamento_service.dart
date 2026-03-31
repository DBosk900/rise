import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PagamentoService {
  static const String _entitlementArtista = 'rise_artista';
  static const String _abbonamentoId = 'rise_artista_monthly_599';

  // Chiavi API RevenueCat
  static const String _iosKey = 'appl_ylXuIIpGyriVYAAZGSJUNMHwyhi';
  static const String _androidKey = 'goog_pMMqNxJpAgvfynOtPFcQXJcnQSW';

  Future<void> initialize() async {
    try {
      // Usa chiave da .env se disponibile, altrimenti usa quella hardcoded
      final apiKey = Platform.isIOS
          ? (dotenv.env['REVENUECAT_API_KEY_IOS']?.isNotEmpty == true
              ? dotenv.env['REVENUECAT_API_KEY_IOS']!
              : _iosKey)
          : (dotenv.env['REVENUECAT_API_KEY_ANDROID']?.isNotEmpty == true
              ? dotenv.env['REVENUECAT_API_KEY_ANDROID']!
              : _androidKey);

      await Purchases.configure(PurchasesConfiguration(apiKey));
      debugPrint('PagamentoService: RevenueCat configurato');
    } catch (e) {
      debugPrint('PagamentoService: errore configurazione: $e');
    }
  }

  /// Verifica se l'abbonamento artista è attivo tramite RevenueCat.
  Future<bool> haAbbonamentoAttivo() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_entitlementArtista);
    } catch (e) {
      debugPrint('PagamentoService.haAbbonamentoAttivo: $e');
      return false;
    }
  }

  /// Acquista l'abbonamento artista.
  /// Restituisce [ok, errorMessage].
  Future<(bool, String?)> acquistaAbbonamentoArtista() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;
      if (offering == null) {
        return (false, 'Nessuna offerta disponibile. Riprova più tardi.');
      }

      // Cerca il pacchetto abbonamento mensile artista
      Package? package;
      try {
        package = offering.availablePackages.firstWhere(
          (p) => p.storeProduct.identifier == _abbonamentoId,
        );
      } catch (_) {
        // Fallback al pacchetto mensile o al primo disponibile
        package = offering.monthly ?? offering.availablePackages.firstOrNull;
      }

      if (package == null) {
        return (false, 'Pacchetto abbonamento non trovato.');
      }

      final info = await Purchases.purchasePackage(package);
      final attivo = info.entitlements.active.containsKey(_entitlementArtista);
      return (attivo, attivo ? null : 'Abbonamento non attivato. Contatta il supporto.');
    } on PurchasesErrorCode catch (e) {
      return (false, _mapPurchasesError(e));
    } catch (e) {
      return (false, 'Errore imprevisto: $e');
    }
  }

  /// Acquista voti extra (5 voti).
  Future<(bool, String?)> acquistaVotiExtra5() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;
      if (offering == null) {
        return (false, 'Nessuna offerta disponibile.');
      }

      final package = offering.availablePackages.firstWhere(
        (p) => p.storeProduct.identifier == 'rise_voti_extra_5_099',
        orElse: () => offering.availablePackages.first,
      );

      await Purchases.purchasePackage(package);
      return (true, null);
    } on PurchasesErrorCode catch (e) {
      return (false, _mapPurchasesError(e));
    } catch (e) {
      return (false, 'Errore imprevisto: $e');
    }
  }

  Future<void> restoreAcquisti() async {
    await Purchases.restorePurchases();
  }

  Future<void> identificaUtente(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('PagamentoService.identificaUtente: $e');
    }
  }

  Future<void> logout() async {
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  String _mapPurchasesError(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Acquisto annullato.';
      case PurchasesErrorCode.storeProblemError:
        return 'Problema con l\'App Store. Riprova più tardi.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Acquisti non abilitati su questo dispositivo.';
      case PurchasesErrorCode.purchaseInvalidError:
        return 'Acquisto non valido. Controlla il metodo di pagamento.';
      case PurchasesErrorCode.networkError:
        return 'Errore di rete. Verifica la connessione.';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'Ricevuta già in uso. Prova a ripristinare gli acquisti.';
      default:
        return 'Errore nell\'acquisto. Riprova più tardi.';
    }
  }
}
