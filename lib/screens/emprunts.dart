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
      _currentUser = _apiService.currentUser;
      
      // ignore: unnecessary_null_comparison
      if (_currentUser != null && _currentUser!.id != null) {
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
        setState(() {
          _errorMessage = 'Utilisateur non connecté';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des emprunts: $e';
        _isLoading = false;
      });
      print('Erreur lors du chargement des emprunts: $e');
    }
  }

  Future<void> _handleExtend(Emprunt emprunt) async {
    try {
      // TODO: Implémenter la logique de prolongation d'emprunt
      // Cette méthode devrait appeler l'API pour prolonger l'emprunt
      
      // Exemple : calculer une nouvelle date de retour (14 jours supplémentaires)
      final newReturnDate = emprunt.returnDate != null 
          ? emprunt.returnDate!.add(const Duration(days: 14))
          : DateTime.now().add(const Duration(days: 14));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prolongation demandée jusqu\'au ${newReturnDate.day}/${newReturnDate.month}/${newReturnDate.year}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      
      // Recharger les données après l'action
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadEmprunts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la prolongation: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handleReturn(Emprunt emprunt) async {
    try {
      if (emprunt.id.isNotEmpty) {
        final result = await _apiService.returnBook(emprunt.id);
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${emprunt.bookTitle}" marqué comme retourné'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          
          // Recharger les données après l'action
          await Future.delayed(const Duration(milliseconds: 500));
          await _loadEmprunts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ?? 'Erreur lors du retour'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: ID d\'emprunt manquant'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du retour: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  List<Emprunt> get _currentList {
    return _currentTab == 0 ? _emprunts : _lateEmprunts;
  }

  // Fonction pour formater la date de manière lisible
  // ignore: unused_element
  String _formatDate(DateTime? date) {
    if (date == null) return 'Non spécifiée';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Fonction pour calculer les jours restants
  // ignore: unused_element
  String _getRemainingDays(DateTime? returnDate) {
    if (returnDate == null) return '';
    
    final now = DateTime.now();
    final difference = returnDate.difference(now);
    
    if (difference.isNegative) {
      final daysLate = difference.inDays.abs();
      return 'En retard de $daysLate jour${daysLate > 1 ? 's' : ''}';
    } else {
      final daysRemaining = difference.inDays;
      return '$daysRemaining jour${daysRemaining > 1 ? 's' : ''} restant${daysRemaining > 1 ? 's' : ''}';
    }
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
        title: const Text(
          'Mes emprunts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEmprunts,
            tooltip: 'Rafraîchir',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'dashboard') {
                GoRouter.of(context).go('/dashboard');
              } else if (value == 'help') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Aide"),
                    content: const Text("Pour toute question concernant vos emprunts, contactez le service de la bibliothèque."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              } else if (value == 'logout') {
                _apiService.logout();
                GoRouter.of(context).go('/login');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'dashboard',
                child: Row(
                  children: [
                    Icon(Icons.home, color: Color(0xFF3B82F6)),
                    SizedBox(width: 10),
                    Text('Dashboard'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help, color: Color(0xFF6B7280)),
                    SizedBox(width: 10),
                    Text('Aide'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
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
                            'En cours',
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
                        ? ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _currentList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final emprunt = _currentList[index];
                              final isLate = emprunt.isLate;
                              final daysRemaining = emprunt.daysRemaining;
                              final daysLate = emprunt.daysLate;
                              
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.book,
                                                size: 30,
                                                color: Color(0xFF64748B)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  emprunt.bookTitle,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  emprunt.book?.author ?? 'Auteur inconnu',
                                                  style: const TextStyle(
                                                    color: Color(0xFF64748B),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isLate
                                                        ? const Color(0xFFEF4444).withOpacity(0.1)
                                                        : const Color(0xFF10B981).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: isLate
                                                          ? const Color(0xFFEF4444)
                                                          : const Color(0xFF10B981),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    isLate 
                                                        ? 'EN RETARD ($daysLate jour${daysLate > 1 ? 's' : ''})'
                                                        : 'EN COURS ($daysRemaining jour${daysRemaining > 1 ? 's' : ''} restant${daysRemaining > 1 ? 's' : ''})',
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
                                          const SizedBox(width: 12),
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
                          )
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
                  ? 'Aucun emprunt en retard'
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
                  ? 'Tous vos emprunts sont à jour !'
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
            if (isLate)
              Text(
                'Continuez à respecter les dates de retour !',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}