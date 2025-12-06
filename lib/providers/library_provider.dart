// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
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

  // Méthode d'authentification - adaptée à votre API
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        ApiConfig.getLoginUri(),
        // headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Adapté à la structure de votre API
        if (data['success'] == true) {
          _token = data['token'];
          
          // Convertir la réponse en User
          if (data['user'] != null) {
            _currentUser = User.fromJson(data['user']);
          }
          
          return {
            'success': true,
            'user': _currentUser,
            'token': _token,
            'message': 'Connexion réussie'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Identifiants incorrects'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur (${response.statusCode})'
        };
      }
    } catch (e) {
      print('Erreur de connexion: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
  }

  // Méthodes pour les livres - adaptées à votre API
  Future<List<Book>> getBooks() async {
    try {
      final response = await http.get(
        ApiConfig.getBooksUri(),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      }
      print('Erreur HTTP ${response.statusCode}: ${response.body}');
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
        final data = jsonDecode(response.body);
        return Book.fromJson(data);
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
        Uri.parse(ApiConfig.getUrl('books')),
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
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
        final data = jsonDecode(response.body);
        return User.fromJson(data);
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Emprunt.fromJson(json)).toList();
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Emprunt.fromJson(json)).toList();
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Emprunt.fromJson(json)).toList();
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
        Uri.parse(ApiConfig.getUrl('emprunts')),
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Reservation.fromJson(json)).toList();
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Reservation.fromJson(json)).toList();
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
        Uri.parse(ApiConfig.getUrl('reservations')),
        headers: _getAuthHeaders(),
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
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Role.fromJson(json)).toList();
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
        final data = jsonDecode(response.body);
        return data;
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
        final data = jsonDecode(response.body);
        return List<dynamic>.from(data);
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
        final data = jsonDecode(response.body);
        return List<dynamic>.from(data);
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
        final data = jsonDecode(response.body);
        return List<dynamic>.from(data);
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des stats par catégorie: $e');
      return [];
    }
  }

  // Méthodes utilitaires
  Map<String, String> _getAuthHeaders() {
    final headers = <String, String>{};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  bool get isAuthenticated => _token != null && _currentUser != null;
}