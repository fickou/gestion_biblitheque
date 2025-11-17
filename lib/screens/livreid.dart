import 'package:flutter/material.dart';
import '../models/book.dart';
import 'package:go_router/go_router.dart';

class LivreDetailPage extends StatelessWidget {
  final String id;
  const LivreDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final Book? book = Book.getBookById(id);

    if (book == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 44, 80, 164),
          title: const Text('Détails du livre'),
        ),
        body: const Center(child: Text("Livre introuvable")),
      );
    }

    void handleExtend(String title) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prêt prolongé pour "$title"')),
      );
    }

    void handleReturn(String title) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$title" marqué comme retourné')),
      );
    }

    // ───────────────────────────────
    // FOOTER / BOTTOM NAVIGATION
    // ───────────────────────────────
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // HEADER avec logo + titre + menu
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'accueil') context.go('/dashboard');
              if (value == 'parametres') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ouverture des paramètres...')),
                );
              }
              if (value == 'quitter') Navigator.pop(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'accueil',
                child: Row(
                  children: [
                    Icon(Icons.home, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Accueil')
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'parametres',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey),
                    SizedBox(width: 10),
                    Text('Paramètres')
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'quitter',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Quitter')
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // Corps principal
      body: SingleChildScrollView(
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
                            child: const Icon(Icons.book_outlined,
                                size: 80, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: book.available
                                  ? Colors.green
                                  : Colors.redAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              book.available
                                  ? "Disponible (${book.copies ?? 0} exemplaires)"
                                  : "Emprunté",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Titre + auteur + catégorie + année
                    Text(
                      book.title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C50A4)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(book.author, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(book.year, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 16),
                        const Icon(Icons.category_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(book.category, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Résumé
                    const Text("Résumé",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      book.description != null && book.description!.isNotEmpty
                          ? book.description!
                          : "Aucun résumé disponible pour ce livre.",
                      style: const TextStyle(
                          fontSize: 14, height: 1.5, color: Colors.black87),
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
                    onPressed: book.available ? () => handleExtend(book.title) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C50A4),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: const Text("Réserver"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: book.available ? () => handleReturn(book.title) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2C50A4),
                      side: const BorderSide(color: Color(0xFF2C50A4)),
                    ),
                    child: const Text("Emprunter"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Livres similaires
            const Text("Livres similaires",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final similarBook = Book.catalogueBooks[index];
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                                color: const Color(0xFFE9EDF5),
                                borderRadius: BorderRadius.circular(6)),
                            child: const Center(
                                child: Icon(Icons.book,
                                    size: 40, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(similarBook.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),

      // FOOTER
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
