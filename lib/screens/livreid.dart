import 'package:flutter/material.dart';
import '/models/user.dart';
import '../models/book.dart';
import 'package:go_router/go_router.dart';
import '/services/api_service.dart';

class LivreDetailPage extends StatefulWidget {
  final String id;
  const LivreDetailPage({super.key, required this.id});

  @override
  State<LivreDetailPage> createState() => _LivreDetailPageState();
}

class _LivreDetailPageState extends State<LivreDetailPage> {
  final ApiService _apiService = ApiService();
  Book? _book;
  List<Book> _similarBooks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  Future<void> _loadBookData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Charger les informations du livre
      final book = await _apiService.getBookById(widget.id);
      
      if (book != null && book.isValid) {
        setState(() {
          _book = book;
          _isLoading = false;
        });
        
        // Charger des livres similaires (par catégorie)
        _loadSimilarBooks(book);
      } else {
        setState(() {
          _errorMessage = 'Livre introuvable';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du livre: $e';
        _isLoading = false;
      });
      print('Erreur lors du chargement du livre: $e');
    }
  }

  Future<void> _loadSimilarBooks(Book currentBook) async {
    try {
      final allBooks = await _apiService.getBooks();
      
      // Filtrer les livres par catégorie similaire (exclure le livre actuel)
      final similarBooks = allBooks
          .where((book) => 
              book.id != currentBook.id && 
              book.isValid &&
              book.category?.id == currentBook.category?.id)
          .toList();
      
      // Limiter à 3 livres maximum
      final limitedBooks = similarBooks.length > 3 
          ? similarBooks.sublist(0, 3) 
          : similarBooks;
      
      setState(() {
        _similarBooks = limitedBooks;
      });
    } catch (e) {
      print('Erreur lors du chargement des livres similaires: $e');
    }
  }

  Future<void> _handleReserve() async {
    if (_book == null || _currentUser == null) return;

    try {
      final result = await _apiService.createReservation(
        _book!.id,
        _currentUser!.id,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_book!.title}" réservé avec succès'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        
        // Recharger les données du livre
        await _loadBookData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Erreur lors de la réservation'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la réservation: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handleBorrow() async {
    if (_book == null || _currentUser == null) return;

    if (!_book!.canBeBorrowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce livre n\'est pas disponible pour l\'emprunt'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    try {
      final result = await _apiService.createEmprunt(
        _book!.id,
        _currentUser!.id,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_book!.title}" emprunté avec succès'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        
        // Recharger les données du livre
        await _loadBookData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Erreur lors de l\'emprunt'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'emprunt: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
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
        currentIndex: 1,
        onTap: (index) {
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
          onPressed: () => context.go('/catalogue'),
        ),
        title: const Text(
          'Détails du livre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBookData,
            tooltip: 'Rafraîchir',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'dashboard') {
                context.go('/dashboard');
              } else if (value == 'help') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Aide"),
                    content: const Text("Pour toute question concernant ce livre, contactez le service de la bibliothèque."),
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
                context.go('/login');
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
      body: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage.isNotEmpty || _book == null
              ? _buildErrorWidget()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rectangle englobant livre + résumé
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Carte du livre + badge disponibilité
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 160,
                                      height: 220,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE9EDF5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _book!.categoryIcon,
                                              style: const TextStyle(fontSize: 48),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _book!.categoryName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color.fromARGB(255, 44, 80, 164),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _book!.available
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _book!.available
                                            ? "Disponible (${_book!.copies} exemplaires)"
                                            : "Indisponible",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Titre + auteur + catégorie + année
                              Text(
                                _book!.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C50A4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _book!.author,
                                    style: const TextStyle(color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _book!.displayYear,
                                    style: const TextStyle(color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.category_outlined,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _book!.categoryName,
                                    style: const TextStyle(color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              if (_book!.isbn?.isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.numbers,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ISBN: ${_book!.isbn}',
                                      style: const TextStyle(color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Résumé
                              const Text(
                                "Résumé",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _book!.description?.isNotEmpty == true
                                    ? _book!.description!
                                    : "Aucun résumé disponible pour ce livre.",
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Boutons "Réserver" / "Emprunter"
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _book!.canBeReserved ? _handleReserve : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C50A4),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFFCBD5E1),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Réserver"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _book!.canBeBorrowed ? _handleBorrow : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2C50A4),
                                side: const BorderSide(color: Color(0xFF2C50A4)),
                                disabledForegroundColor: const Color(0xFFCBD5E1),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Emprunter"),
                            ),
                          ),
                        ],
                      ),
                      if (_similarBooks.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        // Livres similaires
                        const Text(
                          "Livres similaires",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _similarBooks.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, index) {
                            final similarBook = _similarBooks[index];
                            return InkWell(
                              onTap: () => context.go('/livre/${similarBook.id}'),
                              child: Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE9EDF5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Center(
                                            child: Text(
                                              similarBook.categoryIcon,
                                              style: const TextStyle(fontSize: 32),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        similarBook.title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      floatingActionButton: _errorMessage.isNotEmpty
          ? FloatingActionButton(
              onPressed: _loadBookData,
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
            'Chargement du livre...',
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
              'Livre introuvable',
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
              onPressed: _loadBookData,
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
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/catalogue'),
              child: const Text('Retour au catalogue'),
            ),
          ],
        ),
      ),
    );
  }
}