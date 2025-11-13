// lib/models/book.dart
class Book {
  final String id;
  final String title;
  final String author;
  final bool available;
  final String category;
  final String year;
  final String? description;
  final int? copies;
  final String? borrowDate;
  final String? returnDate;
  final String? status;
  final String? reserveDate;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.available,
    required this.category,
    required this.year,
    this.description,
    this.copies,
    this.borrowDate,
    this.returnDate,
    this.status,
    this.reserveDate,
  });

  // Données pour le dashboard (nouveautés et populaires)
  static final List<Book> newBooks = [
    Book(
      id: "1",
      title: "Introduction à Python",
      author: "J. Dupont",
      available: true,
      category: "Informatique",
      year: "2023",
      description: "Un guide complet pour apprendre les bases de la programmation Python.",
      copies: 2,
    ),
    Book(
      id: "2",
      title: "Mathématiques Appliquées",
      author: "M. Martin",
      available: true,
      category: "Mathématiques",
      year: "2022",
      description: "Mathématiques pour les sciences appliquées.",
      copies: 1,
    ),
    Book(
      id: "3",
      title: "Physique Quantique",
      author: "A. Bernard",
      available: false,
      category: "Physique",
      year: "2021",
      description: "Introduction à la physique quantique moderne.",
      copies: 0,
    ),
    Book(
      id: "4",
      title: "Chimie Organique",
      author: "L. Petit",
      available: true,
      category: "Chimie",
      year: "2023",
      description: "Fondamentaux de la chimie organique.",
      copies: 3,
    ),
  ];

  static final List<Book> popularBooks = [
    Book(
      id: "5",
      title: "Algorithmique Avancée",
      author: "P. Dubois",
      available: true,
      category: "Informatique",
      year: "2023",
      description: "Algorithmes avancés et structures de données.",
      copies: 2,
    ),
    Book(
      id: "6",
      title: "Base de Données",
      author: "S. Laurent",
      available: false,
      category: "Informatique",
      year: "2022",
      description: "Conception et gestion de bases de données.",
      copies: 0,
    ),
    Book(
      id: "7",
      title: "Intelligence Artificielle",
      author: "R. Thomas",
      available: true,
      category: "Informatique",
      year: "2024",
      description: "Introduction à l'intelligence artificielle moderne.",
      copies: 1,
    ),
  ];

  // Données pour le catalogue
  static final List<Book> catalogueBooks = [
    Book(id: "1", title: "Introduction à Python", author: "J. Dupont", available: true, category: "Informatique", year: "2023"),
    Book(id: "2", title: "Mathématiques Appliquées", author: "M. Martin", available: true, category: "Mathématiques", year: "2022"),
    Book(id: "3", title: "Physique Quantique", author: "A. Bernard", available: false, category: "Physique", year: "2021"),
    Book(id: "4", title: "Chimie Organique", author: "L. Petit", available: true, category: "Chimie", year: "2023"),
    Book(id: "5", title: "Algorithmique Avancée", author: "P. Dubois", available: true, category: "Informatique", year: "2023"),
    Book(id: "6", title: "Base de Données", author: "S. Laurent", available: false, category: "Informatique", year: "2022"),
    Book(id: "7", title: "Intelligence Artificielle", author: "R. Thomas", available: true, category: "Informatique", year: "2024"),
    Book(id: "8", title: "Biologie Moléculaire", author: "C. Moreau", available: true, category: "Biologie", year: "2023"),
  ];

  // Données pour les emprunts
  static final List<Book> emprunts = [
    Book(
      id: "1",
      title: "Introduction à Python",
      author: "J. Dupont",
      available: false,
      category: "Informatique",
      year: "2023",
      borrowDate: "2025-01-05",
      returnDate: "2025-02-05",
      status: "En cours",
    ),
    Book(
      id: "2",
      title: "Base de Données",
      author: "S. Laurent",
      available: false,
      category: "Informatique",
      year: "2022",
      borrowDate: "2024-12-20",
      returnDate: "2025-01-10",
      status: "En retard",
    ),
    Book(
      id: "3",
      title: "Intelligence Artificielle",
      author: "R. Thomas",
      available: false,
      category: "Informatique",
      year: "2024",
      borrowDate: "2025-01-08",
      returnDate: "2025-02-08",
      status: "En cours",
    ),
  ];

  // Données pour les réservations
  static final List<Book> reservations = [
    Book(
      id: "1",
      title: "Physique Quantique",
      author: "A. Bernard",
      available: false,
      category: "Physique",
      year: "2021",
      reserveDate: "2025-01-10",
      status: "En attente",
    ),
    Book(
      id: "2",
      title: "Chimie Organique",
      author: "L. Petit",
      available: false,
      category: "Chimie",
      year: "2023",
      reserveDate: "2025-01-08",
      status: "Disponible",
    ),
  ];

  // Méthode utilitaire pour récupérer un livre par son ID
  static Book? getBookById(String id) {
    final allBooks = [...catalogueBooks, ...emprunts, ...reservations];
    try {
      return allBooks.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }
}