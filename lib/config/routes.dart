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
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) async {
      // Récupérer l'état d'authentification
      final authState = ref.read(authStateProvider);
      
      // Si nous n'avons pas encore de données, attendre
      if (authState.isLoading) {
        return null;
      }
      
      final user = authState.value;
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
      
      // 1. Si non connecté et accès à une route protégée → login
      if (user == null && (isUserRoute || isAdminRoute)) {
        // Sauvegarder la route demandée pour redirection après login
        return '/login?redirect=${Uri.encodeComponent(state.matchedLocation)}';
      }
      
      // 2. Si déjà connecté et accès à login/signup → redirection
      if (user != null && isAuthPage) {
        // Récupérer le rôle de l'utilisateur
        final userData = await ref.read(authServiceProvider).getCurrentUserMySQLData();
        final role = userData?['role'] ?? 'Étudiant';
        
        // Rediriger vers le dashboard approprié
        if (role == 'Administrateur' || role == 'Bibliothécaire') {
          return '/admin/dashboard';
        } else {
          return '/dashboard';
        }
      }
      
      // 4. Si connecté et sur la page d'accueil, rediriger vers le dashboard approprié
      if (user != null && isHomePage) {
        final userData = await ref.read(authServiceProvider).getCurrentUserMySQLData();
        final role = userData?['role'] ?? 'Étudiant';
        
        if (role == 'Administrateur' || role == 'Bibliothécaire') {
          return '/admin/dashboard';
        } else {
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
  );
});