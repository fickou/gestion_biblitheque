// lib/models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String matricule;
  final String role;
  final String avatarText;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.matricule,
    required this.role,
    required this.avatarText,
  });

  get status => null;
}

// Données utilisateur (à remplacer par les vraies données utilisateur)
final User currentUser = User(
  id: "1",
  name: "Jean Dupont",
  email: "jean.dupont@univ.edu",
  matricule: "2024-UFR-001",
  role: "Étudiant",
  avatarText: "JD",
);