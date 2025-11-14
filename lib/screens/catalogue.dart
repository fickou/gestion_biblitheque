import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/book.dart';
import '../components/book_card.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({Key? key}) : super(key: key);

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  String _searchQuery = '';
  List<Book> _filteredBooks = Book.catalogueBooks;

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredBooks = Book.catalogueBooks;
      } else {
        _filteredBooks = Book.catalogueBooks.where((book) {
          return book.title.toLowerCase().contains(query.toLowerCase()) ||
                 book.author.toLowerCase().contains(query.toLowerCase()) ||
                 book.category.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _handleBookClick(String bookId) {
    context.go('/livre/$bookId');
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filtres',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 16),
            // TODO: Implémenter les filtres
            Text(
              'Fonctionnalité de filtres à implémenter',
              style: TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 44, 80, 164),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec recherche
            _buildAppHeader(),
            
            // Contenu principal
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 448),
                  child: Column(
                    children: [
                      // En-tête avec compteur et bouton filtre
                      _buildHeaderSection(),
                      SizedBox(height: 16),
                      
                      // Liste des livres
                      _buildBooksList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Barre de navigation inférieure
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// Header de l'application avec barre de recherche
  Widget _buildAppHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Catalogue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 44, 80, 164),
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                color: Color(0xFF64748B),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 12),
          // Barre de recherche
          TextField(
            onChanged: _handleSearch,
            decoration: InputDecoration(
              hintText: 'Rechercher un livre...',
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
              filled: true,
              fillColor: Color(0xFFF1F5F9),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  /// Section en-tête avec compteur et bouton filtre
  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_filteredBooks.length} livre(s) trouvé(s)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        OutlinedButton(
          onPressed: _showFilters,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Liste des livres
  Widget _buildBooksList() {
    if (_filteredBooks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _filteredBooks.map((book) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: BookCard(
            book: book,
            onTap: () => _handleBookClick(book.id),
          ),
        );
      }).toList(),
    );
  }

  /// État vide quand aucun livre n'est trouvé
  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 16),
          Text(
            'Aucun livre trouvé.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres termes de recherche.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  /// Barre de navigation inférieure
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 1, // Catalogue actif
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              // Déjà sur le catalogue
              break;
            case 2:
              context.go('/emprunts');
              break;
            case 3:
              context.go('/profil');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color.fromARGB(255, 44, 80, 164),
        unselectedItemColor: Color(0xFF64748B),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: [
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
}