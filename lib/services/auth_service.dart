// lib/services/auth_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '/config/api_url.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // URL de votre API PHP - À MODIFIER AVEC VOTRE IP
  static const String apiBaseUrl = api; // Remplacez par votre IP
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ✅ INSCRIPTION COMPLÈTE (Firebase + MySQL)
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String matricule,
    required String role,
  }) async {
    try {
      print('🚀 Début inscription - Firebase + MySQL');
      
      // 1. CRÉATION DANS FIREBASE AUTH
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final fullName = '$prenom $nom';
      
      print('✅ Utilisateur Firebase créé - UID: $uid');

      // 2. SYNCHRONISATION AVEC MYSQL VIA API PHP
      print('🔄 Synchronisation avec MySQL...');
      
      final phpResponse = await _syncUserWithPHP(
        firebaseUid: uid,
        email: email,
        nom: nom,
        prenom: prenom,
        fullName: fullName,
        matricule: matricule,
        role: role,
      );

      print('📊 Réponse API PHP: $phpResponse');

      if (phpResponse['success'] != true) {
        print('❌ Erreur MySQL - Suppression utilisateur Firebase...');
        
        // Annuler la création Firebase en cas d'erreur MySQL
        await userCredential.user!.delete();
        
        return {
          'success': false,
          'error': phpResponse['error'] ?? 'Erreur lors de la création du profil',
        };
      }

      print('🎉 Inscription complète réussie !');
      
      return {
        'success': true,
        'user': userCredential.user,
        'uid': uid,
        'mysqlUserId': phpResponse['userId'],
        'userData': phpResponse['user'],
        'role': phpResponse['user']['role'] ?? role,
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur Firebase: ${e.code}');
      return {
        'success': false,
        'error': _getErrorMessage(e.code),
      };
    } catch (e) {
      print('❌ Erreur générale: $e');
      return {
        'success': false,
        'error': 'Une erreur est survenue: $e',
      };
    }
  }

  // ✅ CONNEXION AVEC RÉCUPÉRATION DES DONNÉES MYSQL
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Début connexion');
      
      // 1. CONNEXION FIREBASE
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      print('✅ Connexion Firebase réussie - UID: $uid');

      // 2. RÉCUPÉRATION DES DONNÉES MYSQL
      print('🔄 Récupération données MySQL...');
      final phpUser = await _getUserFromPHP(uid);
      
      // LOG DÉTAILLÉ
      print('📊 Données PHP reçues:');
      print('  - Type: ${phpUser.runtimeType}');
      print('  - Valeur: $phpUser');
      
      if (phpUser == null) {
        print('⚠️ Utilisateur non trouvé dans MySQL - Création automatique...');
        // ... reste du code
      }

      print('✅ Données MySQL récupérées');
      
      // VALIDATION DES DONNÉES
      if (phpUser != null) {
        // Vérifiez chaque champ
        print('🔍 Validation des données utilisateur:');
        print('  - id: ${phpUser['id']} (type: ${phpUser['id']?.runtimeType})');
        print('  - firebaseUid: ${phpUser['firebaseUid']} (type: ${phpUser['firebaseUid']?.runtimeType})');
        print('  - name: ${phpUser['name']} (type: ${phpUser['name']?.runtimeType})');
        print('  - email: ${phpUser['email']} (type: ${phpUser['email']?.runtimeType})');
        print('  - matricule: ${phpUser['matricule']} (type: ${phpUser['matricule']?.runtimeType})');
        print('  - role: ${phpUser['role']} (type: ${phpUser['role']?.runtimeType})');
        print('  - avatarText: ${phpUser['avatarText']} (type: ${phpUser['avatarText']?.runtimeType})');
        
        // Assurez-vous qu'aucune valeur n'est null si votre code s'attend à une string
        final userData = {
          'id': phpUser['id']?.toString() ?? '',
          'firebaseUid': phpUser['firebaseUid']?.toString() ?? uid,
          'name': phpUser['name']?.toString() ?? userCredential.user!.displayName ?? email.split('@')[0],
          'email': phpUser['email']?.toString() ?? email,
          'matricule': phpUser['matricule']?.toString() ?? '',
          'role': phpUser['role']?.toString() ?? 'Étudiant',
          'avatarText': phpUser['avatarText']?.toString() ?? 'US',
        };
        
        print('📦 Données traitées: $userData');
        
        return {
          'success': true,
          'user': userCredential.user,
          'uid': uid,
          'userData': userData, // Utilisez les données traitées
        };
      }
      
      return {
        'success': true,
        'user': userCredential.user,
        'uid': uid,
        'warning': 'Profil utilisateur incomplet',
      };
      
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur connexion: ${e.code}');
      return {
        'success': false,
        'error': _getErrorMessage(e.code),
      };
    } catch (e, stackTrace) {
      print('❌ Erreur générale: $e');
      print('📌 Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  // ✅ RÉCUPÉRER LES DONNÉES UTILISATEUR ACTUEL DEPUIS MYSQL
  Future<Map<String, dynamic>?> getCurrentUserMySQLData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ Aucun utilisateur connecté');
        return null;
      }
      
      print('🔄 Récupération données MySQL pour UID: ${user.uid}');
      return await _getUserFromPHP(user.uid);
    } catch (e) {
      print('❌ Erreur getCurrentUserMySQLData: $e');
      return null;
    }
  }

  // ✅ DÉCONNEXION
  Future<void> signOut() async {
    print('🚪 Déconnexion...');
    await _auth.signOut();
    print('✅ Déconnecté');
  }

  // ✅ RÉINITIALISATION MOT DE PASSE
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      print('📧 Envoi réinitialisation mot de passe à: $email');
      await _auth.sendPasswordResetEmail(email: email);
      
      return {
        'success': true,
        'message': 'Email de réinitialisation envoyé',
      };
    } catch (e) {
      print('❌ Erreur resetPassword: $e');
      return {
        'success': false,
        'error': 'Erreur: $e',
      };
    }
  }

  // ✅ VÉRIFIER SI L'UTILISATEUR EST ADMIN
  Future<bool> isUserAdmin() async {
    try {
      final userData = await getCurrentUserMySQLData();
      if (userData == null) return false;
      
      final role = userData['role'];
      final roleName = (role is Map) ? role['name'] : role;
      
      return roleName == 'Administrateur' || roleName == 'Bibliothécaire';
    } catch (e) {
      return false;
    }
  }

  // 🔧 MÉTHODES PRIVÉES POUR L'API PHP
  Future<Map<String, dynamic>> _syncUserWithPHP({
  required String firebaseUid,
  required String email,
  required String nom,
  required String prenom,
  required String fullName,
  required String matricule,
  required String role,
}) async {
  try {
    print('🌐 Appel API PHP pour synchronisation...');
    
    final response = await http.post(
      Uri.parse('$apiBaseUrl/firebase-sync.php'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'firebaseUid': firebaseUid,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'name': fullName,
        'matricule': matricule,
        'role': role,
      }),
    );

    print('📡 Réponse HTTP: ${response.statusCode}');
    print('📄 Body complet (1000 premiers caractères):');
    print(response.body.length > 1000 ? response.body.substring(0, 1000) : response.body);
    
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        print('✅ JSON décodé avec succès');
        print('📊 Données reçues: $data');
        
        return {
          'success': data['success'] ?? false,
          'userId': data['userId'],
          'message': data['message'],
          'user': data['user'],
        };
      } catch (e) {
        print('❌ Erreur décodage JSON: $e');
        print('⚠️ Le serveur a peut-être renvoyé du HTML au lieu de JSON');
        
        // Vérifier si c'est du HTML
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) {
          print('🚨 Le serveur renvoie du HTML !');
          
          // Extraire le message d'erreur PHP
          String errorMessage = 'Erreur serveur HTML reçu';
          if (response.body.contains('<b>') && response.body.contains('</b>')) {
            final start = response.body.indexOf('<b>') + 3;
            final end = response.body.indexOf('</b>', start);
            errorMessage = response.body.substring(start, end);
          }
          
          return {
            'success': false,
            'error': 'Erreur PHP: $errorMessage\nAssurez-vous que l\'API retourne du JSON valide.',
          };
        }
        
        return {
          'success': false,
          'error': 'Réponse invalide du serveur: ${e.toString()}',
        };
      }
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
      
      return {
        'success': false,
        'error': 'Erreur serveur (${response.statusCode})\n'
                 'Body: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      };
    }
  } catch (e) {
    print('❌ Erreur connexion API: $e');
    
    return {
      'success': false,
      'error': 'Impossible de se connecter à l\'API. Vérifiez:\n'
               '1. Que votre serveur PHP est démarré\n'
               '2. Que l\'URL ($apiBaseUrl/firebase-sync.php) est correcte\n'
               '3. Que votre appareil est sur le même réseau que le serveur\n'
               'Erreur: ${e.toString()}',
    };
  }
}

  Future<Map<String, dynamic>?> _getUserFromPHP(String firebaseUid) async {
    try {
      print('🌐 Appel API PHP pour récupération utilisateur: $firebaseUid');
      
      final response = await http.get(
        Uri.parse('$apiBaseUrl/firebase-sync.php?uid=$firebaseUid'),
        headers: {'Accept': 'application/json'},
      );

      print('📡 Réponse HTTP: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ Utilisateur trouvé dans MySQL');
          return data['user'];
        } else {
          print('⚠️ Utilisateur non trouvé: ${data['error']}');
          return null;
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Erreur _getUserFromPHP: $e');
      return null;
    }
  }

  // ✅ MESSAGES D'ERREUR EN FRANÇAIS
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password': return 'Le mot de passe est trop faible (minimum 6 caractères)';
      case 'email-already-in-use': return 'Cet email est déjà utilisé par un autre compte';
      case 'invalid-email': return 'L\'adresse email est invalide';
      case 'user-not-found': return 'Aucun compte n\'est associé à cet email';
      case 'wrong-password': return 'Le mot de passe est incorrect';
      case 'user-disabled': return 'Ce compte a été désactivé';
      case 'too-many-requests': return 'Trop de tentatives de connexion. Réessayez plus tard';
      case 'operation-not-allowed': return 'La connexion par email/mot de passe n\'est pas activée';
      case 'network-request-failed': return 'Erreur de connexion réseau. Vérifiez votre internet';
      default: return 'Erreur d\'authentification: $code';
    }
  }
}