// lib/models/admin_models.dart - SANS DONNÉES STATIQUES
import 'package:flutter/material.dart';
import 'emprunt.dart';
import 'reservation.dart';

/// Modèle pour les statistiques du dashboard
class DashboardStat {
  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final bool trendUp;
  final Color color;

  DashboardStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
    required this.trendUp,
    this.color = const Color(0xFF3B82F6),
  });
}

/// Modèle pour les activités récentes
class RecentActivity {
  final IconData icon;
  final String title;
  final String time;
  final Color iconColor;
  final String type;
  final String? userId;
  final String? bookId;
  final DateTime? date;

  RecentActivity({
    required this.icon,
    required this.title,
    required this.time,
    required this.iconColor,
    required this.type,
    this.userId,
    this.bookId,
    this.date,
  });
}

/// Modèle pour les livres les plus empruntés
class TopBook {
  final String id;
  final String title;
  final String author;
  final String categoryName;
  final int loanCount;
  final int copies;
  final bool available;

  TopBook({
    required this.id,
    required this.title,
    required this.author,
    required this.categoryName,
    required this.loanCount,
    required this.copies,
    required this.available,
  });

  factory TopBook.fromJson(Map<String, dynamic> json) {
    return TopBook(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      categoryName: (json['category'] ?? json['categoryName'] ?? '').toString(),
      loanCount: (json['loanCount'] ?? json['loans'] ?? 0) as int,
      copies: (json['copies'] ?? 1) as int,
      available: (json['available'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'categoryName': categoryName,
      'loanCount': loanCount,
      'copies': copies,
      'available': available,
    };
  }
}

/// Modèle pour les statistiques de catégorie
class CategoryStat {
  final String categoryName;
  final int totalBooks;
  final int availableBooks;
  final int uniqueBorrowers;

  CategoryStat({
    required this.categoryName,
    required this.totalBooks,
    required this.availableBooks,
    required this.uniqueBorrowers,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      categoryName: (json['categoryName'] ?? json['name'] ?? '').toString(),
      totalBooks: (json['totalBooks'] ?? json['bookCount'] ?? 0) as int,
      availableBooks: (json['availableBooks'] ?? 0) as int,
      uniqueBorrowers: (json['uniqueBorrowers'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'totalBooks': totalBooks,
      'availableBooks': availableBooks,
      'uniqueBorrowers': uniqueBorrowers,
    };
  }
}

/// Classe utilitaire pour transformer les données de l'API en modèles dashboard
class AdminDashboardData {
  /// Convertir les statistiques de l'API en DashboardStat
  static List<DashboardStat> statsFromApi(Map<String, dynamic> apiStats) {
    final totalBooks = (apiStats['totalBooks'] ?? 0) as int;
    final totalStudents = (apiStats['totalStudents'] ?? 0) as int;
    final borrowedBooks = (apiStats['borrowedBooks'] ?? 0) as int;
    final lateBooks = (apiStats['lateBooks'] ?? 0) as int;
    final newBooksThisMonth = (apiStats['newBooksThisMonth'] ?? 0) as int;
    final pendingReservations = (apiStats['pendingReservations'] ?? 0) as int;

    return [
      DashboardStat(
        title: 'Total Livres',
        value: totalBooks.toString(),
        icon: Icons.menu_book,
        trend: '+$newBooksThisMonth ce mois',
        trendUp: newBooksThisMonth > 0,
        color: const Color(0xFF3B82F6),
      ),
      DashboardStat(
        title: 'Étudiants Inscrits',
        value: totalStudents.toString(),
        icon: Icons.people,
        trend: '+5% ce mois',
        trendUp: true,
        color: const Color(0xFF10B981),
      ),
      DashboardStat(
        title: 'Livres Empruntés',
        value: borrowedBooks.toString(),
        icon: Icons.bookmark,
        trend: '$borrowedBooks actifs',
        trendUp: borrowedBooks > 0,
        color: const Color(0xFFF59E0B),
      ),
      DashboardStat(
        title: 'Livres en Retard',
        value: lateBooks.toString(),
        icon: Icons.access_time,
        trend: lateBooks > 0 ? 'À récupérer' : 'Aucun retard',
        trendUp: false,
        color: const Color(0xFFEF4444),
      ),
      DashboardStat(
        title: 'Nouveaux Livres',
        value: newBooksThisMonth.toString(),
        icon: Icons.add,
        trend: 'Ce mois',
        trendUp: newBooksThisMonth > 0,
        color: const Color(0xFF8B5CF6),
      ),
      DashboardStat(
        title: 'Réservations',
        value: pendingReservations.toString(),
        icon: Icons.list_alt,
        trend: 'En attente',
        trendUp: pendingReservations > 0,
        color: const Color(0xFFEC4899),
      ),
    ];
  }

  /// Convertir les activités récentes de l'API
  static List<RecentActivity> activitiesFromApi(List<dynamic> apiActivities) {
    final List<RecentActivity> activities = [];

    for (final activity in apiActivities) {
      final type = activity['type']?.toString() ?? '';
      final title = activity['title']?.toString() ?? '';
      final date = activity['date']?.toString();
      final userId = activity['userId']?.toString();
      final bookId = activity['bookId']?.toString();

      IconData icon;
      Color color;
      String time;

      switch (type) {
        case 'emprunt':
          icon = Icons.check_circle;
          color = const Color(0xFF10B981);
          time = _formatTimeAgo(date);
          break;
        case 'reservation':
          icon = Icons.person_add;
          color = const Color(0xFFF59E0B);
          time = _formatTimeAgo(date);
          break;
        case 'retard':
          icon = Icons.access_time;
          color = const Color(0xFFEF4444);
          time = 'À traiter';
          break;
        case 'new_book':
          icon = Icons.add_circle;
          color = const Color.fromARGB(255, 44, 80, 164);
          time = _formatTimeAgo(date);
          break;
        default:
          icon = Icons.info;
          color = const Color(0xFF6B7280);
          time = _formatTimeAgo(date);
      }

      activities.add(
        RecentActivity(
          icon: icon,
          title: title,
          time: time,
          iconColor: color,
          type: type,
          userId: userId,
          bookId: bookId,
          date: date != null ? DateTime.tryParse(date) : null,
        ),
      );
    }

    // Si moins de 5 activités, compléter avec des placeholders
    if (activities.length < 5) {
      final placeholderCount = 5 - activities.length;
      final placeholders = List.generate(placeholderCount, (index) {
        return RecentActivity(
          icon: Icons.info,
          title: 'Aucune activité récente',
          time: '-',
          iconColor: const Color(0xFF6B7280),
          type: 'placeholder',
        );
      });
      activities.addAll(placeholders);
    }

    return activities.take(5).toList();
  }

  /// Convertir les livres populaires de l'API
  static List<TopBook> topBooksFromApi(List<dynamic> apiTopBooks) {
    return apiTopBooks.map((bookData) {
      return TopBook.fromJson(bookData is Map<String, dynamic> 
          ? bookData 
          : Map<String, dynamic>.from(bookData));
    }).toList();
  }

  /// Convertir les statistiques de catégorie de l'API
  static List<CategoryStat> categoryStatsFromApi(List<dynamic> apiCategoryStats) {
    return apiCategoryStats.map((statData) {
      return CategoryStat.fromJson(statData is Map<String, dynamic> 
          ? statData 
          : Map<String, dynamic>.from(statData));
    }).toList();
  }

  /// Convertir les livres en retard de l'API
  static List<Emprunt> lateBooksFromApi(List<dynamic> apiLateBooks) {
    return apiLateBooks.map((bookData) {
      return Emprunt.fromJson(bookData is Map<String, dynamic> 
          ? bookData 
          : Map<String, dynamic>.from(bookData));
    }).toList();
  }

  /// Convertir les réservations en attente de l'API
  static List<Reservation> pendingReservationsFromApi(List<dynamic> apiReservations) {
    return apiReservations.map((reservationData) {
      return Reservation.fromJson(reservationData is Map<String, dynamic> 
          ? reservationData 
          : Map<String, dynamic>.from(reservationData));
    }).toList();
  }

  /// Méthode utilitaire pour formater la date "il y a..."
  static String _formatTimeAgo(String? dateString) {
    if (dateString == null) return 'Récemment';
    
    try {
      final date = DateTime.tryParse(dateString);
      if (date == null) return 'Récemment';
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 30) {
        return 'Il y a ${(difference.inDays / 30).floor()} mois';
      } else if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays} jours';
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours} heures';
      } else if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes} minutes';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return 'Récemment';
    }
  }

  /// Méthode pour générer des données de test (uniquement pour développement)
  static Map<String, dynamic> generateTestData() {
    return {
      'stats': {
        'totalBooks': 125,
        'totalStudents': 456,
        'borrowedBooks': 42,
        'lateBooks': 3,
        'newBooksThisMonth': 8,
        'pendingReservations': 5,
      },
      'activities': [
        {
          'type': 'emprunt',
          'title': 'Jean Dupont a emprunté "Introduction à Python"',
          'date': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'userId': '1',
          'bookId': '1',
        },
        {
          'type': 'reservation',
          'title': 'Marie Curie a réservé "Physique Quantique"',
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'userId': '2',
          'bookId': '3',
        },
        {
          'type': 'retard',
          'title': 'Livre en retard : "Base de Données"',
          'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'userId': '3',
          'bookId': '6',
        },
        {
          'type': 'new_book',
          'title': 'Nouveau livre ajouté : "Intelligence Artificielle"',
          'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'bookId': '7',
        },
      ],
      'topBooks': [
        {
          'id': '7',
          'title': 'Intelligence Artificielle',
          'author': 'R. Thomas',
          'categoryName': 'Informatique',
          'loanCount': 45,
          'copies': 1,
          'available': true,
        },
        {
          'id': '1',
          'title': 'Introduction à Python',
          'author': 'J. Dupont',
          'categoryName': 'Informatique',
          'loanCount': 38,
          'copies': 2,
          'available': true,
        },
        {
          'id': '5',
          'title': 'Algorithmique Avancée',
          'author': 'P. Dubois',
          'categoryName': 'Informatique',
          'loanCount': 32,
          'copies': 2,
          'available': true,
        },
      ],
      'categoryStats': [
        {
          'categoryName': 'Informatique',
          'totalBooks': 42,
          'availableBooks': 28,
          'uniqueBorrowers': 156,
        },
        {
          'categoryName': 'Mathématiques',
          'totalBooks': 25,
          'availableBooks': 18,
          'uniqueBorrowers': 89,
        },
        {
          'categoryName': 'Physique',
          'totalBooks': 18,
          'availableBooks': 12,
          'uniqueBorrowers': 67,
        },
      ],
    };
  }
}