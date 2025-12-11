import 'package:flutter/material.dart';
import 'package:gestion_bibliotheque/widgets/notif.dart';
import 'package:go_router/go_router.dart';

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({Key? key}) : super(key: key);

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Données de réservation simulées
  List<Map<String, dynamic>> _reservations = [
    {
      'id': 1,
      'book': 'L\'Étranger',
      'user': 'Marie Dupont',
      'reserveDate': '2024-01-15',
      'status': 'pending',
    },
    {
      'id': 2,
      'book': 'Le Seigneur des Anneaux',
      'user': 'Jean Martin',
      'reserveDate': '2024-01-14',
      'status': 'ready',
    },
    {
      'id': 3,
      'book': 'Harry Potter',
      'user': 'Sophie Laurent',
      'reserveDate': '2024-01-13',
      'status': 'pending',
    },
    {
      'id': 4,
      'book': '1984',
      'user': 'Pierre Dubois',
      'reserveDate': '2024-01-12',
      'status': 'ready',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredReservations {
    if (_searchQuery.isEmpty) return _reservations;
    
    return _reservations.where((res) {
      final book = res['book'].toString().toLowerCase();
      final user = res['user'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return book.contains(query) || user.contains(query);
    }).toList();
  }

  int get _readyCount {
    return _reservations.where((res) => res['status'] == 'ready').length;
  }

  void _handleValidate(int id, String book) {
    setState(() {
      _reservations = _reservations.map((res) {
        if (res['id'] == id) {
          return {...res, 'status': 'ready'};
        }
        return res;
      }).toList();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Réservation de "$book" prête pour retrait'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleCancel(int id, String book) {
    setState(() {
      _reservations.removeWhere((res) => res['id'] == id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Réservation de "$book" annulée'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec titre et badge
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 500) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gestion des réservations',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_reservations.length} réservation${_reservations.length > 1 ? 's' : ''} active${_reservations.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_readyCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 44, 80, 164),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$_readyCount prête${_readyCount > 1 ? 's' : ''} pour retrait',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        } else {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gestion des réservations',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_reservations.length} réservation${_reservations.length > 1 ? 's' : ''} active${_reservations.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              if (_readyCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 44, 80, 164),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$_readyCount prête${_readyCount > 1 ? 's' : ''} pour retrait',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Carte de recherche et liste
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Barre de recherche
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
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText: 'Rechercher par livre ou utilisateur...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Liste des réservations
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: _filteredReservations.map((reservation) {
                                final isReady = reservation['status'] == 'ready';
                                
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 500) {
                                      // Version mobile
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Titre du livre
                                            Text(
                                              reservation['book'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            // Nom d'utilisateur
                                            Text(
                                              reservation['user'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            // Badge de statut
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isReady
                                                    ? const Color.fromARGB(255, 44, 80, 164)
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isReady ? 'Prête' : 'En attente',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isReady ? Colors.white : const Color(0xFF64748B),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            // Date et boutons
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Réservé le',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF64748B),
                                                      ),
                                                    ),
                                                    Text(
                                                      reservation['reserveDate'],
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    if (!isReady)
                                                      Container(
                                                        constraints: const BoxConstraints(
                                                          minWidth: 80,
                                                        ),
                                                        child: OutlinedButton.icon(
                                                          onPressed: () => _handleValidate(
                                                            reservation['id'],
                                                            reservation['book'],
                                                          ),
                                                          icon: const Icon(
                                                            Icons.check,
                                                            size: 14,
                                                          ),
                                                          label: const Text('Prête'),
                                                          style: OutlinedButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    if (!isReady) const SizedBox(width: 8),
                                                    OutlinedButton(
                                                      onPressed: () => _handleCancel(
                                                        reservation['id'],
                                                        reservation['book'],
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        padding: const EdgeInsets.all(8),
                                                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.close,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      // Version desktop
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Informations du livre et utilisateur
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    reservation['book'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    reservation['user'],
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isReady
                                                          ? const Color.fromARGB(255, 44, 80, 164)
                                                          : const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      isReady ? 'Prête' : 'En attente',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isReady ? Colors.white : const Color(0xFF64748B),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Date et boutons
                                            Row(
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    const Text(
                                                      'Réservé le',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF64748B),
                                                      ),
                                                    ),
                                                    Text(
                                                      reservation['reserveDate'],
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 24),
                                                Row(
                                                  children: [
                                                    if (!isReady)
                                                      OutlinedButton.icon(
                                                        onPressed: () => _handleValidate(
                                                          reservation['id'],
                                                          reservation['book'],
                                                        ),
                                                        icon: const Icon(
                                                          Icons.check,
                                                          size: 14,
                                                        ),
                                                        label: const Text('Prête'),
                                                        style: OutlinedButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                        ),
                                                      ),
                                                    if (!isReady) const SizedBox(width: 8),
                                                    OutlinedButton(
                                                      onPressed: () => _handleCancel(
                                                        reservation['id'],
                                                        reservation['book'],
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 8,
                                                        ),
                                                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.close,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
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
          Text(
            'Dashboard Admin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 44, 80, 164),
            ),
          ),
          const Spacer(),
          NotificationIconWithBadge(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: const Color(0xFF64748B),
            onPressed: () => context.go('/profiladmin'),
          ),
        ],
      ),
    );
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
        currentIndex: 1,
        onTap: (index) => _onItemTapped(index, context),
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
            label: 'Profil',
          ),
        ],
      ),
    );
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