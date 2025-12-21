import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/providers/auth_provider.dart';
import '/models/admin_models.dart';
import '/widgets/stat_card.dart';
import '/widgets/activity_item.dart';
import '/widgets/top_book_card.dart';
import '/services/api_service.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _AdminDashboardContent();
  }
}

class _AdminDashboardContent extends ConsumerStatefulWidget {
  const _AdminDashboardContent();

  @override
  ConsumerState<_AdminDashboardContent> createState() => __AdminDashboardContentState();
}

class __AdminDashboardContentState extends ConsumerState<_AdminDashboardContent> {
  final ApiService _apiService = ApiService();
  List<DashboardStat> stats = [];
  List<RecentActivity> recentActivities = [];
  List<TopBook> topBooks = [];
  List<CategoryStat> categoryStats = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Charger les statistiques du dashboard
      final dashboardResponse = await _apiService.getDashboardStats();
      
      // 2. Charger les livres populaires
      final topBooksData = await _apiService.getTopBooks(limit: 5);
      
      // 3. Charger les activités récentes
      final recentActivitiesData = await _apiService.getRecentActivities(limit: 10);
      
      // 4. Charger les statistiques par catégorie
      final categoryStatsData = await _apiService.getCategoryStats();
      
      // Transformer les données
      final transformedStats = _safeTransformStats(dashboardResponse);
      final transformedTopBooks = _safeTransformTopBooks(topBooksData);
      final transformedActivities = _safeTransformRecentActivities(recentActivitiesData);
      final transformedCategories = _safeTransformCategoryStats(categoryStatsData);
      
      setState(() {
        stats = transformedStats;
        topBooks = transformedTopBooks;
        recentActivities = transformedActivities;
        categoryStats = transformedCategories;
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Erreur lors du chargement du dashboard: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: $e';
        _isLoading = false;
      });
    }
  }

  // Méthodes SAFE de transformation (restent inchangées)
  List<DashboardStat> _safeTransformStats(Map<String, dynamic> data) {
    try {
      if (data.isEmpty) {
        return [];
      }
      
      List<DashboardStat> transformedStats = [];
      
      // Extraire les valeurs avec des fallbacks
      final totalBooks = _extractNumber(data, ['totalBooks', 'total_books', 'books', 'total']);
      final booksTrend = _extractNumber(data, ['booksTrend', 'books_trend', 'trend']);
      
      final totalUsers = _extractNumber(data, ['totalUsers', 'total_users', 'users']);
      final usersTrend = _extractNumber(data, ['usersTrend', 'users_trend']);
      
      final activeBorrowings = _extractNumber(data, ['activeBorrowings', 'active_borrowings', 'emprunts']);
      final borrowingsTrend = _extractNumber(data, ['borrowingsTrend', 'borrowings_trend']);
      
      final pendingReturns = _extractNumber(data, ['pendingReturns', 'pending_returns', 'retours']);
      final returnsTrend = _extractNumber(data, ['returnsTrend', 'returns_trend']);
      
      final pendingReservations = _extractNumber(data, ['pendingReservations', 'pending_reservations', 'reservations']);
      final reservationsTrend = _extractNumber(data, ['reservationsTrend', 'reservations_trend']);
      
      final lateBorrowings = _extractNumber(data, ['lateBorrowings', 'late_borrowings', 'retards']);
      final lateTrend = _extractNumber(data, ['lateTrend', 'late_trend']);
      
      // Ajouter les stats
      transformedStats.add(DashboardStat(
        title: 'Livres',
        value: totalBooks.toString(),
        icon: Icons.book,
        trend: '$booksTrend%',
        trendUp: booksTrend >= 0,
      ));
      
      transformedStats.add(DashboardStat(
        title: 'Utilisateurs',
        value: totalUsers.toString(),
        icon: Icons.people,
        trend: '$usersTrend%',
        trendUp: usersTrend >= 0,
      ));
      
      transformedStats.add(DashboardStat(
        title: 'Emprunts actifs',
        value: activeBorrowings.toString(),
        icon: Icons.description,
        trend: '$borrowingsTrend%',
        trendUp: borrowingsTrend >= 0,
      ));
      
      transformedStats.add(DashboardStat(
        title: 'Retours en attente',
        value: pendingReturns.toString(),
        icon: Icons.pending_actions,
        trend: '$returnsTrend%',
        trendUp: returnsTrend >= 0,
      ));
      
      transformedStats.add(DashboardStat(
        title: 'Réservations',
        value: pendingReservations.toString(),
        icon: Icons.event_note,
        trend: '$reservationsTrend%',
        trendUp: reservationsTrend >= 0,
      ));
      
      transformedStats.add(DashboardStat(
        title: 'En retard',
        value: lateBorrowings.toString(),
        icon: Icons.warning,
        trend: '$lateTrend%',
        trendUp: false,
      ));
      
      return transformedStats;
      
    } catch (e) {
      return [];
    }
  }

  List<RecentActivity> _safeTransformRecentActivities(List<dynamic> data) {
    try {
      List<RecentActivity> activities = [];
      
      for (var item in data) {
        try {
          if (item is Map<String, dynamic>) {
            activities.add(RecentActivity(
              icon: _getActivityIcon(item['type']?.toString() ?? ''),
              title: item['description']?.toString() ?? 
                     item['title']?.toString() ?? 'Activité',
              time: item['time']?.toString() ?? 
                    item['createdAt']?.toString() ?? 'Récemment',
              iconColor: _getActivityColor(item['type']?.toString() ?? ''),
              type: item['type']?.toString() ?? '',
            ));
          }
        } catch (e) {
          // Ignorer les erreurs
        }
      }
      
      return activities;
    } catch (e) {
      return [];
    }
  }

  List<TopBook> _safeTransformTopBooks(List<dynamic> data) {
    try {
      List<TopBook> books = [];
      
      for (var item in data) {
        try {
          if (item is Map<String, dynamic>) {
            books.add(TopBook(
              title: item['title']?.toString() ?? 'Titre inconnu',
              author: item['author']?.toString() ?? 'Auteur inconnu',
              loanCount: _parseInt(item['loanCount'] ?? item['loan_count'] ?? 0),
              id: item['id']?.toString() ?? '',
              categoryName: item['categoryName']?.toString() ?? 
                            item['category_name']?.toString() ?? 'Catégorie',
              copies: _parseInt(item['copies'] ?? 1),
              available: (item['available'] ?? false) as bool,
            ));
          }
        } catch (e) {
          // Ignorer les erreurs
        }
      }
      
      return books;
    } catch (e) {
      return [];
    }
  }

  List<CategoryStat> _safeTransformCategoryStats(List<dynamic> data) {
    try {
      List<CategoryStat> categories = [];
      
      for (var item in data) {
        try {
          if (item is Map<String, dynamic>) {
            categories.add(CategoryStat(
              categoryName: item['categoryName']?.toString() ?? 
                           item['category_name']?.toString() ?? 'Catégorie',
              totalBooks: _parseInt(item['totalBooks'] ?? item['total_books'] ?? 0),
              availableBooks: _parseInt(item['availableBooks'] ?? item['available_books'] ?? 0),
              uniqueBorrowers: _parseInt(item['uniqueBorrowers'] ?? item['unique_borrowers'] ?? 0),
            ));
          }
        } catch (e) {
          // Ignorer les erreurs
        }
      }
      
      return categories;
    } catch (e) {
      return [];
    }
  }

  // Méthodes utilitaires
  int _extractNumber(Map<String, dynamic> data, List<String> keys) {
    for (var key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        return _parseInt(value);
      }
    }
    return 0;
  }

  int _parseInt(dynamic value) {
    try {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    } catch (e) {
      return 0;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'emprunt':
      case 'borrowing':
        return Icons.check_circle;
      case 'reservation':
        return Icons.person_add;
      case 'retard':
      case 'late':
        return Icons.access_time;
      case 'new_book':
      case 'book_added':
        return Icons.add_circle;
      case 'return':
      case 'retour':
        return Icons.assignment_returned;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'emprunt':
      case 'borrowing':
        return const Color(0xFF10B981);
      case 'reservation':
        return const Color(0xFFF59E0B);
      case 'retard':
      case 'late':
        return const Color(0xFFEF4444);
      case 'new_book':
      case 'book_added':
        return const Color(0xFF2C50A4);
      case 'return':
      case 'retour':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer l'état d'authentification
    final isAuthenticated = ref.watch(isLoggedInProvider);
    final completeUserAsync = ref.watch(completeUserProvider);
    
    // Vérifier si l'utilisateur est connecté
    if (!isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return completeUserAsync.when(
      data: (completeUser) {
        if (completeUser == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Vérifier si l'utilisateur est admin
        final isAdmin = completeUser.isAdmin;
        if (!isAdmin) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Accès réservé aux administrateurs',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        
        return _buildDashboardContent(context, completeUser);
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF2C50A4),
            title: const Text("Admin Dashboard"),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 50),
                const SizedBox(height: 20),
                const Text(
                  'Erreur de chargement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref.refresh(completeUserProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, CompleteUser completeUser) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(completeUser),
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _errorMessage.isNotEmpty && stats.isEmpty
                      ? _buildErrorWidget()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWelcomeSection(completeUser),
                              const SizedBox(height: 24),
                              _buildStatsGrid(),
                              const SizedBox(height: 24),
                              _buildTwoColumnSection(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: const Color(0xFF2C50A4),
        tooltip: 'Rafraîchir les données',
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF2C50A4),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des données...',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C50A4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Réessayer'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CompleteUser completeUser) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Admin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C50A4),
                ),
              ),
              Text(
                '${completeUser.displayName} 👑',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: const Color(0xFF64748B),
            onPressed: () => context.go('/admin/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: const Color(0xFFEF4444),
            onPressed: () {
              // Déconnexion via provider
              ref.read(authServiceProvider).signOut();
              context.go('/login');
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(CompleteUser completeUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Bonjour, ${completeUser.displayName}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C50A4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Voici un résumé de votre bibliothèque aujourd\'hui.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        if (_errorMessage.isNotEmpty && stats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.circle, size: 8, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                'Connecté • ${completeUser.email ?? ''} • ${completeUser.role}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    if (stats.isEmpty) {
      return _buildEmptyStats();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1024) {
          crossAxisCount = 6;
        } else if (constraints.maxWidth > 768) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return StatCard(
              title: stat.title,
              value: stat.value,
              icon: stat.icon,
              trend: stat.trend,
              trendUp: stat.trendUp,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune statistique disponible',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les données seront disponibles après les premières activités',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C50A4),
              foregroundColor: Colors.white,
            ),
            child: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 768) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRecentActivitiesCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildTopBooksCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildRecentActivitiesCard(),
              const SizedBox(height: 16),
              _buildTopBooksCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildRecentActivitiesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFE2E8F0).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: const Color(0xFF2C50A4), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Dernières Activités',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  color: const Color(0xFF64748B),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
          if (recentActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.notifications_none, size: 48, color: const Color(0xFFCBD5E1)),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune activité récente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadData,
                      child: const Text('Vérifier les nouvelles activités'),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: recentActivities.map((activity) {
                  return ActivityItem(
                    icon: activity.icon,
                    title: activity.title,
                    time: activity.time,
                    iconColor: activity.iconColor,
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTopBooksCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFE2E8F0).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_upward, color: const Color(0xFF2C50A4), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Livres les Plus Empruntés',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  color: const Color(0xFF64748B),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
          if (topBooks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.book_outlined, size: 48, color: const Color(0xFFCBD5E1)),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun livre emprunté',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/catalogue'),
                      child: const Text('Voir le catalogue'),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: topBooks.map((book) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TopBookCard(
                      title: book.title,
                      author: book.author,
                      loans: book.loanCount,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2C50A4),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Livres'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outlined), activeIcon: Icon(Icons.people), label: 'Étudiants'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Emprunts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/admin/dashboard') return 0;
    if (location == '/admin/books') return 1;
    if (location == '/admin/etudiants') return 2;
    if (location == '/admin/emprunts') return 3;
    if (location == '/admin/settings') return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/books');
        break;
      case 2:
        context.go('/admin/etudiants');
        break;
      case 3:
        context.go('/admin/emprunts');
        break;
      case 4:
        context.go('/profiladmin');
        break;
    }
  }
}