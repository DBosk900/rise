import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/gara_provider.dart';
import 'providers/voti_provider.dart';
import 'providers/player_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/notifica_service.dart';
import 'services/pagamento_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('RISE: Starting...');

  // Carica .env
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('RISE: .env loaded');
  } catch (e) {
    debugPrint('RISE: ENV error: $e');
  }

  // Inizializza Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('RISE: Firebase ready');
  } catch (e) {
    debugPrint('RISE: Firebase error: $e');
  }

  // Inizializza AdMob
  try {
    await MobileAds.instance.initialize();
    debugPrint('RISE: AdMob ready');
  } catch (e) {
    debugPrint('RISE: AdMob error: $e');
  }

  // Inizializza RevenueCat
  try {
    await PagamentoService().initialize();
    debugPrint('RISE: RevenueCat ready');
  } catch (e) {
    debugPrint('RISE: RevenueCat error: $e');
  }

  // Inizializza notifiche push
  try {
    await NotificaService().init();
    debugPrint('RISE: Notifiche ready');
  } catch (e) {
    debugPrint('RISE: Notifiche error: $e');
  }

  debugPrint('RISE: runApp');

  // Nota: il progetto usa il pacchetto "provider", non Riverpod.
  // ProviderScope è Riverpod — qui si usa MultiProvider.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GaraProvider()),
        ChangeNotifierProvider(create: (_) => VotiProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: const RiseApp(),
    ),
  );
}

class RiseApp extends StatelessWidget {
  const RiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('RISE: RiseApp.build');
    return MaterialApp(
      title: 'RISE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
