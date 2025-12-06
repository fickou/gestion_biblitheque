// lib/models/book.dart - SANS DONNÉES STATIQUES
import 'category.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final bool available;
  final Category? category; // Rendre nullable
  final String year;
  final String? description;
  final int copies;
  final String? isbn;
  final DateTime? createdAt; // Rendre nullable
  final DateTime? updatedAt; // Rendre nullable
  final String? borrowDate;
  final String? returnDate;
  final String? status;
  final String? reserveDate;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.available,
    this.category, // Optionnel
    required this.year,
    this.description,
    required this.copies,
    this.isbn,
    this.createdAt, // Optionnel
    this.updatedAt, // Optionnel
    this.borrowDate,
    this.returnDate,
    this.status,
    this.reserveDate,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    // Extraction sécurisée
    final String id = (json['id'] ?? '').toString();
    final String title = (json['title'] ?? '').toString();
    final String author = (json['author'] ?? '').toString();
    final bool available = json['available'] == true || json['available'] == 1;
    final String year = (json['year'] ?? '').toString();
    final String? description = json['description']?.toString();
    final int copies = (json['copies'] is int) 
        ? json['copies'] 
        : int.tryParse(json['copies']?.toString() ?? '0') ?? 0;
    final String? isbn = json['isbn']?.toString();
    final String? borrowDate = json['borrowDate']?.toString();
    final String? returnDate = json['returnDate']?.toString();
    final String? status = json['status']?.toString();
    final String? reserveDate = json['reserveDate']?.toString();
    
    // Gestion de la catégorie
    Category? category;
    try {
      if (json['category'] != null) {
        if (json['category'] is Map<String, dynamic>) {
          category = Category.fromJson(json['category'] as Map<String, dynamic>);
        } else if (json['category'] is Map) {
          category = Category.fromJson(Map<String, dynamic>.from(json['category']));
        }
      } else if (json['categoryName'] != null) {
        category = Category(
          id: (json['categoryId'] ?? '').toString(),
          name: (json['categoryName'] ?? '').toString(),
          description: (json['categoryDescription'] ?? '').toString(),
        );
      }
    } catch (e) {
      print('Erreur création catégorie dans Book: $e');
    }
    
    // Gestion des dates
    DateTime? createdAt;
    DateTime? updatedAt;
    
    try {
      if (json['createdAt'] != null) {
        final dateStr = json['createdAt'].toString();
        if (dateStr.isNotEmpty) {
          createdAt = DateTime.tryParse(dateStr);
        }
      }
      
      if (json['updatedAt'] != null) {
        final dateStr = json['updatedAt'].toString();
        if (dateStr.isNotEmpty) {
          updatedAt = DateTime.tryParse(dateStr);
        }
      }
    } catch (e) {
      print('Erreur parsing dates dans Book: $e');
    }

    return Book(
      id: id,
      title: title,
      author: author,
      available: available,
      category: category,
      year: year,
      description: description,
      copies: copies,
      isbn: isbn,
      createdAt: createdAt,
      updatedAt: updatedAt,
      borrowDate: borrowDate,
      returnDate: returnDate,
      status: status,
      reserveDate: reserveDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'available': available,
      'category': category?.toJson(),
      'year': year,
      'description': description,
      'copies': copies,
      'isbn': isbn,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'borrowDate': borrowDate,
      'returnDate': returnDate,
      'status': status,
      'reserveDate': reserveDate,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'available': available ? 1 : 0,
      'categoryId': category?.id ?? '',
      'year': year,
      'description': description,
      'copies': copies,
      'isbn': isbn,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Getters utiles
  int get availableCopies => copies;
  bool get canBeBorrowed => available && copies > 0;
  bool get canBeReserved => !available || copies == 0;
  bool get isValid => id.isNotEmpty && title.isNotEmpty && author.isNotEmpty;
  
  String get displayTitle => title;
  String get displayAuthor => author;
  String get displayYear => year.isNotEmpty ? year : 'N/A';
  String get categoryName => category?.name ?? 'Non catégorisé';
  
  String get categoryIcon {
    final catName = category?.name?.toLowerCase() ?? '';
    if (catName.contains('info')) return '💻';
    if (catName.contains('math')) return '📐';
    if (catName.contains('physique')) return '⚛️';
    if (catName.contains('chimie')) return '🧪';
    if (catName.contains('biologie')) return '🧬';
    if (catName.contains('littérature')) return '📚';
    if (catName.contains('histoire')) return '📜';
    if (catName.contains('économie')) return '💰';
    return '📖';
  }

  String? get formattedCreatedAt {
    if (createdAt == null) return null;
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  String? get formattedUpdatedAt {
    if (updatedAt == null) return null;
    return '${updatedAt!.day}/${updatedAt!.month}/${updatedAt!.year}';
  }

  // Méthode factory pour un livre vide
  factory Book.empty() {
    return Book(
      id: '',
      title: '',
      author: '',
      available: false,
      category: null,
      year: '',
      copies: 0,
    );
  }

  @override
  String toString() {
    return 'Book{id: $id, title: $title, author: $author, available: $available}';
  }
}