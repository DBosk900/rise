import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdmobBanner extends StatefulWidget {
  const AdmobBanner({super.key});

  @override
  State<AdmobBanner> createState() => _AdmobBannerState();
}

class _AdmobBannerState extends State<AdmobBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  String get _bannerId {
    if (Platform.isIOS) {
      return dotenv.env['ADMOB_BANNER_ID_IOS'] ?? '';
    }
    return dotenv.env['ADMOB_BANNER_ID_ANDROID'] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (_bannerId.isEmpty) return;
    _ad = BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}

class AdmobInterstitialHelper {
  InterstitialAd? _ad;
  bool _loaded = false;

  String get _id {
    if (Platform.isIOS) {
      return dotenv.env['ADMOB_INTERSTITIAL_ID_IOS'] ?? '';
    }
    return dotenv.env['ADMOB_INTERSTITIAL_ID_ANDROID'] ?? '';
  }

  Future<void> load() async {
    if (_id.isEmpty) return;
    await InterstitialAd.load(
      adUnitId: _id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loaded = true;
        },
        onAdFailedToLoad: (_) => _loaded = false,
      ),
    );
  }

  void showIfReady() {
    if (_loaded && _ad != null) {
      _ad!.show();
      _loaded = false;
      _ad = null;
    }
  }

  void dispose() {
    _ad?.dispose();
  }
}
