import 'package:flutter/material.dart';
import '/models/reservation.dart';
import '/models/emprunt.dart';
import '/models/book.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/services/api_service.dart';
import '/providers/auth_provider.dart';

class LivreDetailPage extends ConsumerStatefulWidget {
  final String id;
  const LivreDetailPage({super.key, required this.id});

  @override
  ConsumerState<LivreDetailPage> createState() => _LivreDetailPageState();
}

class _LivreDetailPageState extends ConsumerState<LivreDetailPage> {
  final ApiService _apiService = ApiService();
  Book? _book;
  List<Book> _similarBooks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isReserving = false;
  bool _isBorrowing = false;
  List<dynamic> _userEmprunts = [];
  List<dynamic> _userReservations = [];

  @override
  void initState() {
    super.initState();
    _loadBookData();
    _loadUserEmpruntsAndReservations();
  }

  // Récupérer l'utilisateur connecté via Riverpod
  CompleteUser? get _currentUser {
    final completeUserAsync = ref.watch(completeUserProvider);
    return completeUserAsync.value;
  }

  // Vérifier si l'utilisateur est connecté
  bool get _isAuthenticated {
    return ref.watch(isLoggedInProvider);
  }

  Future<void> _loadUserEmpruntsAndReservations() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      // Charger les emprunts de l'utilisateur
      final emprunts = await _apiService.getUserEmprunts(user.uid);
      setState(() {
        _userEmprunts = emprunts;
      });

      // Charger les réservations de l'utilisateur
      final allReservations = await _apiService.getReservations();
      final userReservations = allReservations
          .where((reservation) => reservation.user?.id == user.uid)
          .toList();
      setState(() {
        _userReservations = userReservations;
      });
    } catch (e) {
      print('Erreur chargement données utilisateur: $e');
    }
  }

  Future<void> _loadBookData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final book = await _apiService.getBookById(widget.id);
      
      if (book != null && book.isValid) {
        setState(() {
          _book = book;
          _isLoading = false;
        });
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
      final similarBooks = allBooks
          .where((book) => 
              book.id != currentBook.id && 
              book.isValid &&
              book.category?.id == currentBook.category?.id)
          .toList();
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

  // 📌 MÉTHODE POUR RÉSERVER AVEC VÉRIFICATIONS
  Future<void> _handleReserve() async {
    // Vérification 1: Utilisateur connecté
    if (!_isAuthenticated || _currentUser == null) {
      _showNotConnectedDialog();
      return;
    }

    // Vérification 2: Livre disponible
    if (_book == null) return;

    // Vérification 3: L'utilisateur n'a pas déjà emprunté ce livre
    final hasBorrowed = _userEmprunts.any((emprunt) => 
        emprunt is Emprunt && emprunt.bookId == _book!.id && emprunt.status != 'returned');
    
    if (hasBorrowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous avez déjà emprunté "${_book!.title}"'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Vérification 4: L'utilisateur n'a pas déjà réservé ce livre
    final hasReserved = _userReservations.any((reservation) => 
        reservation is Reservation && reservation.book?.id == _book!.id && reservation.status == 'pending');
    
    if (hasReserved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous avez déjà réservé "${_book!.title}"'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Vérification 5: Le livre peut être réservé
    if (!_book!.canBeReserved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce livre ne peut pas être réservé actuellement'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la réservation'),
        content: Text('Voulez-vous réserver "${_book!.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C50A4),
            ),
            child: const Text('Réserver'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isReserving = true;
    });

    try {
      debugPrint("📘 Book ID: ${_book!.id}");
      debugPrint("👤 User ID: ${_currentUser!.uid}");

      final result = await _apiService.createReservation(
        _book!.id,
        _currentUser!.uid,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_book!.title}" réservé avec succès'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Recharger les données
        await Future.wait([
          _loadBookData(),
          _loadUserEmpruntsAndReservations(),
        ]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Erreur lors de la réservation'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la réservation: $e'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isReserving = false;
      });
    }
  }

  // 📌 MÉTHODE POUR EMPRUNTER AVEC VÉRIFICATIONS
  Future<void> _handleBorrow() async {
    // Vérification 1: Utilisateur connecté
    if (!_isAuthenticated || _currentUser == null) {
      _showNotConnectedDialog();
      return;
    }

    // Vérification 2: Livre disponible
    if (_book == null) return;

    // Vérification 3: L'utilisateur n'a pas déjà emprunté ce livre
    final hasBorrowed = _userEmprunts.any((emprunt) => 
        emprunt is Emprunt && emprunt.bookId == _book!.id && emprunt.status != 'returned');
    
    if (hasBorrowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous avez déjà emprunté "${_book!.title}"'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Vérification 4: L'utilisateur n'a pas déjà réservé ce livre
    final hasReserved = _userReservations.any((reservation) => 
        reservation is Reservation && reservation.book?.id == _book!.id && reservation.status == 'pending');
    
    if (hasReserved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous avez déjà réservé "${_book!.title}"'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Vérification 5: Le livre est disponible pour l'emprunt
    if (!_book!.canBeBorrowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce livre n\'est pas disponible pour l\'emprunt'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Demander confirmation avec durée d'emprunt
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'emprunt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous emprunter "${_book!.title}" ?'),
            const SizedBox(height: 8),
            const Text(
              'Durée d\'emprunt: 14 jours',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C50A4),
            ),
            child: const Text('Emprunter'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isBorrowing = true;
    });

    try {
      final result = await _apiService.createEmprunt(
        _book!.id,
        _currentUser!.uid,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_book!.title}" emprunté avec succès'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Recharger les données
        await Future.wait([
          _loadBookData(),
          _loadUserEmpruntsAndReservations(),
        ]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Erreur lors de l\'emprunt'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'emprunt: $e'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isBorrowing = false;
      });
    }
  }

  void _showNotConnectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Vous devez être connecté pour réserver ou emprunter un livre.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C50A4),
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  // Méthode pour vérifier si l'utilisateur peut réserver
  bool _canReserve() {
    if (!_isAuthenticated || _currentUser == null || _book == null) return false;
    
    final hasBorrowed = _userEmprunts.any((emprunt) => 
        emprunt is Emprunt && emprunt.bookId == _book!.id && emprunt.status != 'returned');
    
    final hasReserved = _userReservations.any((reservation) => 
        reservation is Reservation && reservation.book?.id == _book!.id && reservation.status == 'pending');
    
    return !hasBorrowed && !hasReserved && _book!.canBeReserved;
  }

  // Méthode pour vérifier si l'utilisateur peut emprunter
  bool _canBorrow() {
    if (!_isAuthenticated || _currentUser == null || _book == null) return false;
    
    final hasBorrowed = _userEmprunts.any((emprunt) => 
        emprunt is Emprunt && emprunt.bookId == _book!.id && emprunt.status != 'returned');
    
    final hasReserved = _userReservations.any((reservation) => 
        reservation is Reservation && reservation.book?.id == _book!.id && reservation.status == 'pending');
    
    return !hasBorrowed && !hasReserved && _book!.canBeBorrowed;
  }

  // Méthode pour obtenir le texte de l'avatar (inspirée de ProfilePage)
  String _getAvatarText(CompleteUser user) {
    final name = user.displayName;
    if (name.isNotEmpty) {
      final nameParts = name.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else if (nameParts[0].isNotEmpty) {
        return nameParts[0][0].toUpperCase();
      }
    }
    
    final mysqlAvatar = user.mysqlData['avatarText'];
    if (mysqlAvatar != null && mysqlAvatar.toString().isNotEmpty) {
      return mysqlAvatar.toString();
    }
    
    return user.email != null && user.email!.isNotEmpty 
        ? user.email![0].toUpperCase()
        : 'U';
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
    // Observer l'état d'authentification comme dans ProfilePage
    final isAuthenticated = ref.watch(isLoggedInProvider);
    
    // Si non authentifié et qu'on essaie de réserver/emprunter, on redirige
    if (!isAuthenticated && (_isReserving || _isBorrowing)) {
      Future.delayed(Duration.zero, () {
        context.go('/login');
      });
    }

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
          // Affichage de l'avatar utilisateur si connecté
          if (_currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(
                  _getAvatarText(_currentUser!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C50A4),
                  ),
                ),
              ),
            ),
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
                              // Info utilisateur si connecté
                              if (_currentUser != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF2C50A4).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: const Color(0xFF2C50A4),
                                            child: Text(
                                              _getAvatarText(_currentUser!),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _currentUser!.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFF2C50A4),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Vérifier si déjà emprunté
                                      if (_userEmprunts.any((emprunt) => 
                                          emprunt is Emprunt && emprunt.bookId == _book!.id && emprunt.status != 'returned'))
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green[700],
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Vous avez déjà emprunté ce livre',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        )
                                      // Vérifier si déjà réservé
                                      else if (_userReservations.any((reservation) => 
                                          reservation is Reservation && reservation.book?.id == _book!.id && reservation.status == 'pending'))
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              color: Colors.orange[700],
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Vous avez déjà réservé ce livre',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        const Text(
                                          'Vous pouvez réserver ou emprunter ce livre',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
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
                              onPressed: _isReserving ? null : (_canReserve() ? _handleReserve : null),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C50A4),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFFCBD5E1),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isReserving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text("Réserver"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isBorrowing ? null : (_canBorrow() ? _handleBorrow : null),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2C50A4),
                                side: const BorderSide(color: Color(0xFF2C50A4)),
                                disabledForegroundColor: const Color(0xFFCBD5E1),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isBorrowing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF2C50A4),
                                      ),
                                    )
                                  : const Text("Emprunter"),
                            ),
                          ),
                        ],
                      ),
                      // Messages d'information
                      if (!_isAuthenticated) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[300]!),
                          ),
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Row(
                              children: [
                                Icon(Icons.info, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Connectez-vous pour réserver ou emprunter ce livre',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward, color: Colors.orange, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
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
          const Text(
            'Chargement du livre...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          if (!_isAuthenticated) ...[
            const SizedBox(height: 8),
            const Text(
              'Veuillez vous connecter pour réserver ou emprunter',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ],
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