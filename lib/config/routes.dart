import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/catalogue.dart';
import '../screens/dashbord.dart'; // ✅ Corrigé le nom du fichier
import '../screens/home.dart';
import '../screens/login.dart';

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    // 🔓 SUPPRIMEZ complètement la logique de redirection
    // ou gardez une version très simple sans restriction
    redirect: (context, state) {
      // Option 1: Aucune redirection - toutes les routes accessibles
      return null;
      
      // Option 2: Redirection uniquement pour éviter le login quand déjà connecté
      // final authState = ref.read(authStateProvider);
      // if (authState && state.matchedLocation == '/login') {
      //   return '/home';
      // }
      // return null;
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