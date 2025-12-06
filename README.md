# gestion_bibliotheque

Application Flutter de gestion d'une bibliothèque — front-end mobile/web.

**Résumé**

Cette application fournit une interface pour consulter le catalogue, gérer les emprunts et réservations, et administrer les utilisateurs et les livres. Le projet utilise Flutter, Riverpod pour la gestion d'état, GoRouter pour la navigation et Firebase pour certains services (configuration partielle fournie).

**Table des matières**

- **Prérequis**
- **Installation & exécution**
- **Configuration Firebase & variables d'environnement**
- **Structure du projet**
- **Sécurité & bonnes pratiques**
- **Tests**
- **Contribution**

## Prérequis

- Flutter (recommandé v3.7+ / SDK compatible avec `environment.sdk` dans `pubspec.yaml`)
- Dart SDK fourni par Flutter
- Un backend API (optionnel local : `http://10.0.2.2/library_api/api`) ou URL fournie via `--dart-define`
- (Optionnel) Projet Firebase si vous voulez utiliser l'authentification, Firestore ou Storage

## Installation & exécution

1. Récupérer les dépendances :

```powershell
flutter pub get
```

2. Lancer l'application (émulateur Android par défaut) :

```powershell
flutter run
```

3. Pour pointer l'application vers une API différente :

```powershell
flutter run --dart-define=API_BASE_URL='https://mon-api.example.com/api'
```

## Configuration Firebase & fichiers sensibles

- Le dépôt contient un fichier `firebase.json` et un exemple de `android/app/google-services.json` mais **les clés sensibles doivent rester en dehors du dépôt**.
- Remplacez localement `android/app/google-services.json` par celui téléchargé depuis la console Firebase **et ne le commitez pas**.
- Le projet `.gitignore` exclut par défaut `android/app/google-services.json` et `lib/firebase_options.dart` — conservez cette pratique.

Si vous utilisez Firebase pour l'authentification :

- Configurez l'application Android (package name + SHA-1) et/ou iOS dans la console Firebase.
- Restreignez la clé API dans Google Cloud Console (restrictions par application) si possible.

## Variables d'environnement et API

- L'URL de l'API peut être fournie au moment du build via `--dart-define=API_BASE_URL`.
- Exemple pour la build de production :

```powershell
flutter build apk --dart-define=API_BASE_URL='https://api.production.example.com'
```

## Structure du projet (rapide)

- `lib/main.dart` : point d'entrée, initialisation Firebase, ProviderScope.
- `lib/config/` : configuration (routes, api_config).
- `lib/models/` : modèles de données (`User`, `Book`, ...).
- `lib/providers/` : providers Riverpod (auth, library, ...).
- `lib/screens/` : écrans de l'application (login, signup, admin, catalogue, ...).
- `lib/services/` : services (ex : `ApiService` pour communiquer avec l'API).
- `lib/components/` & `lib/widgets/` : composants UI réutilisables.

## Sécurité & bonnes pratiques

- Ne jamais committer de clés API, secrets ou fichiers `google-services.json` contenant des clés.
- Restreindre les clés via la console Google Cloud et définir des règles de sécurité Firestore/Storage.
- Utiliser `String.fromEnvironment('API_BASE_URL')` (déjà partiellement implémenté) pour séparer environnements.
- Protéger les routes côté frontend (guards) et côté backend (vérifier les permissions et rôles).

## Tests

- Le projet contient un test widget d'exemple. Il est recommandé d'ajouter :
	- tests unitaires pour `ApiService` (mock HTTP),
	- tests pour les providers Riverpod,
	- tests d'intégration si nécessaire.

Exécuter les tests :

```powershell
flutter test
```

## Contribution

- Forkez le dépôt, créez une branche feature/bugfix, puis ouvrez une Pull Request.
- Respectez les conventions d'analyse (`flutter analyze`) et formatez avec `dart format`.

## Prochaines améliorations suggérées

- Autoriser l'authentification en écoutant `FirebaseAuth.instance.authStateChanges()` via un `StreamProvider` Riverpod.
- Protéger les routes avec des guards basés sur le rôle utilisateur.
- Ajouter caching local (`hive` ou `shared_preferences`) pour la résilience offline.
- Ajouter CI (GitHub Actions) pour `flutter analyze`, `flutter test` et builds.

---

Si tu veux, je peux :
- Implémenter le `StreamProvider` pour synchroniser l'état d'authentification,
- Ajouter un exemple de CI GitHub Actions,
- Ou rédiger un guide précis pour configurer Firebase en local.

Dis‑moi quelle action tu souhaites prioriser.
