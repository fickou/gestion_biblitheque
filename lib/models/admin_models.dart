import 'package:flutter/material.dart';
import 'book.dart';

/// Modèle pour les statistiques du dashboard
class DashboardStat {
  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final bool trendUp;

  DashboardStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
    required this.trendUp,
  });
}

/// Modèle pour les activités récentes
class RecentActivity {
  final IconData icon;
  final String title;
  final String time;
  final Color iconColor;

  RecentActivity({
    required this.icon,
    required this.title,
    required this.time,
    required this.iconColor,
  });
}

/// Modèle pour les livres les plus empruntés
class TopBook {
  final String title;
  final String author;
  final int loans;

  TopBook({
    required this.title,
    required this.author,
    required this.loans,
  });

  factory TopBook.fromJson(Map<String, dynamic> json) {
    return TopBook(
      title: json['title'] as String,
      author: json['author'] as String,
      loans: json['loans'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'loans': loans,
    };
  }
}

/// Classe contenant toutes les données du dashboard admin avec calculs réels
class AdminDashboardData {
  /// Liste des statistiques du dashboard basées sur les données réelles
  static List<DashboardStat> getStats() {
    // Calculs basés sur vos modèles
    final totalBooks = Book.catalogueBooks.length;
    final borrowedBooks = Book.emprunts.length;
    final lateBooks = Book.emprunts.where((e) => e.status == "En retard").length;
    final newBooksThisMonth = Book.newBooks.length;
    final pendingReservations = Book.reservations.length;
    
    // Pour les étudiants, on simule car vous n'avez pas de liste d'étudiants
    final totalStudents = 456; // À remplacer par vos données réelles

    return [
      DashboardStat(
        title: 'Total Livres',
        value: '$totalBooks',
        icon: Icons.menu_book,
        trend: '+${Book.newBooks.length} ce mois',
        trendUp: true,
      ),
      DashboardStat(
        title: 'Étudiants Inscrits',
        value: '$totalStudents',
        icon: Icons.people,
        trend: '+5% ce mois',
        trendUp: true,
      ),
      DashboardStat(
        title: 'Livres Empruntés',
        value: '$borrowedBooks',
        icon: Icons.bookmark,
        trend: '${Book.emprunts.length} actifs',
        trendUp: borrowedBooks > 0,
      ),
      DashboardStat(
        title: 'Livres en Retard',
        value: '$lateBooks',
        icon: Icons.access_time,
        trend: '${lateBooks > 0 ? 'À récupérer' : 'Aucun retard'}',
        trendUp: false,
      ),
      DashboardStat(
        title: 'Nouveaux Ajouts',
        value: '$newBooksThisMonth',
        icon: Icons.add_circle,
        trend: 'Ce mois',
        trendUp: true,
      ),
      DashboardStat(
        title: 'Réservations',
        value: '$pendingReservations',
        icon: Icons.list_alt,
        trend: 'En attente',
        trendUp: pendingReservations > 0,
      ),
    ];
  }

  /// Liste des activités récentes basées sur les données réelles
  static List<RecentActivity> getRecentActivities() {
    // Utilise les données réelles de vos modèles
    final recentEmprunts = Book.emprunts.take(2).toList();
    final recentReservations = Book.reservations.take(1).toList();
    final newBooks = Book.newBooks.take(1).toList();

    List<RecentActivity> activities = [];

    // Ajouter les emprunts récents
    if (recentEmprunts.isNotEmpty) {
      activities.addAll([
        RecentActivity(
          icon: Icons.check_circle,
          title: '${recentEmprunts.first.author} a emprunté \'${recentEmprunts.first.title}\'',
          time: 'Aujourd\'hui',
          iconColor: const Color(0xFF10B981),
        ),
        if (recentEmprunts.length > 1)
          RecentActivity(
            icon: Icons.refresh,
            title: 'Retour du livre \'${recentEmprunts[1].title}\'',
            time: 'Aujourd\'hui',
            iconColor: const Color(0xFF3B82F6),
          ),
      ]);
    }

    // Ajouter les nouveaux livres
    if (newBooks.isNotEmpty) {
      activities.add(
        RecentActivity(
          icon: Icons.add_circle,
          title: 'Nouveau livre ajouté : \'${newBooks.first.title}\'',
          time: 'Cette semaine',
          iconColor: const Color.fromARGB(255, 44, 80, 164),
        ),
      );
    }

    // Ajouter les réservations
    if (recentReservations.isNotEmpty) {
      activities.add(
        RecentActivity(
          icon: Icons.person_add,
          title: 'Nouvelle réservation : \'${recentReservations.first.title}\'',
          time: 'Cette semaine',
          iconColor: const Color(0xFFF59E0B),
        ),
      );
    }

    // Ajouter les alertes de retard
    final lateBooks = Book.emprunts.where((e) => e.status == "En retard").toList();
    if (lateBooks.isNotEmpty) {
      activities.add(
        RecentActivity(
          icon: Icons.access_time,
          title: 'Alerte : \'${lateBooks.first.title}\' est en retard',
          time: 'À traiter',
          iconColor: const Color(0xFFEF4444),
        ),
      );
    }

    // Si pas assez d'activités, compléter avec des données par défaut
    if (activities.length < 5) {
      activities.addAll([
        RecentActivity(
          icon: Icons.person_add,
          title: 'Nouvel étudiant inscrit',
          time: 'Cette semaine',
          iconColor: const Color(0xFFF59E0B),
        ),
        RecentActivity(
          icon: Icons.library_books,
          title: 'Mise à jour du catalogue',
          time: 'Cette semaine',
          iconColor: const Color(0xFF8B5CF6),
        ),
      ]);
    }

    return activities.take(5).toList();
  }

  /// Liste des livres les plus empruntés basée sur les données réelles
  static List<TopBook> getTopBooks() {
    // Combiner les livres populaires et les emprunts pour créer un classement
    final Map<String, int> bookLoans = {};

    // Compter les emprunts par livre
    for (final emprunt in Book.emprunts) {
      bookLoans.update(
        emprunt.title,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    // Ajouter les livres populaires avec un compteur basé sur leur position
    for (int i = 0; i < Book.popularBooks.length; i++) {
      final book = Book.popularBooks[i];
      final baseLoans = 30 - (i * 5); // Simulation basée sur la popularité
      bookLoans.update(
        book.title,
        (value) => value + baseLoans,
        ifAbsent: () => baseLoans,
      );
    }

    // Ajouter les nouveaux livres avec un compteur modéré
    for (int i = 0; i < Book.newBooks.length; i++) {
      final book = Book.newBooks[i];
      final baseLoans = 15 - (i * 3);
      bookLoans.update(
        book.title,
        (value) => value + baseLoans,
        ifAbsent: () => baseLoans,
      );
    }

    // Créer la liste des livres triés par nombre d'emprunts
    final sortedBooks = bookLoans.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedBooks.take(5).map((entry) {
      // Trouver l'auteur du livre
      final book = Book.catalogueBooks.firstWhere(
        (b) => b.title == entry.key,
        orElse: () => Book.catalogueBooks.first,
      );

      return TopBook(
        title: entry.key,
        author: book.author,
        loans: entry.value,
      );
    }).toList();
  }

  /// Méthodes utilitaires pour les calculs statistiques
  static Map<String, dynamic> getDashboardMetrics() {
    return {
      'totalBooks': Book.catalogueBooks.length,
      'borrowedBooks': Book.emprunts.length,
      'lateBooks': Book.emprunts.where((e) => e.status == "En retard").length,
      'availableBooks': Book.catalogueBooks.where((b) => b.available).length,
      'newBooksThisMonth': Book.newBooks.length,
      'pendingReservations': Book.reservations.length,
      'popularBooksCount': Book.popularBooks.length,
    };
  }

  /// Récupérer les livres en retard
  static List<Book> getLateBooks() {
    return Book.emprunts.where((e) => e.status == "En retard").toList();
  }

  /// Récupérer les réservations en attente
  static List<Book> getPendingReservations() {
    return Book.reservations.where((r) => r.status == "En attente").toList();
  }

  /// Récupérer les livres récemment ajoutés
  static List<Book> getRecentlyAddedBooks() {
    return Book.newBooks;
  }
}