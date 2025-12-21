# Rapport de Projet : Système de Gestion de Bibliothèque "Bibliotech"

## 1. Introduction
Le projet **Bibliotech** est une solution numérique intégrée conçue pour moderniser et simplifier la gestion des ressources documentaires au sein d'une institution académique. Il s'agit d'une application multiplateforme (Mobile & Web) permettant une interaction fluide entre les étudiants et le personnel de la bibliothèque.

## 2. Objectifs du Projet
L'objectif principal est d'automatiser les processus manuels fastidieux et d'offrir une accessibilité accrue aux ressources :
*   **Accessibilité** : Permettre aux étudiants de consulter le catalogue et de réserver des livres depuis n'importe où.
*   **Efficacité** : Réduire le temps de traitement des emprunts et des retours pour les bibliothécaires.
*   **Suivi en Temps Réel** : Disposer d'une vue d'ensemble instantanée sur l'état du stock et les retards de retour.
*   **Statistiques** : Fournir des indicateurs de performance (livres les plus lus, fréquentation) pour optimiser les achats futurs.

## 3. Analyse Fonctionnelle
L'application se divise en deux interfaces distinctes selon le rôle de l'utilisateur :

### 3.1. Interface Étudiant
*   **Consultation du Catalogue** : Recherche par titre, auteur ou catégorie.
*   **Gestion des Réservations** : Possibilité de réserver un livre disponible ou en cours d'emprunt.
*   **Historique des Emprunts** : Suivi des livres actuellement en possession et des dates de retour prévues.
*   **Profil Personnel** : Gestion des informations de compte.

### 3.2. Interface Administrateur / Bibliothécaire
*   **Tableau de Bord (Dashboard)** : Visualisation des statistiques clés (total livres, emprunts actifs, retards).
*   **Gestion du Catalogue (CRUD)** : Ajout, modification et suppression de livres.
*   **Gestion des Utilisateurs** : Validation des comptes et suivi de l'activité.
*   **Suivi des Opérations** : Validation des retours de livres et gestion des amendes éventuelles pour les retards.

## 4. Architecture Technique
Le projet repose sur une architecture moderne de type Client-Serveur :

*   **Frontend (Application Mobile/Web)** : Développé avec le framework **Flutter**.
    *   **Gestion d'état** : Utilisation de **Riverpod** pour une réactivité optimale de l'interface.
    *   **Navigation** : **GoRouter** pour une gestion robuste des routes et des permissions.
    *   **UI/UX** : Design basé sur **Material 3** avec une approche "clean design".
*   **Backend (API)** : Développé en **PHP**.
    *   Fournit des points de terminaison RESTful pour la manipulation des données.
*   **Base de Données** : **MySQL** pour le stockage structuré des livres, utilisateurs et transactions.
*   **Services Cloud** : **Firebase Authentication** pour sécuriser l'accès et gérer les comptes utilisateurs de manière fiable.

## 5. Défis rencontrés et Solutions
*   **Synchronisation des Comptes** : Lier l'authentification Firebase à la base de données MySQL locale. Nous avons implémenté un service de synchronisation qui crée ou met à jour les données dans MySQL lors de la première connexion.
*   **Gestion des Données de l'API** : Nettoyage des réponses JSON pour ignorer les avertissements PHP potentiels, assurant la stabilité de l'application cliente.
*   **Expérience Utilisateur Offline** : Mise en place de mécanismes de gestion d'erreur robustes lorsque le serveur n'est pas joignable.

## 6. Conclusion et Perspectives
Le projet Bibliotech remplit tous les critères d'une application moderne de gestion. Pour la suite, nous envisageons d'ajouter :
*   Un système de notifications push pour rappeler les dates de retour.
*   Un scanner de codes-barres intégré pour accélérer l'inventaire.
*   Un mode hors-ligne avec synchronisation automatique.

---
*Rédigé dans le cadre de la présentation de projet de fin d'année.*
