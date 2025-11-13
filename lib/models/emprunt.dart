// lib/models/emprunt.dart
class Emprunt {
  final String id;
  final String title;
  final String author;
  final String borrowDate;
  final String returnDate;
  final String status;

  Emprunt({
    required this.id,
    required this.title,
    required this.author,
    required this.borrowDate,
    required this.returnDate,
    required this.status,
  });
}

// Données des emprunts
final List<Emprunt> emprunts = [
  Emprunt(
    id: "1",
    title: "Introduction à Python",
    author: "J. Dupont",
    borrowDate: "2025-01-05",
    returnDate: "2025-02-05",
    status: "En cours",
  ),
  Emprunt(
    id: "2",
    title: "Base de Données",
    author: "S. Laurent",
    borrowDate: "2024-12-20",
    returnDate: "2025-01-10",
    status: "En retard",
  ),
  Emprunt(
    id: "3",
    title: "Intelligence Artificielle",
    author: "R. Thomas",
    borrowDate: "2025-01-08",
    returnDate: "2025-02-08",
    status: "En cours",
  ),
];