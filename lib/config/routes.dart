import 'package:gestion_bibliotheque/screens/admin/notification.dart';
import 'package:gestion_bibliotheque/screens/admin/profil.dart';
import 'package:gestion_bibliotheque/screens/admin/users.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/catalogue.dart';
import '../screens/dashbord.dart'; // ✅ Corrigé le nom du fichier
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
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const Signup(),
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

      //admin
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
      path: '/admin/booksdetails/:id',  // ← Ajoutez :id ici
      name: 'admin_booksdetails',
      builder: (context, state) {
        final id = state.pathParameters['id']!;  // ← Récupérez l'ID
        return BookDetailPage(id: id);
      },
    ),
// Dans votre configuration GoRouter
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
              path: '/profiladmin', // Route pour le profil
              name: 'profiladmin',
              builder: (context, state) => const AdminProfilePage(), // Page de profil
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
    

    ],
  );
});