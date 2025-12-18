import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/providers/auth_provider.dart';
import '/services/api_service.dart';
import '/models/user.dart';

class StudentsPage extends ConsumerWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _StudentsPageContent();
  }
}

class _StudentsPageContent extends ConsumerStatefulWidget {
  const _StudentsPageContent();

  @override
  ConsumerState<_StudentsPageContent> createState() => _StudentsPageContentState();
}

class _StudentsPageContentState extends ConsumerState<_StudentsPageContent> {
  final ApiService _apiService = ApiService();
  String searchQuery = '';
  List<User> userList = [];
  bool _isLoading = true;
  String? _error;
  Map<String, int> userEmpruntsCount = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📡 Chargement des utilisateurs...');
      final users = await _apiService.getUsers();
      print('✅ ${users.length} utilisateurs récupérés');
      
      // Compter les emprunts par utilisateur
      for (final user in users) {
        try {
          final emprunts = await _apiService.getUserEmprunts(user.id);
          userEmpruntsCount[user.id] = emprunts.length;
        } catch (e) {
          print('⚠️ Erreur chargement emprunts pour ${user.name}: $e');
          userEmpruntsCount[user.id] = 0;
        }
      }
      
      setState(() {
        userList = users;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement utilisateurs: $e');
      setState(() {
        _error = 'Erreur lors du chargement des utilisateurs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Filtrer les utilisateurs selon la recherche
  List<User> get filteredUsers {
    if (searchQuery.isEmpty) return userList;
    
    return userList.where((user) {
      return user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
             user.email.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer l'état d'authentification
    final isAuthenticated = ref.watch(isLoggedInProvider);
    final completeUserAsync = ref.watch(completeUserProvider);
    
    // Vérifier si l'utilisateur est connecté
    if (!isAuthenticated) {
      // Rediriger vers la page de connexion si non authentifié
      Future.delayed(Duration.zero, () {
        context.go('/login');
      });
      
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
          Future.delayed(Duration.zero, () {
            context.go('/dashboard');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Accès réservé aux administrateurs'),
                backgroundColor: Colors.red,
              ),
            );
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return _buildStudentsContent(context, completeUser);
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
            title: const Text("Gestion des étudiants"),
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

  Widget _buildStudentsContent(BuildContext context, CompleteUser completeUser) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(completeUser),
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _error != null
                      ? _buildErrorWidget()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitleSection(),
                              const SizedBox(height: 16),
                              _buildUsersCard(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _error != null || (!_isLoading && userList.isEmpty)
          ? FloatingActionButton(
              onPressed: _loadUsers,
              backgroundColor: const Color(0xFF2C50A4),
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
            color: Color(0xFF2C50A4),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des utilisateurs...',
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
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUsers,
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
                'Gestion des Étudiants',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C50A4),
                ),
              ),
              Text(
                'Admin: ${completeUser.displayName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildNotificationButton(),
          const SizedBox(width: 8),
          _buildProfileButton(completeUser),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: const Color(0xFF64748B),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications - Fonctionnalité à venir'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileButton(CompleteUser completeUser) {
    return GestureDetector(
      onTap: () => context.go('/profil'),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF2C50A4),
        child: Text(
          _getAvatarInitials(completeUser),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getAvatarInitials(CompleteUser user) {
    final name = user.displayName;
    if (name.isNotEmpty) {
      final nameParts = name.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else if (nameParts[0].isNotEmpty) {
        return nameParts[0][0].toUpperCase();
      }
    }
    return user.email != null && user.email!.isNotEmpty 
        ? user.email![0].toUpperCase()
        : 'A';
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestion des utilisateurs',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${userList.length} utilisateurs inscrits',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUsersCard() {
    if (filteredUsers.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFFE2E8F0).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: const Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun utilisateur trouvé',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (searchQuery.isNotEmpty)
                Text(
                  'Aucun résultat pour "$searchQuery"',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ),
      );
    }

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
              children: [
                const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou email...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => setState(() => searchQuery = ''),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: filteredUsers.map((user) {
                return GestureDetector(
                  onTap: () {
                    context.go('/admin/etudiants/${user.id}');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 640) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildUserInfo(user),
                                  const SizedBox(height: 12),
                                  _buildStatsAndActions(user),
                                ],
                              );
                            } else {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: _buildUserInfo(user)),
                                  _buildStatsAndActions(user),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF2C50A4),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.status == 'active' || user.status == 'actif'
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.status == 'active' || user.status == 'actif' ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: user.status == 'active' || user.status == 'actif'
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C50A4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.role.name,
                style: const TextStyle(
                  color: Color(0xFF2C50A4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsAndActions(User user) {
    final empruntsCount = userEmpruntsCount[user.id] ?? 0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatsSection(empruntsCount),
              _buildActionButtons(user),
            ],
          );
        } else {
          return Row(
            children: [
              _buildStatsSection(empruntsCount),
              const SizedBox(width: 24),
              _buildActionButtons(user),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatsSection(int empruntsCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                '$empruntsCount',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Text(
                'Emprunts',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              const Text(
                '0',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Text(
                'Réservations',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(User user) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _editUser(user),
          icon: const Icon(Icons.edit_outlined),
          color: const Color(0xFF2C50A4),
          tooltip: 'Modifier',
        ),
        IconButton(
          onPressed: () => _viewUserDetails(user),
          icon: const Icon(Icons.visibility_outlined),
          color: const Color(0xFF64748B),
          tooltip: 'Voir détails',
        ),
        IconButton(
          onPressed: () => _toggleUserStatus(user),
          icon: Icon(
            user.status == 'active' || user.status == 'actif' 
                ? Icons.block_outlined 
                : Icons.check_circle_outlined,
          ),
          color: user.status == 'active' || user.status == 'actif' 
              ? const Color(0xFFEF4444) 
              : const Color(0xFF10B981),
          tooltip: user.status == 'active' || user.status == 'actif' 
              ? 'Désactiver' 
              : 'Activer',
        ),
      ],
    );
  }

  void _editUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'utilisateur'),
        content: const Text('Fonctionnalité à venir'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _viewUserDetails(User user) {
    context.go('/admin/etudiants/${user.id}');
  }

  void _toggleUserStatus(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user.status == 'active' || user.status == 'actif' 
              ? 'Désactiver l\'utilisateur' 
              : 'Activer l\'utilisateur'
        ),
        content: Text(
          user.status == 'active' || user.status == 'actif'
              ? 'Êtes-vous sûr de vouloir désactiver ${user.name} ?'
              : 'Êtes-vous sûr de vouloir activer ${user.name} ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    user.status == 'active' || user.status == 'actif'
                        ? 'Utilisateur ${user.name} désactivé (simulation)'
                        : 'Utilisateur ${user.name} activé (simulation)'
                  ),
                  backgroundColor: const Color(0xFF2C50A4),
                ),
              );
            },
            child: Text(
              user.status == 'active' || user.status == 'actif' 
                  ? 'Désactiver' 
                  : 'Activer'
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Livres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Étudiants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Emprunts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
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