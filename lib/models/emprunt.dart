// lib/models/emprunt.dart
import 'book.dart';
import 'user.dart';

class Emprunt {
  final String id;
  final String bookId;
  final String userId;
  final Book? book; // Optionnel - si les données du livre sont fournies
  final User? user; // Optionnel - si les données de l'utilisateur sont fournies
  final DateTime borrowDate;
  final DateTime? returnDate;
  final String status;
  final DateTime createdAt;
  
  // Champs directs de l'API (pour éviter les objets Book/User si non disponibles)
  final String bookTitle;
  final String? bookAuthor;
  final String? userName;
  final String? userEmail;

  Emprunt({
    required this.id,
    required this.bookId,
    required this.userId,
    this.book,
    this.user,
    required this.borrowDate,
    this.returnDate,
    required this.status,
    required this.createdAt,
    required this.bookTitle,
    this.bookAuthor,
    this.userName,
    this.userEmail,
  });

  factory Emprunt.fromJson(Map<String, dynamic> json) {
    
    try {
      // ID
      final String id = (json['id'] ?? '').toString();
      
      // IDs des relations
      final String bookId = (json['bookId'] ?? '').toString();
      final String userId = (json['userId'] ?? '').toString();
      
      // Status
      final String status = (json['status'] ?? 'En cours').toString();
      
      // Informations du livre (directes depuis JSON)
      final String bookTitle = (json['bookTitle'] ?? 'Titre inconnu').toString();
      final String? bookAuthor = json['bookAuthor']?.toString();
      
      // Informations utilisateur
      final String? userName = json['userName']?.toString();
      final String? userEmail = json['userEmail']?.toString();
      
      // Dates
      DateTime borrowDate;
      try {
        borrowDate = DateTime.parse(json['borrowDate']?.toString() ?? '2025-01-01');
      } catch (e) {
        print('⚠️ Erreur parsing borrowDate: $e');
        borrowDate = DateTime.now();
      }
      
      DateTime? returnDate;
      if (json['returnDate'] != null && json['returnDate'].toString().isNotEmpty) {
        try {
          returnDate = DateTime.parse(json['returnDate'].toString());
        } catch (e) {
          print('⚠️ Erreur parsing returnDate: $e');
          returnDate = null;
        }
      }
      
      DateTime createdAt;
      try {
        createdAt = DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String());
      } catch (e) {
        print('⚠️ Erreur parsing createdAt: $e');
        createdAt = DateTime.now();
      }
      
      // Création de l'objet Book si nécessaire
      Book? book;
      try {
        if (json['book'] != null) {
          if (json['book'] is Map<String, dynamic>) {
            book = Book.fromJson(json['book'] as Map<String, dynamic>);
          } else if (json['book'] is Map) {
            book = Book.fromJson(Map<String, dynamic>.from(json['book']));
          }
        }
      } catch (e) {
        print('⚠️ Erreur création Book: $e');
      }
      
      // Création de l'objet User si nécessaire
      User? user;
      try {
        if (json['user'] != null) {
          if (json['user'] is Map<String, dynamic>) {
            user = User.fromJson(json['user'] as Map<String, dynamic>);
          } else if (json['user'] is Map) {
            user = User.fromJson(Map<String, dynamic>.from(json['user']));
          }
        }
      } catch (e) {
        print('⚠️ Erreur création User: $e');
      }

      return Emprunt(
        id: id,
        bookId: bookId,
        userId: userId,
        book: book,
        user: user,
        borrowDate: borrowDate,
        returnDate: returnDate,
        status: status,
        createdAt: createdAt,
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        userName: userName,
        userEmail: userEmail,
      );
    } catch (e) {
      print('❌ Erreur grave parsing Emprunt: $e');
      print('❌ JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'book': book?.toJson(),
      'user': user?.toJson(),
      'borrowDate': borrowDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'bookTitle': bookTitle,
      'bookAuthor': bookAuthor,
      'userName': userName,
      'userEmail': userEmail,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'borrowDate': borrowDate.toIso8601String().split('T')[0],
      'returnDate': returnDate?.toIso8601String().split('T')[0],
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'bookTitle': bookTitle,
      'bookAuthor': bookAuthor,
    };
  }

  // Getters améliorés
  bool get isValid => id.isNotEmpty && bookTitle.isNotEmpty;
  
  bool get isLate {
    // Vérifier d'abord le statut
    if (status.toLowerCase() == 'en retard') return true;
    
    // Sinon vérifier la date
    if (returnDate != null && DateTime.now().isAfter(returnDate!)) {
      return true;
    }
    return false;
  }
  
  int get daysLate {
    if (!isLate || returnDate == null) return 0;
    final days = DateTime.now().difference(returnDate!).inDays;
    return days > 0 ? days : 0;
  }
  
  int get daysRemaining {
    if (status.toLowerCase() != 'en cours' || returnDate == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(returnDate!)) return 0;
    final diff = returnDate!.difference(now).inDays;
    return diff > 0 ? diff : 0;
  }
  
  // Utilisez les champs directs ou les objets
  String get displayBookTitle => book?.title ?? bookTitle;
  String get displayBookAuthor => book?.author ?? bookAuthor ?? 'Auteur inconnu';
  String get displayUserName => user?.name ?? userName ?? 'Utilisateur';
  
  String get formattedBorrowDate {
    return '${borrowDate.day}/${borrowDate.month}/${borrowDate.year}';
  }
  
  String? get formattedReturnDate {
    if (returnDate == null) return null;
    return '${returnDate!.day}/${returnDate!.month}/${returnDate!.year}';
  }

  // Méthode factory pour un emprunt vide
  factory Emprunt.empty() {
    return Emprunt(
      id: '',
      bookId: '',
      userId: '',
      borrowDate: DateTime.now(),
      status: 'En cours',
      createdAt: DateTime.now(),
      bookTitle: '',
    );
  }

  // Méthode factory pour un emprunt de test
  factory Emprunt.test() {
    return Emprunt(
      id: '1',
      bookId: '1',
      userId: '1',
      borrowDate: DateTime.now().subtract(const Duration(days: 5)),
      returnDate: DateTime.now().add(const Duration(days: 9)),
      status: 'En cours',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      bookTitle: 'Introduction à Python',
      bookAuthor: 'J. Dupont',
      userName: 'Jean Dupont',
      userEmail: 'jean@example.com',
    );
  }

  @override
  String toString() {
    return 'Emprunt{id: $id, livre: $bookTitle, utilisateur: $userName, status: $status, dates: $formattedBorrowDate - $formattedReturnDate}';
  }
}