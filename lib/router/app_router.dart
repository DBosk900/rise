import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registrazione_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/gare/dettaglio_gara_screen.dart';
import '../screens/gare/schermata_brano_screen.dart';
import '../screens/artista/dashboard_artista_screen.dart';
import '../screens/artista/upload_brano_screen.dart';
import '../screens/profilo/profilo_screen.dart';
import '../screens/voti/acquisto_voti_screen.dart';
import '../screens/classifica/classifica_screen.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    // Cattura il provider una volta dal contesto noto — evita di usare
    // ctx.read<>() nel redirect callback dove il contesto è incerto
    final authProvider = context.read<AuthProvider>();

    return GoRouter(
      initialLocation: '/splash',
      // Ri-valuta i redirect ogni volta che AuthProvider notifica cambiamenti
      refreshListenable: authProvider,
      redirect: (ctx, state) {
        final status = authProvider.status;
        final location = state.matchedLocation;

        // Non interferire con splash e onboarding
        final onSplash = location == '/splash';
        final onOnboarding = location == '/onboarding';
        final onAuthPage = location.startsWith('/auth');

        // Durante il loading non fare redirect — la splash gestisce la navigazione
        if (status == AuthStatus.loading) {
          if (onSplash) return null;
          // Se non siamo sulla splash e l'auth è in loading, aspettiamo sulla splash
          return '/splash';
        }

        final loggedIn = authProvider.isAuthenticated;

        if (onSplash || onOnboarding) return null;
        if (!loggedIn && !onAuthPage) return '/auth/login';
        if (loggedIn && onAuthPage) return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/registrazione',
          builder: (_, __) => const RegistrazioneScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/gara/:garaId',
          builder: (_, state) => DettaglioGaraScreen(
            garaId: state.pathParameters['garaId']!,
          ),
        ),
        GoRoute(
          path: '/brano/:branoId',
          builder: (_, state) => SchermataBranoScreen(
            branoId: state.pathParameters['branoId']!,
          ),
        ),
        GoRoute(
          path: '/artista/dashboard',
          builder: (_, __) => const DashboardArtistaScreen(),
        ),
        GoRoute(
          path: '/artista/upload',
          builder: (_, __) => const UploadBranoScreen(),
        ),
        GoRoute(
          path: '/profilo/:artistaId',
          builder: (_, state) => ProfiloScreen(
            artistaId: state.pathParameters['artistaId']!,
          ),
        ),
        GoRoute(
          path: '/voti/acquisto',
          builder: (_, __) => const AcquistoVotiScreen(),
        ),
        GoRoute(
          path: '/classifica',
          builder: (_, __) => const ClassificaScreen(),
        ),
      ],
    );
  }
}
