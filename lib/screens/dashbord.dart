import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/book.dart';
import '../models/quick_action.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ignore: unused_field
  String _searchQuery = '';

  final List<Book> newBooks = Book.newBooks;
  final List<Book> popularBooks = Book.popularBooks;

  final List<QuickAction> quickActions = [
    QuickAction(
      icon: Icons.menu_book,
      label: 'Catalogue',
      color: Color.fromARGB(255, 44, 80, 164),
      route: '/catalogue',
    ),
    QuickAction(
      icon: Icons.description,
      label: 'Mes emprunts',
      color: Color.fromARGB(221, 248, 190, 45),
      route: '/emprunts',
    ),
    QuickAction(
      icon: Icons.access_time,
      label: 'Réservations',
      color: Color(0xFF10B981),
      route: '/reservations',
    ),
    QuickAction(
      icon: Icons.person,
      label: 'Profil',
      color: Color(0xFFF59E0B),
      route: '/profil',
    ),
  ];

  void _handleBookClick(String id) {
    // Utilisation de GoRouter
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickActionsSection(),
                        const SizedBox(height: 24),
                        _buildNewBooksSection(),
                        const SizedBox(height: 24),
                        _buildPopularBooksSection(),
                        const SizedBox(height: 24),
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
      bottomNavigationBar: _buildBottomNav(),
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
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Rechercher un livre...',
              hintStyle:
                  const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ Section Actions rapides - CORRIGÉE
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
      // CORRECTION: Utilisation de context.go() au lieu de Navigator.pushNamed
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
        _buildSectionHeader('Nouveautés'),
        const SizedBox(height: 16),
        _buildBookCarousel(newBooks),
      ],
    );
  }

  /// 🔥 Section Livres populaires
  Widget _buildPopularBooksSection() {
    return Column(
      children: [
        _buildSectionHeader('Livres populaires'),
        const SizedBox(height: 16),
        _buildBookCarousel(popularBooks),
      ],
    );
  }

  /// 🧩 En-tête de section - CORRIGÉ
  Widget _buildSectionHeader(String title) {
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
          // CORRECTION: Utilisation de context.go()
          onTap: () => context.go('/catalogue'),
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
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) => _buildBookCard(books[index]),
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
            // Image/icone du livre
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
              child: const Center(
                child: Icon(Icons.menu_book,
                    size: 48,
                    color: Color.fromARGB(255, 44, 80, 164)),
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
                          color: Color(0xFF0F172A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              offset: const Offset(0, 4))
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue à la Bibliothèque UFR SAT',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Cherchez un livre, réservez et empruntez facilement depuis votre smartphone.',
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  /// 🧭 Barre de navigation inférieure
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(context),
      onTap: (index) => _onItemTapped(index, context),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color.fromARGB(255, 44, 80, 164),
      unselectedItemColor: const Color(0xFF64748B),
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