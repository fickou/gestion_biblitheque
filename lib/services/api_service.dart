// lib/services/api_service.dart - VERSION CORRIGÉE
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

  String? _token;
  User? _currentUser;

  User? get currentUser => _currentUser;
  String? get token => _token;

  // Méthode d'authentification CORRIGÉE - Gestion des nulls
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Tentative de connexion vers: ${ApiConfig.getLoginUri()}');
      
      final response = await http.post(
        ApiConfig.getLoginUri(),
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      print('Statut HTTP: ${response.statusCode}');
      print('Réponse brute: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          // Vérifier si la réponse contient 'success'
          final bool success = data['success'] == true;
          
          if (success) {
            // Récupérer le token de manière sécurisée
            _token = data['token']?.toString();
            
            // Récupérer l'utilisateur de manière sécurisée
            if (data['user'] != null) {
              try {
                _currentUser = User.fromJson(Map<String, dynamic>.from(data['user']));
              } catch (e) {
                print('Erreur lors de la création de l\'utilisateur: $e');
                return {
                  'success': false,
                  'message': 'Format utilisateur invalide'
                };
              }
            } else {
              print('Avertissement: Pas de données utilisateur dans la réponse');
              return {
                'success': false,
                'message': 'Pas de données utilisateur dans la réponse'
              };
            }
            
            // Vérifier que le token et l'utilisateur sont valides
            if (_token != null && _currentUser != null) {
              return {
                'success': true,
                'user': _currentUser,
                'token': _token,
                'message': data['message']?.toString() ?? 'Connexion réussie'
              };
            } else {
              return {
                'success': false,
                'message': 'Données utilisateur incomplètes'
              };
            }
          } else {
            // Récupérer le message d'erreur
            final errorMessage = data['message']?.toString() 
                ?? data['error']?.toString()
                ?? 'Identifiants incorrects';
            
            return {
              'success': false,
              'message': errorMessage
            };
          }
        } catch (e) {
          print('Erreur de parsing JSON: $e');
          return {
            'success': false,
            'message': 'Format de réponse invalide'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur (${response.statusCode})',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Erreur de connexion complète: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}'
      };
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
  }

  // Méthodes pour les livres avec gestion des nulls
  Future<List<Book>> getBooks() async {
    try {
      final response = await http.get(
        ApiConfig.getBooksUri(),
        headers: _getAuthHeaders(),
      );

      print('Statut getBooks: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          // Vérifier si c'est une liste
          if (data is List) {
            return data.map((json) {
              try {
                return Book.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('Erreur lors de la conversion d\'un livre: $e');
                return null;
              }
            }).whereType<Book>().toList();
          } else if (data is Map<String, dynamic>) {
            // Si c'est un objet avec une clé 'books' ou 'data'
            final List<dynamic> booksData = data['books'] ?? data['data'] ?? [];
            return booksData.map((json) {
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
          print('Erreur de parsing getBooks: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des livres: $e');
      return [];
    }
  }

  Future<Book?> getBookById(String id) async {
    try {
      final response = await http.get(
        ApiConfig.getBookUri(id),
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        ApiConfig.getBookUri(book.id ?? ''),
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
      final response = await http.get(
        ApiConfig.getUsersUri(),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((json) {
              try {
                return User.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                print('Erreur lors de la conversion d\'un utilisateur: $e');
                return null;
              }
            }).whereType<User>().toList();
          }
          return [];
        } catch (e) {
          print('Erreur de parsing getUsers: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  Future<User?> getUserById(String id) async {
    try {
      final response = await http.get(
        ApiConfig.getUserUri(id),
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
      final response = await http.get(
        ApiConfig.getUserEmpruntsUri(userId),
        headers: _getAuthHeaders(),
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
          print('Erreur de parsing getUserEmprunts: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des emprunts utilisateur: $e');
      return [];
    }
  }

  Future<List<Emprunt>> getLateEmprunts() async {
    try {
      final response = await http.get(
        ApiConfig.getLateEmpruntsUri(),
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
  Map<String, String> _getAuthHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  bool get isAuthenticated => _token != null && _currentUser != null;
  
  // Nouvelle méthode pour vérifier la validité du token
  Future<bool> validateToken() async {
    if (_token == null) return false;
    
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('validate-token')),
        headers: _getAuthHeaders(),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur validation token: $e');
      return false;
    }
  }
  
  // Méthode de débogage
  void debugInfo() {
    print('''
=== API SERVICE DEBUG ===
Authentifié: $isAuthenticated
Token: ${_token != null ? 'Oui (${_token!.substring(0, min(20, _token!.length))}...)' : 'Non'}
Utilisateur: ${_currentUser != null ? 'Oui (${_currentUser!.name})' : 'Non'}
URL de base: ${ApiConfig.baseUrl}
=======================
''');
  }
  
  int min(int a, int b) => a < b ? a : b;
}