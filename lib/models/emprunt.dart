// lib/models/emprunt.dart
import 'book.dart';
import 'user.dart';
import 'role.dart';

class Emprunt {
  final String id;
  final Book? book;
  final User? user;
  final DateTime? borrowDate;
  final DateTime? returnDate;
  final String status;
  final DateTime? createdAt;

  Emprunt({
    required this.id,
    this.book,
    this.user,
    this.borrowDate,
    this.returnDate,
    required this.status,
    this.createdAt,
  });

  factory Emprunt.fromJson(Map<String, dynamic> json) {
    final String id = (json['id'] ?? '').toString();
    final String status = (json['status'] ?? 'En cours').toString();
    
    // Gestion du livre
    Book? book;
    try {
      if (json['book'] != null) {
        if (json['book'] is Map<String, dynamic>) {
          book = Book.fromJson(json['book'] as Map<String, dynamic>);
        } else if (json['book'] is Map) {
          book = Book.fromJson(Map<String, dynamic>.from(json['book']));
        }
      } else if (json['bookTitle'] != null) {
        book = Book(
          id: (json['bookId'] ?? '').toString(),
          title: (json['bookTitle'] ?? '').toString(),
          author: (json['bookAuthor'] ?? '').toString(),
          available: false,
          category: null,
          year: '0',
          description: '',
          copies: 0,
          isbn: '',
          createdAt: null,
          updatedAt: null,
        );
      }
    } catch (e) {
      print('Erreur création Book: $e');
    }
    
    // Gestion de l'utilisateur
    User? user;
    try {
      if (json['user'] != null) {
        if (json['user'] is Map<String, dynamic>) {
          user = User.fromJson(json['user'] as Map<String, dynamic>);
        } else if (json['user'] is Map) {
          user = User.fromJson(Map<String, dynamic>.from(json['user']));
        }
      } else if (json['userName'] != null) {
        user = User(
          id: (json['userId'] ?? '').toString(),
          name: (json['userName'] ?? '').toString(),
          email: (json['userEmail'] ?? '').toString(),
          matricule: (json['userMatricule'] ?? '').toString(),
          role: Role.empty(),
          avatarText: '',
          status: 'actif',
          createdAt: null,
          updatedAt: null,
        );
      }
    } catch (e) {
      print('Erreur création User: $e');
    }
    
    // Dates
    DateTime? borrowDate;
    DateTime? returnDate;
    DateTime? createdAt;
    
    try {
      if (json['borrowDate'] != null) {
        final dateStr = json['borrowDate'].toString();
        if (dateStr.isNotEmpty) {
          borrowDate = DateTime.tryParse(dateStr);
        }
      }
      
      if (json['returnDate'] != null) {
        final dateStr = json['returnDate'].toString();
        if (dateStr.isNotEmpty) {
          returnDate = DateTime.tryParse(dateStr);
        }
      }
      
      if (json['createdAt'] != null) {
        final dateStr = json['createdAt'].toString();
        if (dateStr.isNotEmpty) {
          createdAt = DateTime.tryParse(dateStr);
        }
      }
    } catch (e) {
      print('Erreur parsing dates: $e');
    }

    return Emprunt(
      id: id,
      book: book,
      user: user,
      borrowDate: borrowDate,
      returnDate: returnDate,
      status: status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book?.toJson(),
      'user': user?.toJson(),
      'borrowDate': borrowDate?.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'bookId': book?.id ?? '',
      'userId': user?.id ?? '',
      'borrowDate': borrowDate?.toIso8601String().split('T')[0],
      'returnDate': returnDate?.toIso8601String().split('T')[0],
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Getters
  bool get isValid => id.isNotEmpty && status.isNotEmpty;
  bool get isLate {
    if (status == 'En retard') return true;
    if (status == 'En cours' && returnDate != null && DateTime.now().isAfter(returnDate!)) {
      return true;
    }
    return false;
  }
  
  int get daysLate {
    if (!isLate || returnDate == null) return 0;
    return DateTime.now().difference(returnDate!).inDays;
  }
  
  int get daysRemaining {
    if (status != 'En cours' || returnDate == null) return 0;
    final diff = returnDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }
  
  String get bookTitle => book?.title ?? 'Livre inconnu';
  String get userName => user?.name ?? 'Utilisateur inconnu';
  
  String? get formattedBorrowDate {
    if (borrowDate == null) return null;
    return '${borrowDate!.day}/${borrowDate!.month}/${borrowDate!.year}';
  }
  
  String? get formattedReturnDate {
    if (returnDate == null) return null;
    return '${returnDate!.day}/${returnDate!.month}/${returnDate!.year}';
  }

  // Méthode factory pour un emprunt vide
  factory Emprunt.empty() {
    return Emprunt(
      id: '',
      status: 'En cours',
    );
  }

  @override
  String toString() {
    return 'Emprunt{id: $id, livre: $bookTitle, utilisateur: $userName, status: $status}';
  }
}