import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importation du provider d'authentification
import '../providers/auth_provider.dart';

// Importation des pages
import '../screens/catalogue.dart';
import '../screens/dashbord.dart';
import '../screens/home.dart';
import '../screens/login.dart';

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  // On écoute l'état de l'authentification
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home', // Page par défaut au lancement
    redirect: (context, state) {
      final requestedLocation = state.matchedLocation;

      // Pages accessibles sans être connecté
      final publicRoutes = ['/home', '/login'];

      // Si l'utilisateur n'est pas connecté et veut aller sur une page protégée
      if (!authState && !publicRoutes.contains(requestedLocation)) {
        return '/login'; // redirection vers login
      }

      // Si l'utilisateur est connecté et veut aller sur login, on le renvoie sur home
      if (authState && requestedLocation == '/login') {
        return '/home';
      }

      // Sinon, on ne redirige pas
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Login(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const Home(),
      ),
      GoRoute(
        path: '/catalogue',
        name: 'catalogue',
        builder: (context, state) => const CataloguePage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
    ],
  );
});
