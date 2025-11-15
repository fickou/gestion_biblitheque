// Créez le fichier : lib/providers/auth_provider.dart
import 'package:flutter_riverpod/legacy.dart';
/// Un StateProvider est le type de provider le plus simple.
/// Il est parfait pour stocker des états simples comme un booléen, un nombre, ou une chaîne de caractères.
/// Ici, il va stocker 'true' si l'utilisateur est connecté, et 'false' sinon.
final authStateProvider = StateProvider<bool>((ref) {
  // La valeur initiale de notre état.
  // Au démarrage de l'app, l'utilisateur n'est pas connecté.
  return false;
});