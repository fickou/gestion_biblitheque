// lib/models/reservation.dart
class Reservation {
  final String id;
  final String title;
  final String author;
  final String reserveDate;
  final String status;

  Reservation({
    required this.id,
    required this.title,
    required this.author,
    required this.reserveDate,
    required this.status,
  });
}

// Données des réservations
final List<Reservation> reservations = [
  Reservation(
    id: "1",
    title: "Physique Quantique",
    author: "A. Bernard",
    reserveDate: "2025-01-10",
    status: "En attente",
  ),
  Reservation(
    id: "2",
    title: "Chimie Organique",
    author: "L. Petit",
    reserveDate: "2025-01-08",
    status: "Disponible",
  ),
];