import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'api_config.dart';

import '../models/user.dart' as model; // Alias pour éviter conflit avec Firebase User
import '../models/book.dart';
import '../models/emprunt.dart';
import '../models/reservation.dart';
import '../models/category.dart';
import '../models/role.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Méthode de sécurité pour bloquer les appels si déconnecté
  void _requireAuth() {
    if (currentUser == null) {
      throw Exception("Action non autorisée : Utilisateur déconnecté");
    }
  }

  @Deprecated('Use AuthService.signIn instead')
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

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          final bool success = data['success'] == true;
          
          if (success) {
            if (data['user'] != null) {
              try {
                var user = model.User.fromJson(Map<String, dynamic>.from(data['user']));
                
                return {
                  'success': true,
                  'user': user,
                  'message': data['message']?.toString() ?? 'Connexion réussie'
                };
              } catch (e) {
                return {
                  'success': false,
                  'message': 'Format utilisateur invalide'
                };
              }
            } else {
              return {
                'success': false,
                'message': 'Pas de données utilisateur dans la réponse'
              };
            }
          } else {
            final errorMessage = data['message']?.toString() 
                ?? data['error']?.toString()
                ?? 'Identifiants incorrects';
            
            return {
              'success': false,
              'message': errorMessage
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'Format de réponse invalide'
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Email ou mot de passe incorrect'
        };
      } else if (response.statusCode == 422) {
        return {
          'success': false,
          'message': 'Données de connexion invalides'
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur (${response.statusCode})',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
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
  }

  // Méthodes pour les livres
  Future<List<Book>> getBooks() async {
    try {
      final uri = ApiConfig.getBooksUri();
      
      final response = await http.get(
        uri,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
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
                  return null;
                }
              }).whereType<Book>().toList();
              return books;
            }
          } else if (data is List) {
            final books = data.map<Book?>((json) {
              try {
                return Book.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                return null;
              }
            }).whereType<Book>().toList();
            return books;
          }
          
          return [];
        } catch (e) {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Book?> getBookById(String id) async {
  try {
    
    final uri = ApiConfig.getBookUri(id);
    
    final response = await http.get(
      uri,
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      
      // VOICI LA CORRECTION : NETTOYER LA RÉPONSE DES WARNINGS PHP
      String cleanBody = response.body;
      
      // 1. Supprimer les balises HTML <br> et <b>
      cleanBody = cleanBody.replaceAll(RegExp(r'<br\s*/?>'), '');
      cleanBody = cleanBody.replaceAll(RegExp(r'<b>.*?</b>'), '');
      
      // 2. Chercher le début du JSON (première accolade {)
      final jsonStartIndex = cleanBody.indexOf('{');
      if (jsonStartIndex > 0) {
        cleanBody = cleanBody.substring(jsonStartIndex);
      }
      
      // 3. Chercher la fin du JSON (dernière accolade })
      final jsonEndIndex = cleanBody.lastIndexOf('}');
      if (jsonEndIndex != -1 && jsonEndIndex < cleanBody.length - 1) {
        cleanBody = cleanBody.substring(0, jsonEndIndex + 1);
      }
      
      // 4. Nettoyer les espaces et nouvelles lignes
      cleanBody = cleanBody.trim();
      
      try {
        final data = jsonDecode(cleanBody);
        return Book.fromJson(Map<String, dynamic>.from(data));
      } catch (e) {
        print('❌ Erreur parsing JSON nettoyé: $e');
        
        final start = response.body.indexOf('{');
        final end = response.body.lastIndexOf('}');
        
        if (start != -1 && end != -1 && end > start) {
          final extractedJson = response.body.substring(start, end + 1);
          
          String finalJson = extractedJson.replaceAll(RegExp(r'<[^>]*>'), '');
          
          finalJson = finalJson.replaceAll(RegExp(r'Deprecated[^\n]*'), '');
          
          finalJson = finalJson.trim();
          
          print('🔧 JSON extrait manuellement: $finalJson');
          
          try {
            final data = jsonDecode(finalJson);
            return Book.fromJson(Map<String, dynamic>.from(data));
          } catch (e2) {
            print('❌ Échec du parsing manuel: $e2');
          }
        }
        
        return null;
      }
    }
    return null;
    
  } catch (e) {
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
                return null;
              }
            }).whereType<Book>().toList();
          }
          return [];
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Méthodes pour les utilisateurs
  Future<List<model.User>> getUsers() async {
    try {
      final uri = ApiConfig.getUsersUri();
      
      final headers = _getHeaders();
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          if (data is List) {
            final users = data.map<model.User?>((json) {
              try {
                return model.User.fromJson(Map<String, dynamic>.from(json));
              } catch (e) {
                return null;
              }
            }).whereType<model.User>().toList();
            return users;
          }
          
          return [];
        } catch (e) {
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('Accès non autorisé');
      } else {
        return [];
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<model.User?> getUserById(String id) async {
    try {
      final response = await http.get(
        ApiConfig.getUserUri(id),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return model.User.fromJson(Map<String, dynamic>.from(data));
        } catch (e) {
          return null;
        }
      }
      return null;
    } catch (e) {
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
                return null;
              }
            }).whereType<Emprunt>().toList();
          }
          return [];
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
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
                return null;
              }
            }).whereType<Emprunt>().toList();
          }
          return [];
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
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
                return null;
              }
            }).whereType<Reservation>().toList();
          }
          return [];
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
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
                return null;
              }
            }).whereType<Reservation>().toList();
          }
          return [];
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
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
                return null;
              }
            }).whereType<Category>().toList();
          }
          return [];
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
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
                return null;
              }
            }).whereType<Role>().toList();
          }
          return [];
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
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
          return {};
        }
      }
      return {};
    } catch (e) {
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
          return [];
        }
      }
      return [];
    } catch (e) {
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
          return [];
        }
      }
      return [];
    } catch (e) {
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
          return [];
        }
      }
      return [];
    } catch (e) {
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

  // Méthodes de mise à jour (ajoutées)
  Future<Map<String, dynamic>> updateUserStatus(String userId, String status) async {
    try {
      final response = await http.put(
        ApiConfig.getUserUri(userId),
        headers: _getHeaders(),
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> updateReservationStatus(String reservationId, String status) async {
    try {
      final response = await http.put(
        ApiConfig.getReservationUri(reservationId),
        headers: _getHeaders(),
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;
    // Ajouter ces deux méthodes dans votre ApiService

  Future<Map<String, dynamic>> addBook(Map<String, dynamic> bookData) async {
    try {
      print('📚 Tentative d\'ajout d\'un livre: $bookData');
      
      final response = await http.post(
        ApiConfig.getBooksUri(),
        headers: _getHeaders(),
        body: jsonEncode(bookData),
      );

      print('📥 Réponse ajout livre - Status: ${response.statusCode}');
      print('📥 Réponse ajout livre - Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'message': data['message'] ?? 'Livre ajouté avec succès',
            'data': data,
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Livre ajouté avec succès',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de l\'ajout du livre (${response.statusCode})',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Erreur addBook: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateBooks(String id, Map<String, dynamic> bookData) async {
    try {
      print('📝 Tentative de mise à jour du livre ID: $id');
      print('📝 Données: $bookData');
      
      final response = await http.put(
        ApiConfig.getBookUri(id),
        headers: _getHeaders(),
        body: jsonEncode(bookData),
      );

      print('📥 Réponse mise à jour livre - Status: ${response.statusCode}');
      print('📥 Réponse mise à jour livre - Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'message': data['message'] ?? 'Livre modifié avec succès',
            'data': data,
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Livre modifié avec succès',
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Erreur lors de la modification du livre (${response.statusCode})',
            'statusCode': response.statusCode,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Erreur serveur (${response.statusCode})',
            'statusCode': response.statusCode,
          };
        }
      }
    } catch (e) {
      print('❌ Erreur updateBook: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }
  
}