# Bibliotech - Système de Gestion de Bibliothèque

**Bibliotech** est une solution numérique intégrée conçue pour moderniser et simplifier la gestion des ressources documentaires au sein d'une institution académique. Il s'agit d'une application multiplateforme permettant une interaction fluide entre les étudiants et le personnel de la bibliothèque.

---

## 🚀 Fonctionnalités Clés

### Interface Étudiant
- **Catalogue interactif** : Recherche de livres par titre, auteur ou catégorie.
- **Réservations** : Réserver des livres en temps réel.
- **Historique** : Suivi des emprunts actifs et passés.
- **Profil personnel** : Gestion des informations de compte et du matricule.

### Interface Administrateur / Bibliothécaire
- **Tableau de Bord** : Statistiques en temps réel sur le stock, les emprunts et les retards.
- **Gestion du Catalogue (CRUD)** : Ajout, modification et suppression de livres et catégories.
- **Gestion des Utilisateurs** : Suivi des inscriptions et validation des comptes.
- **Suivi des Retards** : Identification automatique des retours hors délais avec système de notifications.

---

## 🛠️ Architecture Technique

- **Frontend** : [Flutter](https://flutter.dev) (Dart)
  - Gestion d'état : `Riverpod`
  - Navigation : `GoRouter`
  - Design : `Material 3`
- **Backend** : PHP (API RESTful)
- **Base de Données** : MySQL / MariaDB
- **Authentification** : Firebase Auth
- **Stockage Cloud** : Firebase Storage (pour les couvertures de livres et avatars)

---

## ⚙️ Configuration et Installation

### 1. Base de Données
1. Installez un serveur MySQL local (WAMP, XAMPP ou Laragon).
2. Créez une base de données nommée `bibliotheque_db`.
3. Importez le fichier SQL de structure : `script/bibliotheque_db.sql`.

### 2. Backend (PHP API)
1. copier et coller le dossier `library_app` vers votre serveur local (ex : `C:\xampp\htdocs\library_app`).
2. Configurez la connexion à la base de données dans les fichiers modèles (si nécessaire).

### 3. Frontend (Flutter)
1. Installez le SDK Flutter.
2. Dans le dossier racine du projet, lancez :
   ```bash
   flutter pub get
   ```
3. Configurez l'URL de votre API dans `lib/config/api_url.dart` (ex: `http://localhost/library_app/api/`). Remplacez `localhost` par l'adresse IP de votre serveur.

### 4. Firebase
Assurez-vous que le fichier `google-services.json` (Android) ou `GoogleService-Info.plist` (iOS) est présent dans les dossiers respectifs pour l'authentification.

---

## 👥 Comptes de Test

Voici les comptes pré-configurés pour tester les différentes interfaces de l'application :

| Rôle | Email | Mot de passe |
| :--- | :--- | :--- |
| **Administrateur** | `admin@user.com` | 123456 |
| **Étudiant** | `fickou@gmail.com` | 123456 |

> [!NOTE]
> Les données de ces comptes sont déjà présentes dans la base de données MySQL fournie pour assurer la synchronisation avec les UID Firebase.

---

## 📁 Structure du Projet

```text
gestion_bibliotheque/
├── lib/               # Code source Flutter (UIs, Providers, Models)
├── library_app/       # Backend API PHP
│   └── api/           # Endpoints REST
├── script/            # Scripts SQL (Database schema)
├── assets/            # Images et ressources statiques
└── android/ios/etc.   # Configurations natives
```

---

## 📝 Auteurs
Projet développé dans le cadre d'un système de gestion de bibliothèque universitaire.
