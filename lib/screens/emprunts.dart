import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/emprunt.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class EmpruntsPage extends StatefulWidget {
  const EmpruntsPage({super.key});

  @override
  State<EmpruntsPage> createState() => _EmpruntsPageState();
}

class _EmpruntsPageState extends State<EmpruntsPage> {
  final ApiService _apiService = ApiService();
  List<Emprunt> _emprunts = [];
  List<Emprunt> _lateEmprunts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  User? _currentUser;
  int _currentTab = 0; // 0: Emprunts actifs, 1: En retard

  @override
  void initState() {
    super.initState();
    _loadEmprunts();
  }

  Future<void> _loadEmprunts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Vérifier l'authentification d'abord
      if (!_apiService.isAuthenticated) {
        setState(() {
          _errorMessage = 'Veuillez vous connecter';
          _isLoading = false;
        });
        return;
      }

      _currentUser = _apiService.currentUser;
      
      if (_currentUser?.id != null && _currentUser!.id.isNotEmpty) {
        // Charger les emprunts de l'utilisateur
        final userEmprunts = await _apiService.getUserEmprunts(_currentUser!.id);
        
        // Séparer les emprunts actifs et en retard
        final activeEmprunts = userEmprunts.where((e) => !e.isLate).toList();
        final lateEmprunts = userEmprunts.where((e) => e.isLate).toList();
        
        setState(() {
          _emprunts = activeEmprunts;
          _lateEmprunts = lateEmprunts;
          _isLoading = false;
        });
      } else {
        // Si c'est un admin, charger tous les emprunts
        if (_currentUser?.role.name.toLowerCase() == 'admin' || 
            _currentUser?.role.name.toLowerCase() == 'administrateur') {
          await _loadAllEmprunts();
        } else {
          setState(() {
            _errorMessage = 'Informations utilisateur incomplètes';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
        _isLoading = false;
      });
      print('Erreur lors du chargement des emprunts: $e');
    }
  }

  Future<void> _loadAllEmprunts() async {
    try {
      final allEmprunts = await _apiService.getEmprunts();
      
      // Séparer les emprunts actifs et en retard
      final activeEmprunts = allEmprunts.where((e) => !e.isLate).toList();
      final lateEmprunts = allEmprunts.where((e) => e.isLate).toList();
      
      setState(() {
        _emprunts = activeEmprunts;
        _lateEmprunts = lateEmprunts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur chargement tous emprunts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleExtend(Emprunt emprunt) async {
    try {
      // Vérifier si l'utilisateur peut prolonger
      if (emprunt.isLate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de prolonger un emprunt en retard'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      if (emprunt.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID d\'emprunt manquant'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      // TODO: Implémenter l'API de prolongation si elle existe
      // Pour l'instant, montrer un message
      final newReturnDate = emprunt.returnDate != null 
          ? emprunt.returnDate!.add(const Duration(days: 14))
          : DateTime.now().add(const Duration(days: 14));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prolongation demandée jusqu\'au ${_formatDate(newReturnDate)}'),
          backgroundColor: const Color(0xFF10B981),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      
      // Pour l'instant, on rafraîchit juste la liste
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadEmprunts();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handleReturn(Emprunt emprunt) async {
    try {
      if (emprunt.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID d\'emprunt manquant'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      // Demander confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Retourner le livre"),
          content: Text("Voulez-vous marquer '${emprunt.bookTitle}' comme retourné ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C50A4),
              ),
              child: const Text("Confirmer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Appeler l'API pour retourner le livre
      final result = await _apiService.returnBook(emprunt.id);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${emprunt.bookTitle}" marqué comme retourné'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        
        // Recharger les données après l'action
        await _loadEmprunts();
      } else {
        final errorMessage = result['message']?.toString() ?? 'Erreur inconnue';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $errorMessage'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  List<Emprunt> get _currentList {
    return _currentTab == 0 ? _emprunts : _lateEmprunts;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBottomNav(BuildContext context) {
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
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/catalogue');
              break;
            case 2:
              // Déjà sur la page emprunts
              break;
            case 3:
              context.go('/profil');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color.fromARGB(255, 44, 80, 164),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Emprunts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 44, 80, 164),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => GoRouter.of(context).go('/dashboard'),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mes emprunts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            if (_currentUser != null && (_currentUser!.role.name.toLowerCase() == 'admin' || 
                _currentUser!.role.name.toLowerCase() == 'administrateur'))
              const Text(
                'Vue administrateur',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEmprunts,
            tooltip: 'Rafraîchir',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'dashboard') {
                GoRouter.of(context).go('/dashboard');
              } else if (value == 'help') {
                _showHelpDialog();
              } else if (value == 'logout') {
                await _apiService.logout();
                GoRouter.of(context).go('/login');
              } else if (value == 'late_emprunts') {
                final lateEmprunts = await _apiService.getLateEmprunts();
                _showLateEmpruntsDialog(lateEmprunts);
              } else if (value == 'stats') {
                _showStatsDialog();
              }
            },
            itemBuilder: (context) {
              final items = [
                const PopupMenuItem(
                  value: 'dashboard',
                  child: Row(
                    children: [
                      Icon(Icons.home, color: Color(0xFF3B82F6)),
                      SizedBox(width: 10),
                      Text('Dashboard'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'help',
                  child: Row(
                    children: [
                      Icon(Icons.help, color: Color(0xFF6B7280)),
                      SizedBox(width: 10),
                      Text('Aide'),
                    ],
                  ),
                ),
              ];

              // Ajouter les options admin
              if (_currentUser?.role.name.toLowerCase() == 'admin' || 
                  _currentUser?.role.name.toLowerCase() == 'administrateur') {
                items.addAll([
                  const PopupMenuItem(
                    value: 'late_emprunts',
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text('Tous les retards'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'stats',
                    child: Row(
                      children: [
                        Icon(Icons.analytics, color: Color(0xFF10B981)),
                        SizedBox(width: 10),
                        Text('Statistiques'),
                      ],
                    ),
                  ),
                ]);
              }

              items.add(
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Color(0xFFEF4444)),
                      SizedBox(width: 10),
                      Text('Déconnexion'),
                    ],
                  ),
                ),
              );

              return items;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs pour filtrer les emprunts
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentTab = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _currentTab == 0
                                ? const Color.fromARGB(255, 44, 80, 164)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _currentUser?.role.name.toLowerCase() == 'admin' ? 
                                'Tous' : 'En cours',
                            style: TextStyle(
                              fontWeight: _currentTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _currentTab == 0
                                  ? const Color.fromARGB(255, 44, 80, 164)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_emprunts.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _currentTab == 0
                                  ? const Color.fromARGB(255, 44, 80, 164)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentTab = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _currentTab == 1
                                ? const Color(0xFFEF4444)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'En retard',
                            style: TextStyle(
                              fontWeight: _currentTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _currentTab == 1
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_lateEmprunts.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _currentTab == 1
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _errorMessage.isNotEmpty && _currentList.isEmpty
                    ? _buildErrorWidget()
                    : _currentList.isNotEmpty
                        ? _buildEmpruntsList()
                        : _buildEmptyState(isLate: _currentTab == 1),
          ),
        ],
      ),
      floatingActionButton: _errorMessage.isNotEmpty && _currentList.isEmpty
          ? FloatingActionButton(
              onPressed: _loadEmprunts,
              backgroundColor: const Color.fromARGB(255, 44, 80, 164),
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildEmpruntsList() {
    return RefreshIndicator(
      onRefresh: _loadEmprunts,
      color: const Color.fromARGB(255, 44, 80, 164),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _currentList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final emprunt = _currentList[index];
          final isLate = emprunt.isLate;
          final daysRemaining = emprunt.daysRemaining;
          final daysLate = emprunt.daysLate;
          final isAdmin = _currentUser?.role.name.toLowerCase() == 'admin' || 
                         _currentUser?.role.name.toLowerCase() == 'administrateur';
          
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.book,
                            size: 30,
                            color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emprunt.bookTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              emprunt.book?.author ?? 'Auteur inconnu',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                            if (isAdmin && emprunt.userName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Emprunté par: ${emprunt.userName!}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isLate
                                    ? const Color(0xFFEF4444).withOpacity(0.1)
                                    : const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isLate
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isLate 
                                    ? 'EN RETARD (${daysLate > 0 ? '$daysLate jour${daysLate > 1 ? 's' : ''}' : 'Retard'})'
                                    : 'EN COURS (${daysRemaining > 0 ? '$daysRemaining jour${daysRemaining > 1 ? 's' : ''}' : 'Dernier jour'})',
                                style: TextStyle(
                                  color: isLate
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        "Emprunté le: ${emprunt.formattedBorrowDate ?? 'Non spécifiée'}",
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isLate
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Retour prévu le: ${emprunt.formattedReturnDate ?? 'Non spécifiée'}",
                        style: TextStyle(
                          color: isLate
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: isLate
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!isAdmin || !isLate) // Les admin ne peuvent pas prolonger les retards
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLate ? null : () => _handleExtend(emprunt),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isLate
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF2C50A4),
                              side: BorderSide(
                                color: isLate
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF2C50A4),
                              ),
                            ),
                            child: const Text("Prolonger"),
                          ),
                        ),
                      if (!isAdmin || !isLate) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleReturn(emprunt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C50A4),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Retourner"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
            'Chargement de vos emprunts...',
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
              onPressed: _loadEmprunts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => GoRouter.of(context).go('/dashboard'),
              child: const Text('Retour au dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isLate = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLate ? Icons.check_circle : Icons.book,
              size: 64,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              isLate
                  ? _currentUser?.role.name.toLowerCase() == 'admin' 
                      ? 'Aucun emprunt en retard' 
                      : 'Aucun emprunt en retard'
                  : _currentUser?.role.name.toLowerCase() == 'admin'
                      ? 'Aucun emprunt en cours'
                      : 'Aucun emprunt en cours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLate
                  ? 'Tous les emprunts sont à jour !'
                  : _currentUser?.role.name.toLowerCase() == 'admin'
                      ? 'Aucun emprunt actif dans le système'
                      : 'Vous n\'avez actuellement aucun livre emprunté.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            if (!isLate)
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go('/catalogue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 8),
                    Text('Explorer le catalogue'),
                  ],
                ),
              ),
            if (isLate && _currentUser?.roleName.toLowerCase() == 'admin')
              const Text(
                'Excellent, tous les emprunts sont dans les temps !',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Color(0xFF2C50A4)),
            SizedBox(width: 10),
            Text("Aide Emprunts"),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Instructions pour la gestion des emprunts :",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text("• **Prolonger** : Ajoute 14 jours supplémentaires"),
              Text("• **Retourner** : Marque le livre comme retourné"),
              Text("• **Emprunts en retard** : Affichés en rouge"),
              SizedBox(height: 10),
              Text(
                "Pour toute question, contactez le service de la bibliothèque.",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  void _showLateEmpruntsDialog(List<Emprunt> lateEmprunts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text("Tous les emprunts en retard"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: lateEmprunts.isEmpty
              ? const Text("Aucun emprunt en retard dans le système.")
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total: ${lateEmprunts.length} emprunt(s) en retard"),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: lateEmprunts.length,
                        itemBuilder: (context, index) {
                          final emprunt = lateEmprunts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emprunt.bookTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Emprunté par: ${emprunt.userName ?? 'Inconnu'}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    "Retour prévu: ${emprunt.formattedReturnDate ?? 'Inconnue'}",
                                    style: const TextStyle(fontSize: 12, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() async {
    try {
      final stats = await _apiService.getDashboardStats();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF2C50A4)),
              SizedBox(width: 10),
              Text("Statistiques des emprunts"),
            ],
          ),
          content: stats.isNotEmpty
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem("Emprunts actifs", stats['active_borrowings']?.toString() ?? '0'),
                      _buildStatItem("Emprunts en retard", stats['late_borrowings']?.toString() ?? '0'),
                      _buildStatItem("Retours ce mois", stats['returns_this_month']?.toString() ?? '0'),
                      _buildStatItem("Total des emprunts", stats['total_borrowings']?.toString() ?? '0'),
                    ],
                  ),
                )
              : const Text("Aucune statistique disponible."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement statistiques: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2C50A4),
            ),
          ),
        ],
      ),
    );
  }
}