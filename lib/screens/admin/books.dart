import 'package:flutter/material.dart';
import 'package:gestion_bibliotheque/models/category.dart';
import '/models/book.dart';
import '/widgets/notif.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import 'dart:convert' show jsonEncode;

class BooksAdminPage extends StatefulWidget {
  const BooksAdminPage({super.key});

  @override
  State<BooksAdminPage> createState() => _BooksAdminPageState();
}

class _BooksAdminPageState extends State<BooksAdminPage> {
  final ApiService _apiService = ApiService();
  String searchQuery = '';
  List<Book> displayedBooks = [];
  List<Book> allBooks = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final books = await _apiService.getBooks();
      setState(() {
        allBooks = books;
        displayedBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement des livres: $e';
        _isLoading = false;
      });
      print('Erreur lors du chargement des livres: $e');
    }
  }

  Future<void> _searchBooks(String query) async {
    setState(() {
      searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        displayedBooks = allBooks;
        _isSearching = false;
      });
      return;
    }

    try {
      final results = await _apiService.searchBooks(query);
      setState(() {
        displayedBooks = results;
      });
    } catch (e) {
      // Si la recherche API échoue, filtrer localement
      setState(() {
        displayedBooks = allBooks.where((book) =>
          book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.author.toLowerCase().contains(query.toLowerCase())
        ).toList();
      });
      print('Recherche API échouée, fallback local: $e');
    }
  }

  Future<void> _deleteBook(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le livre "$title" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _apiService.deleteBook(id);
      
      if (result['success'] == true) {
        // Mettre à jour les listes localement
        setState(() {
          allBooks.removeWhere((book) => book.id == id);
          displayedBooks.removeWhere((book) => book.id == id);
        });
        
        _showSuccessSnackbar('"$title" supprimé avec succès');
      } else {
        _showErrorSnackbar(result['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _refreshBooks() {
    _loadBooks();
    setState(() {
      searchQuery = '';
    });
  }

  void _showAddBookDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: AddEditBookForm(
          onSuccess: () {
            // Recharger la liste des livres après l'ajout
            _loadBooks();
          },
        ),
      ),
    );
  }

  void _showEditBookDialog(Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: AddEditBookForm(
          book: book,
          onSuccess: () {
            // Recharger la liste des livres après la modification
            _loadBooks();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshBooks,
        backgroundColor: const Color.fromARGB(255, 44, 80, 164),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _isSearching ? 'Recherche en cours...' : 'Chargement des livres...',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBooks,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre et compteur
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestion des livres',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${allBooks.length} livres au total • ${displayedBooks.length} affichés',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _showAddBookDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text('Ajouter un livre'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Barre de recherche
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color(0xFFE2E8F0).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: const Color(0xFF64748B),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(text: searchQuery),
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher par titre ou auteur...',
                                    border: InputBorder.none,
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                    suffixIcon: searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                searchQuery = '';
                                              });
                                              _searchBooks('');
                                            },
                                          )
                                        : null,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                  onChanged: (value) {
                                    // Debounce pour éviter trop de requêtes
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      if (mounted) {
                                        _searchBooks(value);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Liste des livres
                      _buildBooksList(),
                      
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBooksList() {
    if (displayedBooks.isEmpty) {
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
          padding: const EdgeInsets.all(40.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isEmpty
                      ? 'Aucun livre dans la bibliothèque'
                      : 'Aucun livre trouvé pour "$searchQuery"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        searchQuery = '';
                      });
                      _searchBooks('');
                    },
                    child: const Text('Voir tous les livres'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: displayedBooks.map((book) {
        final totalCopies = book.copies;
        final availableCopies = book.available ? totalCopies : 0;
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFFE2E8F0).withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/admin/booksdetails/${book.id}'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 768;
                    
                    if (isDesktop) {
                      return _buildDesktopBookItem(book, availableCopies, totalCopies);
                    } else {
                      return _buildMobileBookItem(book, availableCopies, totalCopies);
                    }
                  },
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopBookItem(Book book, int availableCopies, int totalCopies) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                book.author,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      book.categoryName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Année: ${book.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ISBN: ${book.isbn ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        Row(
          children: [
            Column(
              children: [
                Text(
                  '$availableCopies/$totalCopies',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Text(
                  'Disponibles/Total',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              children: _buildActionButtons(book),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileBookItem(Book book, int availableCopies, int totalCopies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
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
          book.author,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                book.categoryName,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Année: ${book.year}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  '$availableCopies/$totalCopies',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Text(
                  'Disponibles/Total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Row(
              children: _buildActionButtons(book),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(Book book) {
    return [
      IconButton(
        icon: const Icon(Icons.visibility, size: 18, color: Color(0xFF64748B)),
        onPressed: () => context.go('/admin/booksdetails/${book.id}'),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          backgroundColor: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.8)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF64748B)),
        onPressed: () => _showEditBookDialog(book),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          backgroundColor: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.8)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
        onPressed: () => _deleteBook(book.id, book.title),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          backgroundColor: const Color(0xFFFEF2F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Color(0xFFFECACA)),
          ),
        ),
      ),
    ];
  }

  // Header identique au dashboard
  Widget _buildHeader() {
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
  
  // Bottom Navigation
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
  
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/admin/dashboard') return 0;
    if (location == '/admin/books') return 1;
    if (location == '/admin/etudiants') return 2;
    if (location == '/admin/emprunts') return 3;
    if (location == '/profiladmin') return 4;
    return 1;
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

class AddEditBookForm extends StatefulWidget {
  final Book? book; // null pour ajout, non-null pour modification
  final Function()? onSuccess;

  const AddEditBookForm({
    super.key,
    this.book,
    this.onSuccess,
  });

  @override
  State<AddEditBookForm> createState() => _AddEditBookFormState();
}

class _AddEditBookFormState extends State<AddEditBookForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;

  // Contrôleurs pour les champs du formulaire
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _copiesController = TextEditingController();
  bool _available = true;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Si on est en mode édition, pré-remplir les champs
    if (widget.book != null) {
      final book = widget.book!;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _isbnController.text = book.isbn ?? '';
      _yearController.text = book.year;
      _categoryNameController.text = book.category?.name ?? '';
      _copiesController.text = book.copies.toString();
      _available = book.available;
      _descriptionController.text = book.description ?? '';
    } else {
      // Valeurs par défaut pour l'ajout
      _copiesController.text = '1';
      _yearController.text = DateTime.now().year.toString();
      _available = true; // FORCER à true pour les nouveaux livres
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _categoryNameController.dispose();
    _copiesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fonction pour générer un ID de catégorie à partir du nom
  String _generateCategoryId(String categoryName) {
    if (categoryName.trim().isEmpty) return '';
    
    // Convertir en minuscules
    String id = categoryName.trim().toLowerCase();
    
    // Supprimer les accents
    id = id
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[ñ]'), 'n');
    
    // Remplacer les espaces et caractères spéciaux par des tirets
    id = id.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    
    // Supprimer les tirets en début et fin
    id = id.replaceAll(RegExp(r'^-+|-+$'), '');
    
    return id;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. GÉNÉRER L'ID DE CATÉGORIE
      final categoryName = _categoryNameController.text.trim();
      final categoryId = _generateCategoryId(categoryName);
      
      if (categoryId.isEmpty) {
        throw Exception('Le nom de la catégorie est invalide');
      }

      // 2. RÉCUPÉRER LE NOMBRE D'EXEMPLAIRES
      final totalCopies = int.parse(_copiesController.text);
      
      // 3. LOGIQUE DE DISPONIBILITÉ
      // - Pour l'AJOUT: toujours disponible et toutes les copies sont disponibles
      // - Pour l'ÉDITION: garder la logique existante
      final bool isNewBook = widget.book == null;
      final bool bookAvailable = isNewBook ? true : _available;
      
      // 4. CRÉER L'OBJET BOOK
      final book = Book(
        id: widget.book?.id ?? '',
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        // IMPORTANT: Logique différente selon ajout/édition
        available: bookAvailable,
        category: Category(
          id: categoryId,
          name: categoryName,
          description: 'Catégorie auto-générée: $categoryName',
        ),
        year: _yearController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        copies: totalCopies, // Nombre total d'exemplaires
        isbn: _isbnController.text.trim().isNotEmpty 
            ? _isbnController.text.trim() 
            : null,
        createdAt: widget.book?.createdAt,
        updatedAt: DateTime.now(),
      );

      Map<String, dynamic> result;
      
      if (widget.book != null) {
        // ÉDITION: Utiliser updateBook
        result = await _apiService.updateBook(book);
      } else {
        // AJOUT: Utiliser createBook
        result = await _apiService.createBook(book);
      }

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: widget.book != null
                  ? Text('📚 Livre modifié - ${book.copies}/${book.copies} exemplaires')
                  : Text('✅ Livre ajouté - ${book.copies}/${book.copies} exemplaires disponibles'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          widget.onSuccess?.call();
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _error = result['message'] ?? 'Une erreur est survenue';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.book != null;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditMode ? 'Modifier le livre' : 'Ajouter un livre',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_error != null) const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Titre
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre *',
                        border: OutlineInputBorder(),
                        hintText: 'Le petit prince',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer un titre';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Auteur
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Auteur *',
                        border: OutlineInputBorder(),
                        hintText: 'Antoine de Saint-Exupéry',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer un auteur';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // ISBN
                    TextFormField(
                      controller: _isbnController,
                      decoration: const InputDecoration(
                        labelText: 'ISBN',
                        border: OutlineInputBorder(),
                        hintText: '9782070612758',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        // Année
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            decoration: const InputDecoration(
                              labelText: 'Année *',
                              border: OutlineInputBorder(),
                              hintText: '1943',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez entrer une année';
                              }
                              final year = int.tryParse(value);
                              if (year == null || year < 1000 || year > DateTime.now().year + 1) {
                                return 'Année invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Nombre d'exemplaires
                        Expanded(
                          child: TextFormField(
                            controller: _copiesController,
                            decoration: InputDecoration(
                              labelText: 'Exemplaires *',
                              border: const OutlineInputBorder(),
                              hintText: '1',
                              helperText: isEditMode 
                                  ? 'Nombre total d\'exemplaires'
                                  : 'Tous les exemplaires seront disponibles',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez entrer un nombre';
                              }
                              final copies = int.tryParse(value);
                              if (copies == null || copies < 1) {
                                return 'Nombre invalide (minimum 1)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Nom Catégorie seulement
                    TextFormField(
                      controller: _categoryNameController,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie *',
                        border: OutlineInputBorder(),
                        hintText: 'Roman, Science-Fiction, Informatique, etc.',
                        helperText: "L'ID sera automatiquement généré à partir du nom",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer une catégorie';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Disponibilité (uniquement pour l'édition)
                    if (isEditMode)
                      Row(
                        children: [
                          Switch(
                            value: _available,
                            onChanged: (value) {
                              setState(() {
                                _available = value;
                              });
                            },
                            activeColor: const Color.fromARGB(255, 44, 80, 164),
                          ),
                          const SizedBox(width: 8),
                          const Text('Disponible'),
                          const SizedBox(width: 16),
                          Icon(
                            _available ? Icons.check_circle : Icons.cancel,
                            color: _available ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pour un nouvel ajout, tous les exemplaires sont automatiquement disponibles.',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        hintText: 'Description du livre...',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditMode ? 'Modifier' : 'Ajouter',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}