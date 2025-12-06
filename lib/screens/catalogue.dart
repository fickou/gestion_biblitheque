import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/book.dart';
import '../components/book_card.dart';
import '../services/api_service.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  final ApiService _apiService = ApiService();
  String _searchQuery = '';
  List<Book> _filteredBooks = [];
  List<Book> _allBooks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final books = await _apiService.getBooks();
      setState(() {
        _allBooks = books;
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des livres: $e';
        _isLoading = false;
      });
      print('Erreur lors du chargement des livres: $e');
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredBooks = _allBooks;
      } else {
        _filteredBooks = _allBooks.where((book) {
          return book.title.toLowerCase().contains(query.toLowerCase()) ||
                 book.author.toLowerCase().contains(query.toLowerCase()) ||
                 (book.category != null && 
                  book.category!.name.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  Future<void> _handleSearchApi(String query) async {
    if (query.trim().isEmpty) {
      _loadBooks();
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final books = await _apiService.searchBooks(query);
      setState(() {
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la recherche: $e';
        _isLoading = false;
      });
      print('Erreur lors de la recherche: $e');
    }
  }

  void _handleBookClick(String bookId) {
    context.go('/livre/$bookId');
  }

  void _showFilters() {
    final categories = _allBooks
        .map((book) => book.category)
        .whereType<String>()
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filtres',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            
            // Filtre par disponibilité
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF64748B)),
              title: const Text('Disponibilité'),
              subtitle: const Text('Afficher seulement les livres disponibles'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  // TODO: Implémenter le filtre de disponibilité
                },
              ),
            ),
            
            // Filtre par catégorie
            ExpansionTile(
              leading: const Icon(Icons.category_outlined, color: Color(0xFF64748B)),
              title: const Text('Catégories'),
              children: categories.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Aucune catégorie disponible'),
                      )
                    ]
                  : categories.map((category) {
                      return CheckboxListTile(
                        value: false,
                        onChanged: (value) {
                          // TODO: Implémenter le filtre par catégorie
                        },
                        title: Text(category),
                      );
                    }).toList(),
            ),
            
            // Filtre par auteur
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
              title: const Text('Auteurs'),
              subtitle: const Text('Filtrer par auteur'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Implémenter le filtre par auteur
              },
            ),
            
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Appliquer les filtres
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
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
            // Header avec recherche
            _buildAppHeader(),
            
            // Contenu principal
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _errorMessage.isNotEmpty && _filteredBooks.isEmpty
                      ? _buildErrorWidget()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: Column(
                              children: [
                                // En-tête avec compteur et bouton filtre
                                _buildHeaderSection(),
                                const SizedBox(height: 16),
                                
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
      floatingActionButton: _errorMessage.isNotEmpty && _filteredBooks.isEmpty
          ? FloatingActionButton(
              onPressed: _loadBooks,
              backgroundColor: const Color.fromARGB(255, 44, 80, 164),
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
      // Barre de navigation inférieure
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
            'Chargement des livres...',
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
              onPressed: _loadBooks,
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

  /// Header de l'application avec barre de recherche
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
              Text(
                'Catalogue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 44, 80, 164),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                color: const Color(0xFF64748B),
                onPressed: _loadBooks,
                tooltip: 'Rafraîchir',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de recherche
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: _handleSearch,
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
                      _filteredBooks = _allBooks;
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
            color: const Color(0xFF0F172A),
          ),
        ),
        if (_errorMessage.isNotEmpty && _filteredBooks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  'Données partielles',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          )
        else
          OutlinedButton(
            onPressed: _showFilters,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  'Filtres',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
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
          padding: const EdgeInsets.only(bottom: 12),
          child: BookCard(
            book: book,
            onTap: () => _handleBookClick(book.id ?? ''),
          ),
        );
      }).toList(),
    );
  }

  /// État vide quand aucun livre n'est trouvé
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.menu_book_outlined,
            size: 64,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Aucun livre ne correspond à votre recherche.'
                : 'Aucun livre disponible.',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez avec d\'autres termes de recherche.'
                : 'Les livres seront bientôt ajoutés au catalogue.',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _filteredBooks = _allBooks;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Afficher tous les livres'),
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
            offset: const Offset(0, -2),
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
}