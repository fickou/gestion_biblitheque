import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/book.dart';
class BooksAdminPage extends StatefulWidget {
  const BooksAdminPage({super.key});

  @override
  State<BooksAdminPage> createState() => _BooksAdminPageState();
}

class _BooksAdminPageState extends State<BooksAdminPage> {
  String _searchQuery = '';
  late List<Book> _books;

  @override
  void initState() {
    super.initState();
    // Tu peux remplacer par ta vraie source API plus tard
    _books = Book.catalogueBooks;
  }

  void _deleteBook(String id, String title) {
    setState(() {
      _books.removeWhere((book) => book.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          '"$title" supprimé avec succès',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _books.where((b) {
      final q = _searchQuery.toLowerCase();
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Gestion des livres",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === HEADER ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Gestion des livres",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "${_books.length} livres au total",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                // === BOUTON AJOUTER ===
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Ajouter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C50A4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                )
              ],
            ),

            const SizedBox(height: 16),

            // === BARRE DE RECHERCHE ===
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                hintText: "Rechercher par titre ou auteur...",
                hintStyle:
                    const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // === LISTE ===
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final book = filtered[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        // === INFORMATIONS LIVRE ===
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.author,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      book.category,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // ISBN : on ne l’a pas → on utilise year ou ''.
                                  Text(
                                    "Année : ${book.year}",
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

                        // === DISPONIBILITÉ ===
                        Column(
                          children: [
                            Text(
                              book.available ? "Disponible" : "Indisponible",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: book.available
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              book.copies != null
                                  ? "${book.copies} copies"
                                  : "",
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 12),

                        // === BOUTONS ACTIONS ===
                        Column(
                          children: [
                            // ÉDITER (fonction à implémenter)
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFF2C50A4)),
                              onPressed: () {},
                            ),

                            // SUPPRIMER
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () =>
                                  _deleteBook(book.id, book.title),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

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
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Livres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  // Méthode pour déterminer l'index actuel
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/admin/dashboard') return 0;
    if (location == '/admin/books') return 1;
    if (location == '/emprunts') return 2;
    if (location == '/profil') return 3;
    return 0;
  }

  // Navigation pour la bottom bar
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/books');
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
