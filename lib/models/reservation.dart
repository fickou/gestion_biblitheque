// lib/models/reservation.dart
import 'book.dart';
import 'user.dart';
import 'role.dart';

class Reservation {
  final String id;
  final Book? book;
  final User? user;
  final DateTime? reserveDate;
  final String status;
  final DateTime? createdAt;

  Reservation({
    required this.id,
    this.book,
    this.user,
    this.reserveDate,
    required this.status,
    this.createdAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final String id = (json['id'] ?? '').toString();
    final String status = (json['status'] ?? 'En attente').toString();
    
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
    DateTime? reserveDate;
    DateTime? createdAt;
    
    try {
      if (json['reserveDate'] != null) {
        final dateStr = json['reserveDate'].toString();
        if (dateStr.isNotEmpty) {
          reserveDate = DateTime.tryParse(dateStr);
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

    return Reservation(
      id: id,
      book: book,
      user: user,
      reserveDate: reserveDate,
      status: status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book?.toJson(),
      'user': user?.toJson(),
      'reserveDate': reserveDate?.toIso8601String(),
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'bookId': book?.id ?? '',
      'userId': user?.id ?? '',
      'reserveDate': reserveDate?.toIso8601String().split('T')[0],
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Getters
  bool get isValid => id.isNotEmpty && status.isNotEmpty;
  bool get isPending => status == 'En attente';
  bool get isConfirmed => status == 'Confirmée';
  bool get isCancelled => status == 'Annulée';
  bool get isExpired => status == 'Expirée';
  
  String get bookTitle => book?.title ?? 'Livre inconnu';
  String get userName => user?.name ?? 'Utilisateur inconnu';
  
  String? get formattedReserveDate {
    if (reserveDate == null) return null;
    return '${reserveDate!.day}/${reserveDate!.month}/${reserveDate!.year}';
  }

  // Méthode factory pour une réservation vide
  factory Reservation.empty() {
    return Reservation(
      id: '',
      status: 'En attente',
    );
  }

  @override
  String toString() {
    return 'Reservation{id: $id, livre: $bookTitle, utilisateur: $userName, status: $status}';
  }
}