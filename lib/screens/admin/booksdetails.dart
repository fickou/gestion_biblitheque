import 'package:flutter/material.dart';
import 'package:gestion_bibliotheque/models/book.dart';
import 'package:gestion_bibliotheque/widgets/notif.dart';
import 'package:go_router/go_router.dart';

class BookDetailPage extends StatefulWidget {
  final String id;
  
  const BookDetailPage({Key? key, required this.id}) : super(key: key);
  
  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  // Données mockées
  final Map<String, dynamic> mockBookDetail = {
    'id': "1",
    'title': "Introduction à l'Algorithmique",
    'author': "Thomas H. Cormen",
    'isbn': "978-2-10-054526-1",
    'category': "Informatique",
    'publishYear': 2010,
    'publisher': "Dunod",
    'pages': 1312,
    'language': "Français",
    'description': "Cet ouvrage présente un large éventail d'algorithmes de manière détaillée mais accessible. Chaque chapitre est illustré par des exemples et des exercices.",
    'available': true,
    'totalCopies': 5,
    'availableCopies': 2,
  };

  final List<Map<String, dynamic>> mockLoanHistory = [
    {'id': 1, 'user': "Amadou Diallo", 'date': "15/03/2025", 'returnDate': "29/03/2025", 'status': "returned"},
    {'id': 2, 'user': "Fatou Sall", 'date': "01/03/2025", 'returnDate': "15/03/2025", 'status': "returned"},
    {'id': 3, 'user': "Moussa Ndiaye", 'date': "10/02/2025", 'returnDate': "24/02/2025", 'status': "returned"},
    {'id': 4, 'user': "Aïssatou Ba", 'date': "05/02/2025", 'returnDate': "19/02/2025", 'status': "returned"},
  ];

  final List<Map<String, dynamic>> mockCurrentLoans = [
    {'id': 5, 'user': "Cheikh Fall", 'date': "20/03/2025", 'dueDate': "03/04/2025", 'status': "ongoing"},
    {'id': 6, 'user': "Mariama Sy", 'date': "18/03/2025", 'dueDate': "01/04/2025", 'status': "ongoing"},
    {'id': 7, 'user': "Ibrahima Sarr", 'date': "10/03/2025", 'dueDate': "24/03/2025", 'status': "late"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bouton retour
                      TextButton.icon(
                        onPressed: () => context.go('/admin/books'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF64748B)),
                        label: const Text(
                          'Retour aux livres',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Carte principale du livre
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section couverture + informations
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 600) {
                                    // Version mobile
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Couverture du livre
                                        Center(
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 128,
                                                height: 176,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE5E7EB),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.menu_book,
                                                  size: 48,
                                                  color: Color.fromARGB(255, 44, 80, 164),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: mockBookDetail['available'] 
                                                      ? const Color.fromARGB(255, 44, 80, 164)
                                                      : const Color(0xFFEF4444),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  mockBookDetail['available'] ? 'Disponible' : 'Indisponible',
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
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Titre et auteur
                                        Text(
                                          mockBookDetail['title'],
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          mockBookDetail['author'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Grille d'informations pour mobile
                                        Column(
                                          children: [
                                            _buildInfoItemMobile('ISBN', mockBookDetail['isbn']),
                                            const SizedBox(height: 12),
                                            _buildInfoItemMobile('Catégorie', mockBookDetail['category']),
                                            const SizedBox(height: 12),
                                            _buildInfoItemMobile('Année', mockBookDetail['publishYear'].toString()),
                                            const SizedBox(height: 12),
                                            _buildInfoItemMobile('Éditeur', mockBookDetail['publisher']),
                                            const SizedBox(height: 12),
                                            _buildInfoItemMobile('Pages', mockBookDetail['pages'].toString()),
                                            const SizedBox(height: 12),
                                            _buildInfoItemMobile('Langue', mockBookDetail['language']),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Boutons d'action - version mobile avec Wrap
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _buildActionButton(
                                              'Modifier',
                                              Icons.edit,
                                              const Color.fromARGB(255, 44, 80, 164),
                                              () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Fonction d\'édition à venir'),
                                                  ),
                                                );
                                              },
                                            ),
                                            _buildActionButton(
                                              'Supprimer',
                                              Icons.delete,
                                              const Color(0xFFEF4444),
                                              () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Livre supprimé avec succès'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                                Future.delayed(const Duration(milliseconds: 500), () {
                                                  context.go('/admin/books');
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Version desktop
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Couverture du livre
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 128,
                                                  height: 176,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE5E7EB),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.menu_book,
                                                    size: 48,
                                                    color: Color.fromARGB(255, 44, 80, 164),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: mockBookDetail['available'] 
                                                        ? const Color.fromARGB(255, 44, 80, 164)
                                                        : const Color(0xFFEF4444),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    mockBookDetail['available'] ? 'Disponible' : 'Indisponible',
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
                                                    mockBookDetail['title'],
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    mockBookDetail['author'],
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  
                                                  const SizedBox(height: 16),
                                                  
                                                  // Grille d'informations pour desktop
                                                  Wrap(
                                                    spacing: 16,
                                                    runSpacing: 12,
                                                    children: [
                                                      SizedBox(
                                                        width: 150,
                                                        child: _buildInfoItem('ISBN', mockBookDetail['isbn']),
                                                      ),
                                                      SizedBox(
                                                        width: 150,
                                                        child: _buildInfoItem('Catégorie', mockBookDetail['category']),
                                                      ),
                                                      SizedBox(
                                                        width: 150,
                                                        child: _buildInfoItem('Année', mockBookDetail['publishYear'].toString()),
                                                      ),
                                                      SizedBox(
                                                        width: 150,
                                                        child: _buildInfoItem('Éditeur', mockBookDetail['publisher']),
                                                      ),
                                                      SizedBox(
                                                        width: 150,
                                                        child: _buildInfoItem('Pages', mockBookDetail['pages'].toString()),
                                                      ),
                                                      SizedBox(
                                                        width: 150,
                                                        child: _buildInfoItem('Langue', mockBookDetail['language']),
                                                      ),
                                                    ],
                                                  ),
                                                  
                                                  const SizedBox(height: 16),
                                                  
                                                  // Boutons d'action - version desktop
                                                  Row(
                                                    children: [
                                                      _buildCompactActionButton(
                                                        'Modifier',
                                                        Icons.edit,
                                                        const Color.fromARGB(255, 44, 80, 164),
                                                        () {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Fonction d\'édition à venir'),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      
                                                      const SizedBox(width: 8),
                                                      
                                                      _buildCompactActionButton(
                                                        'Supprimer',
                                                        Icons.delete,
                                                        const Color(0xFFEF4444),
                                                        () {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Livre supprimé avec succès'),
                                                              backgroundColor: Colors.green,
                                                            ),
                                                          );
                                                          Future.delayed(const Duration(milliseconds: 500), () {
                                                            context.go('/admin/books');
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // Divider
                                        Container(
                                          height: 1,
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // Description
                                        const Text(
                                          'Description',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          mockBookDetail['description'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Statistiques de disponibilité
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Disponibilité',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      'Exemplaires total',
                                      mockBookDetail['totalCopies'].toString(),
                                      const Color.fromARGB(255, 44, 80, 164),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Disponibles',
                                      mockBookDetail['availableCopies'].toString(),
                                      Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'En prêt',
                                      (mockBookDetail['totalCopies'] - mockBookDetail['availableCopies']).toString(),
                                      Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Emprunts en cours
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Emprunts en cours',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                children: mockCurrentLoans.map((loan) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Color.fromARGB(255, 44, 80, 164),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                loan['user'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Emprunté le ${loan['date']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: loan['status'] == 'late'
                                                    ? Colors.red.withOpacity(0.1)
                                                    : const Color.fromARGB(255, 44, 80, 164).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                loan['status'] == 'late' ? 'En retard' : 'En cours',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: loan['status'] == 'late'
                                                      ? Colors.red
                                                      : const Color.fromARGB(255, 44, 80, 164),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Retour: ${loan['dueDate']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Historique des emprunts
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Historique des emprunts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                children: mockLoanHistory.map((item) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['user'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${item['date']} - ${item['returnDate']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Retourné',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
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
  
  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
  
  Widget _buildCompactActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 0, // Permet au bouton de s'adapter à son contenu
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildInfoItemMobile(String label, String value) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
  
  // Header
  Widget _buildHeader(BuildContext context) {
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
        currentIndex: _getCurrentIndex(),
        onTap: (index) => _onItemTapped(index),
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
  
  int _getCurrentIndex() {
    return 1; // Index 1 = Livres
  }
  
  void _onItemTapped(int index) {
    final context = this.context;
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