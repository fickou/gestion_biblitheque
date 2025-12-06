import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/book.dart';
import '../models/quick_action.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  String _searchQuery = '';
  List<Book> _newBooks = [];
  List<Book> _popularBooks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  User? _currentUser;

  final List<QuickAction> quickActions = [
    QuickAction(
      icon: Icons.menu_book,
      label: 'Catalogue',
      color: const Color.fromARGB(255, 44, 80, 164),
      route: '/catalogue',
    ),
    QuickAction(
      icon: Icons.description,
      label: 'Mes emprunts',
      color: const Color.fromARGB(221, 248, 190, 45),
      route: '/emprunts',
    ),
    QuickAction(
      icon: Icons.access_time,
      label: 'Réservations',
      color: const Color(0xFF10B981),
      route: '/reservations',
    ),
    QuickAction(
      icon: Icons.person,
      label: 'Profil',
      color: const Color(0xFFF59E0B),
      route: '/profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Charger les informations de l'utilisateur
      _currentUser = _apiService.currentUser;

      // Charger les livres depuis l'API
      final books = await _apiService.getBooks();
      
      if (books.isNotEmpty) {
        // Filtrer les livres valides
        final validBooks = books.where((book) => book.isValid).toList();
        
        // Trier par date de création (plus récents en premier)
        validBooks.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(2000);
          final bDate = b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        
        // Prendre les 4 plus récents comme "nouveautés"
        final newBooksCount = validBooks.length >= 4 ? 4 : validBooks.length;
        final List<Book> newBooks = validBooks.sublist(0, newBooksCount);
        
        // Pour les "populaires", prendre les suivants ou les disponibles
        final List<Book> popularBooks = validBooks.length > newBooksCount
            ? validBooks.sublist(
                newBooksCount,
                newBooksCount + (validBooks.length - newBooksCount > 4 ? 4 : validBooks.length - newBooksCount)
              )
            : [];
        
        setState(() {
          _newBooks = newBooks;
          _popularBooks = popularBooks;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: $e';
        _isLoading = false;
      });
      print('Erreur lors du chargement du dashboard: $e');
    }
  }

  Future<void> _handleSearch(String query) async {
    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isNotEmpty) {
      // Naviguer vers le catalogue avec la recherche
      context.go('/catalogue?search=$query');
    }
  }

  void _handleBookClick(String id) {
    context.go('/livre/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _errorMessage.isNotEmpty && _newBooks.isEmpty && _popularBooks.isEmpty
                      ? _buildErrorWidget()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 448),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_errorMessage.isNotEmpty && (_newBooks.isNotEmpty || _popularBooks.isNotEmpty))
                                    _buildWarningBanner(),
                                  
                                  _buildQuickActionsSection(),
                                  const SizedBox(height: 24),
                                  
                                  if (_newBooks.isNotEmpty) ...[
                                    _buildNewBooksSection(),
                                    const SizedBox(height: 24),
                                  ],
                                  
                                  if (_popularBooks.isNotEmpty) ...[
                                    _buildPopularBooksSection(),
                                    const SizedBox(height: 24),
                                  ],
                                  
                                  _buildWelcomeCard(),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _errorMessage.isNotEmpty && _newBooks.isEmpty && _popularBooks.isEmpty
          ? FloatingActionButton(
              onPressed: _loadDashboardData,
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
            'Chargement du dashboard...',
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
              onPressed: _loadDashboardData,
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

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, size: 20, color: Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: const Color(0xFF92400E),
            onPressed: () {
              setState(() {
                _errorMessage = '';
              });
            },
          ),
        ],
      ),
    );
  }

  /// 🧭 Header avec barre de recherche
  Widget _buildAppHeader() {
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
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Bibliothèque',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 44, 80, 164),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: const Color(0xFF64748B),
                onPressed: () {
                  // TODO: Implémenter les notifications
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                color: const Color(0xFF64748B),
                onPressed: _loadDashboardData,
                tooltip: 'Rafraîchir',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: _handleSearch,
                  controller: TextEditingController(text: _searchQuery),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un livre...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  color: const Color(0xFF64748B),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  tooltip: 'Effacer la recherche',
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// ⚡ Section Actions rapides
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: quickActions.length,
          itemBuilder: (context, index) {
            final action = quickActions[index];
            return _buildQuickActionCard(action);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    return InkWell(
      onTap: () => context.go(action.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: action.color,
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 🆕 Section Nouveautés
  Widget _buildNewBooksSection() {
    return Column(
      children: [
        _buildSectionHeader('Nouveautés', '/catalogue?filter=new'),
        const SizedBox(height: 16),
        _buildBookCarousel(_newBooks),
      ],
    );
  }

  /// 🔥 Section Livres populaires
  Widget _buildPopularBooksSection() {
    return Column(
      children: [
        _buildSectionHeader('Livres populaires', '/catalogue?filter=popular'),
        const SizedBox(height: 16),
        _buildBookCarousel(_popularBooks),
      ],
    );
  }

  /// 🧩 En-tête de section
  Widget _buildSectionHeader(String title, String route) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        InkWell(
          onTap: () => context.go(route),
          child: const Text(
            'Voir tout',
            style: TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 44, 80, 164),
            ),
          ),
        ),
      ],
    );
  }

  /// 🎠 Carrousel de livres
  Widget _buildBookCarousel(List<Book> books) {
    if (books.isEmpty) {
      return _buildEmptyBookSection();
    }

    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) => _buildBookCard(books[index]),
      ),
    );
  }

  Widget _buildEmptyBookSection() {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun livre disponible',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les livres seront bientôt ajoutés',
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

  /// 📚 Carte de livre
  Widget _buildBookCard(Book book) {
    return InkWell(
      onTap: () => _handleBookClick(book.id),
      child: Container(
        width: 140,
        height: 230,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Section image/icône
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 44, 80, 164).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.categoryIcon,
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.categoryName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color.fromARGB(255, 44, 80, 164),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Contenu texte
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: book.available
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        book.available ? 'Disponible' : 'Indisponible',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: book.available
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎉 Carte de bienvenue
  Widget _buildWelcomeCard() {
    final userName = _currentUser?.name ?? 'Étudiant';
    final userEmail = _currentUser?.email ?? '';
    final userRole = _currentUser?.role;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 44, 80, 164),
            const Color.fromARGB(255, 44, 80, 164).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue, $userName!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (userEmail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Cherchez un livre, réservez et empruntez facilement depuis votre smartphone.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (userRole != null && userRole.name.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userRole.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (_apiService.isAuthenticated) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Connecté',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 🧭 Barre de navigation inférieure
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

  // Méthode pour déterminer l'index actuel
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/dashboard') return 0;
    if (location == '/catalogue') return 1;
    if (location == '/emprunts') return 2;
    if (location == '/profil') return 3;
    return 0;
  }

  // Navigation pour la bottom bar
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/catalogue');
        break;
      case 2:
        context.go('/emprunts');
        break;
      case 3:
        context.go('/profil');
        break;
    }
  }
}