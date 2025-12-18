import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/admin/notification.dart';
import '../screens/admin/profil.dart';
import '../screens/admin/reservation.dart';
import '../screens/admin/userdetail.dart';
import '/screens/admin/users.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_bibliotheque/providers/auth_provider.dart';
import '../screens/catalogue.dart';
import '../screens/dashbord.dart';
import '../screens/home.dart';
import '../screens/login.dart';
import '../screens/signup.dart';
import '../screens/profil.dart';
import '../screens/reservation.dart';
import '../screens/admin/books.dart';
import '../screens/admin/dashboard.dart';
import '../screens/admin/booksdetails.dart';
import '../screens/admin/loans.dart';
import '../screens/emprunts.dart';

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    redirect: (context, state) async {
      // 1. Récupérer l'état d'authentification actuel
      final user = authService.currentUser;
      final isLoggedIn = user != null;
      
      final isAuthPage = state.matchedLocation == '/login' || 
                         state.matchedLocation == '/signup';
      final isHomePage = state.matchedLocation == '/home';

      // Routes qui nécessitent une authentification (utilisateurs normaux)
      final userRoutes = [
        '/dashboard',
        '/catalogue',
        '/profil',
        '/reservations',
        '/emprunts',
      ];
      
      // Routes admin (administrateurs et bibliothécaires seulement)
      final adminRoutes = [
        '/admin/dashboard',
        '/admin/books',
        '/admin/emprunts',
        '/admin/etudiants',
        '/admin/notifications',
        '/admin/reservations',
        '/profiladmin'
      ];
      
      final isUserRoute = userRoutes.any((route) => 
          state.matchedLocation.startsWith(route));
      final isAdminRoute = adminRoutes.any((route) => 
          state.matchedLocation.startsWith(route));

      // 2. Si NON CONNECTÉ et essaie d'accéder à une page protégée -> LOGIN
      if (!isLoggedIn && (isUserRoute || isAdminRoute)) {
        return '/login?redirect=${Uri.encodeComponent(state.matchedLocation)}';
      }
      
      // 3. Si CONNECTÉ et essaie d'accéder à Login/Signup/Home -> DASHBOARD
      if (isLoggedIn && (isAuthPage || isHomePage)) {
        // En attente : il faudrait idéalement vérifier le rôle ici.
        // Mais nous sommes dans une fonction synchrone (conceptuellement) du routeur.
        // On redirige vers une page "loading" ou par défaut le dashboard étudiant,
        // et le dashboard lui-même redirigera si besoin, OU on fait un appel async rapide.
        
        // Note: L'appel async dans redirect est supporté.
        try {
          final userData = await authService.getCurrentUserMySQLData();
          final role = userData?['role'];
          final roleName = (role is Map) ? role['name'] : role;
          
          if (roleName == 'Administrateur' || roleName == 'Bibliothécaire') {
            return '/admin/dashboard';
          } else {
            return '/dashboard';
          }
        } catch (e) {
          // Fallback en cas d'erreur
          return '/dashboard';
        }
      }
      
      return null;
    },
    routes: [
      // Routes publiques
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const Home(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Login(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const Signup(),
      ),
      
      // Routes utilisateur (authentifiées)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/catalogue',
        name: 'catalogue',
        builder: (context, state) => const CataloguePage(),
      ),
      GoRoute(
        path: '/profil',
        name: 'profil',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/reservations',
        name: 'reservations',
        builder: (context, state) => const ReservationsPage(),
      ),
      GoRoute(
        path: '/emprunts',
        name: 'emprunts',
        builder: (context, state) => const EmpruntsPage(),
      ),
      
      // Routes admin
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin_dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/books',
        name: 'admin_books',
        builder: (context, state) => const BooksAdminPage(),
      ),
      GoRoute(
        path: '/admin/booksdetails/:id',
        name: 'admin_booksdetails',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BookDetailPage(id: id);
        },
      ),
      GoRoute(
        path: '/admin/notifications',
        name: 'admin_notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/admin/emprunts',
        name: 'admin_emprunts',
        builder: (context, state) => const AdminLoansPage(),
      ),
      GoRoute(
        path: '/admin/etudiants',
        name: 'admin_students',
        builder: (context, state) => const StudentsPage(),
      ),
      GoRoute(
        path: '/admin/etudiants/:id',
        name: 'admin_student_detail',
        builder: (context, state) {
          return UserDetailPage(
            id: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/profiladmin',
        name: 'profiladmin',
        builder: (context, state) => const AdminProfilePage(),
      ),
      GoRoute(
        path: '/admin/reservations',
        name: 'admin_reservations',
        builder: (context, state) => const AdminReservationsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Erreur: ${state.error}')),
    ),
  );
});

// Classe utilitaire pour écouter le stream Firebase Auth
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}