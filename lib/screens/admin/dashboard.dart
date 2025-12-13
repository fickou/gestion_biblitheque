import 'package:flutter/material.dart';
import '/models/admin_models.dart';
import '/widgets/notif.dart';
import '/widgets/stat_card.dart';
import '/widgets/activity_item.dart';
import '/widgets/top_book_card.dart';
import 'package:go_router/go_router.dart';
import '/services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  List<DashboardStat> stats = [];
  List<RecentActivity> recentActivities = [];
  List<TopBook> topBooks = [];
  List<CategoryStat> categoryStats = [];
  Map<String, dynamic> dashboardData = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    // Vérifier d'abord l'authentification
    if (!_apiService.isAuthenticated) {
      setState(() {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
      });
      
      // Rediriger vers la page de login après un court délai
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/login');
        }
      });
      return;
    }

    // Vérifier que l'utilisateur est admin
    final currentUser = _apiService.currentUser;
    if (currentUser?.role.name.toLowerCase() != 'admin' && 
        currentUser?.role.name.toLowerCase() != 'administrateur' && 
        currentUser?.role.name.toLowerCase() != 'bibliothécaire') {
      setState(() {
        _errorMessage = 'Accès réservé aux administrateurs';
        _isLoading = false;
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/dashboard'); // Rediriger vers le dashboard utilisateur
        }
      });
      return;
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('📊 Chargement des données du dashboard...');
      
      // 1. Charger les statistiques du dashboard
      final dashboardResponse = await _apiService.getDashboardStats();
      print('✅ Statistiques chargées: ${dashboardResponse.isNotEmpty}');
      
      // 2. Charger les livres populaires
      final topBooksData = await _apiService.getTopBooks(limit: 5);
      print('✅ Top livres chargés: ${topBooksData.length}');
      
      // 3. Charger les activités récentes
      final recentActivitiesData = await _apiService.getRecentActivities(limit: 10);
      print('✅ Activités récentes: ${recentActivitiesData.length}');
      
      // 4. Charger les statistiques par catégorie
      final categoryStatsData = await _apiService.getCategoryStats();
      print('✅ Stats catégories: ${categoryStatsData.length}');
      
      // Transformer les données
      setState(() {
        dashboardData = dashboardResponse;
        stats = _transformStats(dashboardResponse);
        topBooks = _transformTopBooks(topBooksData);
        recentActivities = _transformRecentActivities(recentActivitiesData);
        categoryStats = _transformCategoryStats(categoryStatsData);
        _isLoading = false;
      });
      
      print('🎉 Dashboard chargé avec succès');
      
    } catch (e) {
      print('❌ Erreur lors du chargement du dashboard: $e');
      
      // Essayer de charger les données de test
      _loadTestData();
    }
  }

  void _loadTestData() {
    print('🔄 Utilisation des données de test...');
    final testData = AdminDashboardData.generateTestData();
    
    setState(() {
      stats = AdminDashboardData.statsFromApi(testData['stats']);
      recentActivities = AdminDashboardData.activitiesFromApi(testData['activities']);
      topBooks = AdminDashboardData.topBooksFromApi(testData['topBooks']);
      categoryStats = AdminDashboardData.categoryStatsFromApi(testData['categoryStats']);
      _isLoading = false;
      _errorMessage = 'Mode développement : Données de test affichées';
    });
  }

  List<DashboardStat> _transformStats(Map<String, dynamic> data) {
    try {
      if (data.isEmpty) {
        return AdminDashboardData.generateTestData()['stats']
            .cast<DashboardStat>();
      }
      
      // Transformer le format API en DashboardStat
      List<DashboardStat> transformedStats = [];
      
      // Total des livres
      transformedStats.add(DashboardStat(
        title: 'Livres',
        value: (data['total_books'] ?? data['books'] ?? '0').toString(),
        icon: Icons.book,
        trend: '${data['books_trend'] ?? '0'}%',
        trendUp: (data['books_trend'] ?? 0) >= 0,
      ));
      
      // Utilisateurs
      transformedStats.add(DashboardStat(
        title: 'Utilisateurs',
        value: (data['total_users'] ?? data['users'] ?? '0').toString(),
        icon: Icons.people,
        trend: '${data['users_trend'] ?? '0'}%',
        trendUp: (data['users_trend'] ?? 0) >= 0,
      ));
      
      // Emprunts actifs
      transformedStats.add(DashboardStat(
        title: 'Emprunts actifs',
        value: (data['active_borrowings'] ?? data['emprunts'] ?? '0').toString(),
        icon: Icons.description,
        trend: '${data['borrowings_trend'] ?? '0'}%',
        trendUp: (data['borrowings_trend'] ?? 0) >= 0,
      ));
      
      // Retours en attente
      transformedStats.add(DashboardStat(
        title: 'Retours en attente',
        value: (data['pending_returns'] ?? data['retours'] ?? '0').toString(),
        icon: Icons.pending_actions,
        trend: '${data['returns_trend'] ?? '0'}%',
        trendUp: (data['returns_trend'] ?? 0) >= 0,
      ));
      
      // Réservations en attente
      transformedStats.add(DashboardStat(
        title: 'Réservations',
        value: (data['pending_reservations'] ?? data['reservations'] ?? '0').toString(),
        icon: Icons.event_note,
        trend: '${data['reservations_trend'] ?? '0'}%',
        trendUp: (data['reservations_trend'] ?? 0) >= 0,
      ));
      
      // Emprunts en retard
      transformedStats.add(DashboardStat(
        title: 'En retard',
        value: (data['late_borrowings'] ?? data['retards'] ?? '0').toString(),
        icon: Icons.warning,
        trend: '${data['late_trend'] ?? '0'}%',
        trendUp: false, // Toujours négatif pour les retards
      ));
      
      return transformedStats;
    } catch (e) {
      print('⚠️ Erreur transformation stats: $e');
      return AdminDashboardData.generateTestData()['stats']
          .cast<DashboardStat>();
    }
  }

  List<RecentActivity> _transformRecentActivities(List<dynamic> data) {
    try {
      if (data.isEmpty) {
        return AdminDashboardData.generateTestData()['activities']
            .cast<RecentActivity>();
      }
      
      return data.map<RecentActivity>((item) {
        if (item is Map<String, dynamic>) {
          return RecentActivity(
            icon: _getActivityIcon(item['type']?.toString() ?? ''),
            title: item['description']?.toString() ?? 
                   item['title']?.toString() ?? 'Activité',
            time: item['time']?.toString() ?? 
                  item['createdAt']?.toString() ?? 'Récemment',
            iconColor: _getActivityColor(item['type']?.toString() ?? ''),
            type: item['type']?.toString() ?? '',

          );
        }
        return RecentActivity(
          icon: Icons.info,
          title: 'Activité système',
          time: 'Récemment',
          iconColor: const Color(0xFF6B7280),
          type: String.fromCharCode(0xFF6B7280)
        );
      }).toList();
    } catch (e) {
      print('⚠️ Erreur transformation activités: $e');
      return AdminDashboardData.generateTestData()['activities']
          .cast<RecentActivity>();
    }
  }

  List<TopBook> _transformTopBooks(List<dynamic> data) {
    try {
      if (data.isEmpty) {
        return AdminDashboardData.generateTestData()['topBooks']
            .cast<TopBook>();
      }
      
      return data.map<TopBook>((item) {
        if (item is Map<String, dynamic>) {
          return TopBook(
            title: item['title']?.toString() ?? 'Titre inconnu',
            author: item['author']?.toString() ?? 'Auteur inconnu',
            loanCount: (item['loan_count'] ?? 
                       item['borrowings'] ?? 
                       item['count'] ?? 0).toInt(),
            id: item['id']?.toString() ?? '',
            categoryName: item['category_name']?.toString() ?? 
                          item['category']?.toString() ?? 'Catégorie inconnue',
            copies: (item['copies'] ?? 0).toInt(),
            available: (item['available'] ?? false) as bool,
          );
        }
        return TopBook(
          id: '',
          title: 'Livre inconnu',
          author: 'Auteur inconnu',
          categoryName: 'Catégorie inconnue',
          copies: 0,
          available: false,
          loanCount: 0,
        );
      }).toList();
    } catch (e) {
      print('⚠️ Erreur transformation top livres: $e');
      return AdminDashboardData.generateTestData()['topBooks']
          .cast<TopBook>();
    }
  }

  List<CategoryStat> _transformCategoryStats(List<dynamic> data) {
    try {
      if (data.isEmpty) {
        return AdminDashboardData.generateTestData()['categoryStats']
            .cast<CategoryStat>();
      }
      
      return data.map<CategoryStat>((item) {
        if (item is Map<String, dynamic>) {
          return CategoryStat(
            categoryName: item['category_name']?.toString() ?? 
                         item['category']?.toString() ?? 'Catégorie',
            totalBooks: (item['total_books'] ?? 
                        item['count'] ?? 0).toInt(),
            availableBooks: (item['available_books'] ?? 
                           item['available'] ?? 0).toInt(),
            uniqueBorrowers: (item['unique_borrowers'] ?? 
                            item['borrowers'] ?? 0).toInt(),
          );
        }
        return CategoryStat(
          categoryName: 'Catégorie',
          totalBooks: 0,
          availableBooks: 0,
          uniqueBorrowers: 0
        );
      }).toList();
    } catch (e) {
      print('⚠️ Erreur transformation stats catégories: $e');
      return AdminDashboardData.generateTestData()['categoryStats']
          .cast<CategoryStat>();
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
        return const Color.fromARGB(255, 44, 80, 164);
      case 'return':
      case 'retour':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                              _buildWelcomeSection(),
                              const SizedBox(height: 24),
                              _buildStatsGrid(),
                              const SizedBox(height: 24),
                              _buildTwoColumnSection(),
                              const SizedBox(height: 24),
                              _buildChartSection(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _errorMessage.isNotEmpty && stats.isEmpty
          ? FloatingActionButton(
              onPressed: _loadData,
              backgroundColor: const Color.fromARGB(255, 44, 80, 164),
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color.fromARGB(255, 44, 80, 164),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des données...',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF64748B),
            ),
          ),
          if (_apiService.currentUser != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Connecté en tant que ${_apiService.currentUser!.name}',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
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
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 44, 80, 164),
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
                if (!_apiService.isAuthenticated)
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.login, size: 20),
                        SizedBox(width: 8),
                        Text('Se connecter'),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currentUser = _apiService.currentUser;
    final isAdmin = currentUser?.role.name.toLowerCase() == 'admin' || 
                   currentUser?.role.name.toLowerCase() == 'administrateur'|| 
                   currentUser?.role.name.toLowerCase() == 'bibliothécaire';
    
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
              Text(
                'Dashboard Admin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 44, 80, 164),
                ),
              ),
              if (currentUser != null)
                Text(
                  '${currentUser.name} ${isAdmin ? '👑' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (_apiService.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.person),
              color: const Color.fromARGB(255, 44, 80, 164),
              onPressed: () => context.go('/profil'),
              tooltip: 'Mon profil',
            ),
          NotificationIconWithBadge(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: const Color(0xFF64748B),
            onPressed: () => context.go('/admin/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: const Color(0xFFEF4444),
            onPressed: () {
              _apiService.logout();
              context.go('/login');
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final userName = _apiService.currentUser?.name ?? 'Admin';
    final isAdmin = _apiService.currentUser?.role.name.toLowerCase() == 'admin' || 
                   _apiService.currentUser?.role.name.toLowerCase() == 'administrateur' || 
                   _apiService.currentUser?.role.name.toLowerCase() == 'bibliothécaire';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Bonjour, $userName',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (isAdmin)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 44, 80, 164),
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
        Text(
          'Voici un résumé de votre bibliothèque aujourd\'hui.',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF64748B),
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
                  Icon(Icons.info, color: const Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_apiService.isAuthenticated)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'Connecté • ${_apiService.currentUser?.email ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
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
          Text(
            'Aucune statistique disponible',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les données seront disponibles après les premières activités',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 44, 80, 164),
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
                    Icon(Icons.trending_up, color: const Color.fromARGB(255, 44, 80, 164), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Dernières Activités',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
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
                    Text(
                      'Aucune activité récente',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
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
                    Icon(Icons.arrow_upward, color: const Color.fromARGB(255, 44, 80, 164), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Livres les Plus Empruntés',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
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
                    Text(
                      'Aucun livre emprunté',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
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

  Widget _buildChartSection() {
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
                Text(
                  'Statistiques par Catégorie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  color: const Color(0xFF64748B),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: categoryStats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_graph,
                          size: 48,
                          color: const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune statistique par catégorie',
                          style: TextStyle(fontSize: 14, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: categoryStats.length,
                    itemBuilder: (context, index) {
                      final stat = categoryStats[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                stat.categoryName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              '${stat.totalBooks} livres',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: stat.availableBooks > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${stat.availableBooks} dispo.',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final currentUser = _apiService.currentUser;
    final isAdmin = currentUser?.role.name.toLowerCase() == 'admin' || 
                   currentUser?.role.name.toLowerCase() == 'administrateur' || 
                   currentUser?.role.name.toLowerCase() == 'bibliothécaire';
    
    if (!isAdmin) {
      // Si l'utilisateur n'est pas admin, retourner une barre de navigation vide
      return const SizedBox.shrink();
    }
    
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
        selectedItemColor: const Color.fromARGB(255, 44, 80, 164),
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
        context.go('/admin/settings');
        break;
    }
  }
}