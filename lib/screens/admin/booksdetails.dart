// lib/screens/admin/booksdetails.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/book.dart';
import '../../models/user.dart';

class BookDetailPage extends StatelessWidget {
  final String id;

  const BookDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final Book? book = Book.getBookById(id);

    if (book == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Text(
                    "Livre introuvable",
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    final int totalCopies = book.copies ?? (book.available ? 1 : 0);
    final int availableCopies = book.available ? (book.copies ?? 1) : 0;
    final int onLoanCopies = (totalCopies - availableCopies).clamp(0, totalCopies);

    void handleEdit() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: const Text(
            'Fonction d\'édition à venir',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    void handleDelete() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: const Text(
            'Livre supprimé avec succès',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      context.go('/admin/books');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton Retour
                    TextButton.icon(
                      onPressed: () => context.go('/admin/books'),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Retour aux livres'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Carte En-tête du Livre - VERSION CORRIGÉE
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFFE2E8F0).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isSmallScreen = constraints.maxWidth < 600;
                            
                            return isSmallScreen 
                                ? _buildMobileLayout(book, handleEdit, handleDelete)
                                : _buildDesktopLayout(book, handleEdit, handleDelete);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    _buildDescriptionCard(book),

                    const SizedBox(height: 16),

                    // Statistiques de disponibilité
                    _buildAvailabilityCard(totalCopies, availableCopies, onLoanCopies),

                    const SizedBox(height: 16),

                    // Emprunts en cours
                    _buildCurrentLoansCard(),

                    const SizedBox(height: 16),

                    // Historique des emprunts
                    _buildLoanHistoryCard(),

                    const SizedBox(height: 80),
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

  // Layout pour mobile
  Widget _buildMobileLayout(Book book, VoidCallback handleEdit, VoidCallback handleDelete) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Couverture du livre
        Center(
          child: Column(
            children: [
              Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.book_outlined,
                  size: 40,
                  color: Color(0xFF2C50A4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: book.available
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  book.available ? 'Disponible' : 'Indisponible',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Informations du livre
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              book.author,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Grille d'informations adaptée mobile
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
              children: [
                _buildInfoItem('ISBN', book.id),
                _buildInfoItem('Catégorie', book.category),
                _buildInfoItem('Année', book.year),
                _buildInfoItem('Éditeur', 'Dunod'),
                _buildInfoItem('Pages', '1312'),
                _buildInfoItem('Langue', 'Français'),
              ],
            ),

            const SizedBox(height: 20),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: handleEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C50A4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: handleDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Supprimer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Layout pour desktop
  Widget _buildDesktopLayout(Book book, VoidCallback handleEdit, VoidCallback handleDelete) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Couverture du livre
        Column(
          children: [
            Container(
              width: 128,
              height: 176,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.book_outlined,
                size: 48,
                color: Color(0xFF2C50A4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: book.available
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                book.available ? 'Disponible' : 'Indisponible',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 24),

        // Informations du livre
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.author,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              // Grille d'informations
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _buildInfoItem('ISBN', book.id),
                  _buildInfoItem('Catégorie', book.category),
                  _buildInfoItem('Année', book.year),
                  _buildInfoItem('Éditeur', 'Dunod'),
                  _buildInfoItem('Pages', '1312'),
                  _buildInfoItem('Langue', 'Français'),
                ],
              ),

              const SizedBox(height: 20),

              // Boutons d'action
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: handleEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C50A4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: handleDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(Book book) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFE2E8F0).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cet ouvrage présente un large éventail d\'algorithmes de manière détaillée mais accessible. Chaque chapitre est illustré par des exemples et des exercices.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard(int totalCopies, int availableCopies, int onLoanCopies) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFE2E8F0).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disponibilité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Les statistiques seront ajoutées ici
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLoansCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFE2E8F0).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emprunts en cours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 16),
            // Les emprunts seront ajoutés ici
          ],
        ),
      ),
    );
  }

  Widget _buildLoanHistoryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFE2E8F0).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique des emprunts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 16),
            // L'historique sera ajouté ici
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

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
          const Text(
            'Bibliothèque',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C50A4),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: const Color(0xFF64748B),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: const Color(0xFF64748B),
            onPressed: () {},
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
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/admin/dashboard');
              break;
            case 1:
              context.go('/admin/books');
              break;
            case 2:
              context.go('/admin/users');
              break;
            case 3:
              context.go('/admin/settings');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2C50A4),
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
}