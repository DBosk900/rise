import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/gara_provider.dart';
import 'providers/voti_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Load .env
  await dotenv.load(fileName: '.env');

  // Firebase
  await Firebase.initializeApp();

  // AdMob
  await MobileAds.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GaraProvider()),
        ChangeNotifierProvider(create: (_) => VotiProvider()),
      ],
      child: const RiseApp(),
    ),
  );
}

class RiseApp extends StatefulWidget {
  const RiseApp({super.key});

  @override
  State<RiseApp> createState() => _RiseAppState();
}

class _RiseAppState extends State<RiseApp> {
  late final _router = AppRouter.router(context);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'RISE',
      debugShowCheckedModeBanner: false,
      themeMode: theme.mode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
