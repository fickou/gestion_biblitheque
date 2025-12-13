// Fichier : lib/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/services/auth_service.dart';

// ✅ Provider du service d'authentification
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ✅ Provider de l'état d'authentification (Stream Firebase)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ✅ Provider de l'utilisateur actuel Firebase
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

// ✅ Provider de l'UID Firebase (utile pour les appels API)
final firebaseUidProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
});

// ✅ Provider pour vérifier si l'utilisateur est connecté
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// ✅ Provider pour les données utilisateur depuis MySQL (REMPLACE l'ancien userDataProvider)
final mysqlUserDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    
    if (user == null) return null;
    
    final userData = await authService.getCurrentUserMySQLData();
    
    if (userData != null) {
      print('✅ Données MySQL chargées pour ${userData['name']}');
    } else {
      print('⚠️ Aucune donnée MySQL trouvée pour ${user.uid}');
    }
    
    return userData;
  } catch (e) {
    print('❌ Erreur mysqlUserDataProvider: $e');
    return null;
  }
});

// ✅ Provider du rôle utilisateur depuis MySQL (REMPLACE l'ancien userRoleProvider)
final userRoleProvider = FutureProvider<String>((ref) async {
  try {
    final userDataAsync = ref.watch(mysqlUserDataProvider);
    
    return userDataAsync.when(
      data: (userData) {
        if (userData == null) return 'guest';
        
        // Récupérer le rôle (peut être un Map ou une String)
        final role = userData['role'];
        
        if (role is Map<String, dynamic>) {
          return role['name'] ?? 'Étudiant';
        } else if (role is String) {
          return role;
        }
        
        return 'Étudiant';
      },
      loading: () => 'Chargement...',
      error: (error, stack) {
        print('❌ Erreur userRoleProvider: $error');
        return 'guest';
      },
    );
  } catch (e) {
    return 'guest';
  }
});

// ✅ Provider pour vérifier si l'utilisateur est admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  try {
    final role = await ref.watch(userRoleProvider.future);
    
    final lowerRole = role.toLowerCase();
    return lowerRole == 'administrateur' || lowerRole == 'bibliothécaire';
  } catch (e) {
    print('❌ Erreur isAdminProvider: $e');
    return false;
  }
});

// ✅ Provider pour vérifier si l'utilisateur est professeur
final isProfessorProvider = FutureProvider<bool>((ref) async {
  try {
    final role = await ref.watch(userRoleProvider.future);
    
    final lowerRole = role.toLowerCase();
    return lowerRole == 'professeur' || lowerRole == 'enseignant';
  } catch (e) {
    return false;
  }
});

// ✅ Provider pour l'objet utilisateur complet (fusion Firebase + MySQL)
final completeUserProvider = FutureProvider<CompleteUser?>((ref) async {
  try {
    final firebaseUser = ref.watch(currentUserProvider);
    final mysqlUserData = await ref.watch(mysqlUserDataProvider.future);
    
    if (firebaseUser == null || mysqlUserData == null) return null;
    
    return CompleteUser(
      firebaseUser: firebaseUser,
      mysqlData: mysqlUserData,
    );
  } catch (e) {
    print('❌ Erreur completeUserProvider: $e');
    return null;
  }
});

// ✅ Provider pour le nom d'affichage
final displayNameProvider = Provider<String>((ref) {
  final userAsync = ref.watch(completeUserProvider);
  
  return userAsync.when(
    data: (completeUser) {
      if (completeUser == null) return 'Invité';
      
      // Priorité: MySQL name, sinon Firebase displayName, sinon email
      final mysqlName = completeUser.mysqlData['name'];
      if (mysqlName != null && mysqlName.toString().isNotEmpty) {
        return mysqlName.toString();
      }
      
      final firebaseName = completeUser.firebaseUser.displayName;
      if (firebaseName != null && firebaseName.isNotEmpty) {
        return firebaseName;
      }
      
      return completeUser.firebaseUser.email?.split('@')[0] ?? 'Utilisateur';
    },
    loading: () => 'Chargement...',
    error: (error, stack) => 'Utilisateur',
  );
});

// ✅ Provider pour l'email
final userEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
});

// ✅ Provider pour l'avatar (texte ou URL)
final userAvatarProvider = Provider<String>((ref) {
  final userAsync = ref.watch(completeUserProvider);
  
  return userAsync.when(
    data: (completeUser) {
      if (completeUser == null) return 'U';
      
      // Priorité: MySQL avatarText
      final mysqlAvatar = completeUser.mysqlData['avatarText'];
      if (mysqlAvatar != null && mysqlAvatar.toString().isNotEmpty) {
        return mysqlAvatar.toString();
      }
      
      // Sinon générer à partir du nom
      final name = completeUser.displayName;
      if (name.length >= 2) {
        return name.substring(0, 2).toUpperCase();
      }
      
      return name.substring(0, 1).toUpperCase();
    },
    loading: () => 'U',
    error: (error, stack) => 'U',
  );
});

// ✅ Provider pour les permissions utilisateur
final userPermissionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final userData = await ref.watch(mysqlUserDataProvider.future);
    
    if (userData != null && userData['role'] is Map) {
      final role = userData['role'] as Map<String, dynamic>;
      return role['permissions'] ?? {};
    }
    
    return {}; // Permissions vides par défaut
  } catch (e) {
    return {};
  }
});

// ✅ Provider pour vérifier une permission spécifique
final hasPermissionProvider = FutureProvider.family<bool, String>((ref, permission) async {
  try {
    final permissions = await ref.watch(userPermissionsProvider.future);
    return permissions[permission] == true;
  } catch (e) {
    return false;
  }
});

// 🏗️ Classe pour combiner les données Firebase et MySQL
class CompleteUser {
  final User firebaseUser;
  final Map<String, dynamic> mysqlData;
  
  CompleteUser({
    required this.firebaseUser,
    required this.mysqlData,
  });
  
  // Getter pour le nom d'affichage
  String get displayName {
    final mysqlName = mysqlData['name'];
    if (mysqlName != null && mysqlName.toString().isNotEmpty) {
      return mysqlName.toString();
    }
    return firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'Utilisateur';
  }
  
  // Getter pour le rôle
  String get role {
    final role = mysqlData['role'];
    
    if (role is Map<String, dynamic>) {
      return role['name'] ?? 'Étudiant';
    } else if (role is String) {
      return role;
    }
    
    return 'Étudiant';
  }
  
  // Getter pour l'email
  String? get email => firebaseUser.email;
  
  // Getter pour l'UID Firebase
  String get uid => firebaseUser.uid;
  
  // Getter pour l'ID MySQL
  String? get mysqlId => mysqlData['id']?.toString();
  
  // Getter pour le matricule
  String? get matricule => mysqlData['matricule']?.toString();
  
  // Getter pour vérifier si admin
  bool get isAdmin {
    final lowerRole = role.toLowerCase();
    return lowerRole == 'administrateur' || lowerRole == 'bibliothécaire';
  }
  
  // Getter pour vérifier si professeur
  bool get isProfessor {
    final lowerRole = role.toLowerCase();
    return lowerRole == 'professeur' || lowerRole == 'enseignant';
  }
  
  // Getter pour vérifier si étudiant
  bool get isStudent => role == 'Étudiant';
  
  // Getter pour les permissions
  Map<String, dynamic> get permissions {
    final role = mysqlData['role'];
    if (role is Map<String, dynamic>) {
      return role['permissions'] ?? {};
    }
    return {};
  }
  
  // Méthode pour vérifier une permission
  bool hasPermission(String permission) {
    return permissions[permission] == true;
  }
  
  @override
  String toString() {
    return 'CompleteUser{name: $displayName, role: $role, email: $email}';
  }
}