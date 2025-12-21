// Fichier : lib/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/services/auth_service.dart';

// ✅ Provider du service d'authentification (Stable)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ✅ Provider de l'état d'authentification (Stream Firebase)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ✅ Provider de l'utilisateur actuel Firebase (REACTIF)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// ✅ Provider de l'UID Firebase
final firebaseUidProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

// ✅ Provider pour vérifier si l'utilisateur est connecté
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// ✅ Provider pour les données utilisateur depuis MySQL
final mysqlUserDataProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  try {
    final authService = ref.read(authServiceProvider);
    return await authService.getCurrentUserMySQLData();
  } catch (e) {
    return null;
  }
});

// ✅ Provider du rôle utilisateur
final userRoleProvider = FutureProvider.autoDispose<String>((ref) async {
  final userData = await ref.watch(mysqlUserDataProvider.future);
  if (userData == null) return 'guest';
  final role = userData['role'];
  if (role is Map) return role['name']?.toString() ?? 'Étudiant';
  return role?.toString() ?? 'Étudiant';
});

// ✅ Provider Admin
final isAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  return ['administrateur', 'bibliothécaire'].contains(role.toLowerCase());
});

// ✅ Provider Professeur
final isProfessorProvider = FutureProvider.autoDispose<bool>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  return ['professeur', 'enseignant'].contains(role.toLowerCase());
});

// ✅ Provider "User Complet"
final completeUserProvider = FutureProvider.autoDispose<CompleteUser?>((ref) async {
  final firebaseUser = ref.watch(currentUserProvider);
  final mysqlData = await ref.watch(mysqlUserDataProvider.future);
  
  if (firebaseUser == null || mysqlData == null) return null;
  
  return CompleteUser(
    firebaseUser: firebaseUser,
    mysqlData: mysqlData,
  );
});

// ✅ Provider pour le nom d'affichage
final displayNameProvider = Provider.autoDispose<String>((ref) {
  final userAsync = ref.watch(completeUserProvider);
  return userAsync.when(
    data: (user) => user?.displayName ?? 'Invité',
    loading: () => 'Chargement...',
    error: (_, __) => 'Erreur',
  );
});

// ✅ Provider pour l'email
final userEmailProvider = Provider.autoDispose<String?>((ref) {
  return ref.watch(currentUserProvider)?.email;
});

// ✅ Provider pour l'avatar
final userAvatarProvider = Provider.autoDispose<String>((ref) {
  final userAsync = ref.watch(completeUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return 'U';
      // Logique existante simplifiée via CompleteUser
      final name = user.displayName;
      if (name.length >= 2) return name.substring(0, 2).toUpperCase();
      return name.substring(0, 1).toUpperCase();
    },
    loading: () => 'U',
    error: (_, __) => 'U',
  );
});

// ✅ Provider pour les permissions
final userPermissionsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userData = await ref.watch(mysqlUserDataProvider.future);
  if (userData != null && userData['role'] is Map) {
    return (userData['role'] as Map<String, dynamic>)['permissions'] ?? {};
  }
  return {};
});

// ✅ Provider permission spécifique
final hasPermissionProvider = FutureProvider.autoDispose.family<bool, String>((ref, permission) async {
  final permissions = await ref.watch(userPermissionsProvider.future);
  return permissions[permission] == true;
});


class CompleteUser {
  final User firebaseUser;
  final Map<String, dynamic> mysqlData;
  
  CompleteUser({required this.firebaseUser, required this.mysqlData});
  
  String get uid => firebaseUser.uid;
  String? get email => firebaseUser.email;
  
  String get displayName {
    return mysqlData['name']?.toString() ?? 
           firebaseUser.displayName ?? 
           firebaseUser.email?.split('@')[0] ?? 'Utilisateur';
  }

  String get role {
    final r = mysqlData['role'];
    if (r is Map) return r['name']?.toString() ?? 'Étudiant';
    return r?.toString() ?? 'Étudiant';
  }

  // Getter pour le matricule
  String? get matricule => mysqlData['matricule']?.toString();

  // Getter pour le téléphone
  String? get telephone => mysqlData['telephone']?.toString();

  // Getter pour l'adresse
  String? get adresse => mysqlData['adresse']?.toString();
  
  // Getter pour vérifier si admin
  bool get isAdmin => ['administrateur', 'bibliothécaire'].contains(role.toLowerCase());

  DateTime? get createdAt => null;

  String? get name => mysqlData['nom']?.toString();

}