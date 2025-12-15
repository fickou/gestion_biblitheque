// lib/services/api_service.dart - VERSION SANS TOKENS
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

import '../models/user.dart';
import '../models/book.dart';
import '../models/emprunt.dart';
import '../models/reservation.dart';
import '../models/category.dart';
import '../models/role.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  User? _currentUser;

  User? get currentUser => _currentUser;

  // Méthode d'authentification simplifiée sans token
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Tentative de connexion vers: ${ApiConfig.getLoginUri()}');
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      final response = await http.post(
        ApiConfig.getLoginUri(),
        headers: headers,
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      print('📊 Statut HTTP: ${response.statusCode}');
      print('📄 Réponse brute: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          // Vérifier si la réponse contient 'success'
          final bool success = data['success'] == true;
          
          if (success) {
            // Récupérer l'utilisateur de manière sécurisée
            if (data['user'] != null) {
              try {
                _currentUser = User.fromJson(Map<String, dynamic>.from(data['user']));
                print('✅ Utilisateur créé: ${_currentUser!.name}');
                
                return {
                  'success': true,
                  'user': _currentUser,
                  'message': data['message']?.toString() ?? 'Connexion réussie'
                };
              } catch (e) {
                print('❌ Erreur lors de la création de l\'utilisateur: $e');
                return {
                  'success': false,
                  'message': 'Format utilisateur invalide'
                };
              }
            } else {
              print('⚠️ Avertissement: Pas de données utilisateur dans la réponse');
              return {
                'success': false,
                'message': 'Pas de données utilisateur dans la réponse'
              };
            }
          } else {
            // Récupérer le message d'erreur
            final errorMessage = data['message']?.toString() 
                ?? data['error']?.toString()
                ?? 'Identifiants incorrects';
            
            print('❌ Login échoué: $errorMessage');
            
            return {
              'success': false,
              'message': errorMessage
            };
          }
        } catch (e) {
          print('❌ Erreur de parsing JSON: $e');
          return {
            'success': false,
            'message': 'Format de réponse invalide'
          };
        }
      } else if (response.statusCode == 401) {
        print('❌ 401: Non autorisé');
        return {
          'success': false,
          'message': 'Email ou mot de passe incorrect'
        };
      } else if (response.statusCode == 422) {
        print('❌ 422: Erreur de validation');
        return {
          'success': false,
          'message': 'Données de connexion invalides'
        };
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erreur serveur (${response.statusCode})',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Erreur de connexion complète: $e');
      String errorMsg = 'Erreur de connexion';
      
      if (e.toString().contains('Timeout')) {
        errorMsg = 'Le serveur met trop de temps à répondre';
      } else if (e.toString().contains('Failed host lookup')) {
        errorMsg = 'Impossible de se connecter au serveur';
      }
      
      return {
        'success': false,
        'message': errorMsg
      };
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    print('✅ Déconnexion');
  }

  // Méthodes pour les livres
  Future<List<Book>> getBooks() async {
    print('📚 getBooks - Début');
    
    try {
      final uri = ApiConfig.getBooksUri();
      print('🌐 URI: $uri');
      
      final response = await http.get(
        uri,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      print('📊 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          if (data is Map<String, dynamic> && data['success'] == true) {
            final booksData = data['data'] ?? [];
            if (booksData is List) {
              final books = booksData.map<Book?>((json) {
                try {
                  return Book.fromJson(Map<String, dynamic>.from(json));
                } catch (e) {
                  print('⚠️ Erreur conversion livre: $e');
                  return null;
                }
              }).whereType<Book>().toList();
              
              print('✅ ${books.length} livres récupérés');
              return books;
            }
          } else if (data is List) {
            final books = data.map<Book?>((json) {
              try {
                return Book.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('⚠️ Erreur conversion livre: $e');
                return null;
              }
            }).whereType<Book>().toList();
            
            print('✅ ${books.length} livres récupérés (ancien format)');
            return books;
          }
          
          return [];
        } catch (e) {
          print('❌ Erreur parsing JSON: $e');
          return [];
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception getBooks: $e');
      return [];
    }
  }

  Future<Book?> getBookById(String id) async {
    try {
      final response = await http.get(
        ApiConfig.getBookUri(id),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return Book.fromJson(Map<String, dynamic>.from(data));
        } catch (e) {
          print('Erreur de parsing getBookById: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du livre: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createBook(Book book) async {
    try {
      final response = await http.post(
        ApiConfig.getBooksUri(),
        headers: _getHeaders(),
        body: jsonEncode(book.toDatabase()),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Erreur création livre: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> updateBook(Book book) async {
    try {
      final response = await http.put(
        ApiConfig.getBookUri(book.id),
        headers: _getHeaders(),
        body: jsonEncode(book.toDatabase()),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Erreur mise à jour livre: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteBook(String id) async {
    try {
      final response = await http.delete(
        ApiConfig.getBookUri(id),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Erreur suppression livre: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<List<Book>> searchBooks(String query) async {
    try {
      final response = await http.get(
        ApiConfig.getSearchUri(query),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((json) {
              try {
                return Book.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('Erreur lors de la conversion d\'un livre: $e');
                return null;
              }
            }).whereType<Book>().toList();
          }
          return [];
        } catch (e) {
          print('Erreur de parsing searchBooks: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      return [];
    }
  }

  // Méthodes pour les utilisateurs
  Future<List<User>> getUsers() async {
    try {
      final uri = ApiConfig.getUsersUri();
      print('🌐 GET Users URI: $uri');
      
      final headers = _getHeaders();
      
      final response = await http.get(uri, headers: headers);
      
      print('📊 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          if (data is List) {
            final users = data.map<User?>((json) {
              try {
                return User.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('⚠️ Erreur conversion utilisateur: $e');
                return null;
              }
            }).whereType<User>().toList();
            
            print('✅ ${users.length} utilisateurs récupérés avec succès');
            return users;
          }
          
          return [];
        } catch (e) {
          print('❌ Erreur parsing JSON: $e');
          return [];
        }
      } else if (response.statusCode == 401) {
        print('❌ Erreur 401: Accès non autorisé');
        throw Exception('Accès non autorisé');
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception getUsers: $e');
      rethrow;
    }
  }

  Future<User?> getUserById(String id) async {
    try {
      final response = await http.get(
        ApiConfig.getUserUri(id),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return User.fromJson(Map<String, dynamic>.from(data));
        } catch (e) {
          print('Erreur de parsing getUserById: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  // Méthodes pour les emprunts
  Future<List<Emprunt>> getEmprunts() async {
    try {
      final response = await http.get(
        ApiConfig.getEmpruntsUri(),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((json) {
              try {
                return Emprunt.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('Erreur lors de la conversion d\'un emprunt: $e');
                return null;
              }
            }).whereType<Emprunt>().toList();
          }
          return [];
        } catch (e) {
          print('Erreur de parsing getEmprunts: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des emprunts: $e');
      return [];
    }
  }

  Future<List<Emprunt>> getUserEmprunts(String userId) async {
    try {
      final uri = ApiConfig.getUserEmpruntsUri(userId);
      final headers = _getHeaders();
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        // Nettoyer les warnings PHP
        String cleanBody = response.body.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '');
        cleanBody = cleanBody.replaceAll(RegExp(r'<b>.*?</b>', caseSensitive: false), '');
        cleanBody = cleanBody.trim();
        
        try {
          final data = jsonDecode(cleanBody);
          if (data is List) {
            return data.map((item) => Emprunt.fromJson(Map<String, dynamic>.from(item))).toList();
          }
        } catch (e) {
          print('Erreur parsing emprunts: $e');
        }
      }
      
      return [];
    } catch (e) {
      print('Erreur getUserEmprunts: $e');
      return [];
    }
  }

  Future<List<Emprunt>> getLateEmprunts() async {
    try {
      final response = await http.get(
        ApiConfig.getLateEmpruntsUri(),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((json) {
              try {
                return Emprunt.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('Erreur lors de la conversion d\'un emprunt: $e');
                return null;
              }
            }).whereType<Emprunt>().toList();
          }
          return [];
        } catch (e) {
          print('Erreur de parsing getLateEmprunts: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des emprunts en retard: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createEmprunt(String bookId, String userId) async {
    try {
      final response = await http.post(
        ApiConfig.getEmpruntsUri(),
        headers: _getHeaders(),
        body: jsonEncode({
          'bookId': bookId,
          'userId': userId,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Erreur création emprunt: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> returnBook(String empruntId) async {
    try {
      final response = await http.post(
        ApiConfig.getReturnBookUri(),
        headers: _getHeaders(),
        body: jsonEncode({
          'empruntId': empruntId,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Erreur retour livre: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Méthodes pour les réservations
  Future<List<Reservation>> getReservations() async {
    try {
      final response = await http.get(
        ApiConfig.getReservationsUri(),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((json) {
              try {
                return Reservation.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('Erreur lors de la conversion d\'une réservation: $e');
                return null;
              }
            }).whereType<Reservation>().toList();
          }
          return [];
        } catch (e) {
          print('Erreur de parsing getReservations: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des réservations: $e');
      return [];
    }
  }

  Future<List<Reservation>> getPendingReservations() async {
    try {
      final response = await http.get(
        ApiConfig.getPendingReservationsUri(),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((json) {
              try {
                return Reservation.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('Erreur lors de la conversion d\'une réservation: $e');
                return null;
              }
            }).whereType<Reservation>().toList();
          }
          return [];
        } catch (e) {
          print('Erreur de parsing getPendingReservations: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des réservations en attente: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createReservation(String bookId, String userId) async {
    try {
      final response = await http.post(
        ApiConfig.getReservationsUri(),
        headers: _getHeaders(),
        body: jsonEncode({
          'bookId': bookId,
          'userId': userId,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Erreur création réservation: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Méthodes pour les catégories
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        ApiConfig.getCategoriesUri(),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((json) {
              try {
                return Category.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('Erreur lors de la conversion d\'une catégorie: $e');
                return null;
              }
            }).whereType<Category>().toList();
          }
          return [];
        } catch (e) {
          print('Erreur de parsing getCategories: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  // Méthodes pour les rôles
  Future<List<Role>> getRoles() async {
    try {
      final response = await http.get(
        ApiConfig.getRolesUri(),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((json) {
              try {
                return Role.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('Erreur lors de la conversion d\'un rôle: $e');
                return null;
              }
            }).whereType<Role>().toList();
          }
          return [];
        } catch (e) {
          print('Erreur de parsing getRoles: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des rôles: $e');
      return [];
    }
  }

  // Méthodes pour le dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        ApiConfig.getDashboardStatsUri(),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return Map<String, dynamic>.from(data);
        } catch (e) {
          print('Erreur de parsing getDashboardStats: $e');
          return {};
        }
      }
      return {};
    } catch (e) {
      print('Erreur lors de la récupération des stats du dashboard: $e');
      return {};
    }
  }

  Future<List<dynamic>> getTopBooks({int limit = 5}) async {
    try {
      final response = await http.get(
        ApiConfig.getTopBooksUri(limit: limit),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return List<dynamic>.from(data);
        } catch (e) {
          print('Erreur de parsing getTopBooks: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des livres populaires: $e');
      return [];
    }
  }

  Future<List<dynamic>> getRecentActivities({int limit = 10}) async {
    try {
      final response = await http.get(
        ApiConfig.getRecentActivitiesUri(limit: limit),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return List<dynamic>.from(data);
        } catch (e) {
          print('Erreur de parsing getRecentActivities: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des activités récentes: $e');
      return [];
    }
  }

  Future<List<dynamic>> getCategoryStats() async {
    try {
      final response = await http.get(
        ApiConfig.getCategoryStatsUri(),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return List<dynamic>.from(data);
        } catch (e) {
          print('Erreur de parsing getCategoryStats: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des stats par catégorie: $e');
      return [];
    }
  }

  // Méthodes utilitaires
  Map<String, String> _getHeaders() {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Ancienne méthode, maintenant obsolète
  Map<String, String> _getAuthHeaders() {
    return _getHeaders(); // Retourne juste les headers basiques
  }

  bool get isAuthenticated => _currentUser != null;
  
  // Méthode de débogage
  void debugInfo() {
    print('''
=== API SERVICE DEBUG ===
Authentifié: $isAuthenticated
Utilisateur: ${_currentUser != null ? 'Oui (${_currentUser!.name} - ${_currentUser!.email})' : 'Non'}
URL de base: ${ApiConfig.baseUrl}
=======================
''');
  }
  
  int min(int a, int b) => a < b ? a : b;
}