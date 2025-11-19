// lib/screens/book_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/book.dart';

class BookDetailPage extends StatelessWidget {
  final String id;

  const BookDetailPage({super.key, required this.id});

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

    // Dérivés simples pour la section disponibilité (ton modèle n'a pas totalCopies)
    final int totalCopies = book.copies ?? (book.available ? 1 : 0);
    final int availableCopies = book.available ? (book.copies ?? 1) : 0;
    final int onLoanCopies = (totalCopies - availableCopies).clamp(0, totalCopies);

    // Mocks pour emprunts (comme dans ton exemple React)
    final List<Map<String, String>> mockCurrentLoans = [
      {"user": "Cheikh Fall", "date": "20/03/2025", "dueDate": "03/04/2025", "status": "ongoing"},
      {"user": "Mariama Sy", "date": "18/03/2025", "dueDate": "01/04/2025", "status": "ongoing"},
      {"user": "Ibrahima Sarr", "date": "10/03/2025", "dueDate": "24/03/2025", "status": "late"},
    ];

    final List<Map<String, String>> mockLoanHistory = [
      {"user": "Amadou Diallo", "date": "15/03/2025", "returnDate": "29/03/2025"},
      {"user": "Fatou Sall", "date": "01/03/2025", "returnDate": "15/03/2025"},
      {"user": "Moussa Ndiaye", "date": "10/02/2025", "returnDate": "24/02/2025"},
      {"user": "Aïssatou Ba", "date": "05/02/2025", "returnDate": "19/02/2025"},
    ];

    void handleEdit() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fonction d\'édition à venir')),
      );
    }

    void handleDelete() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livre supprimé avec succès')),
      );
      // Exemple de navigation après suppression :
      GoRouter.of(context).go('/catalogue');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 44, 80, 164),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => GoRouter.of(context).go('/catalogue'),
        ),
        title: const Text(
          'Détails du livre',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'accueil') GoRouter.of(context).go('/dashboard');
              if (value == 'parametres') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Paramètres"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock, color: Colors.blue),
                          title: const Text("Modifier le mot de passe"),
                          onTap: () {
                            Navigator.pop(ctx);
                            GoRouter.of(context).go('/modifier-mdp');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text("Se déconnecter"),
                          onTap: () {
                            Navigator.pop(ctx);
                            GoRouter.of(context).go('/login');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.orange),
                          title: const Text("Supprimer le compte"),
                          onTap: () {
                            Navigator.pop(ctx);
                            GoRouter.of(context).go('/supprimer-compte');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'accueil', child: Row(children: [Icon(Icons.home, color: Colors.blue), SizedBox(width: 10), Text('Accueil')])),
              PopupMenuItem(value: 'parametres', child: Row(children: [Icon(Icons.settings, color: Colors.grey), SizedBox(width: 10), Text('Paramètres')])),
            ],
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card header (cover + infos)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // cover + badge
                        Column(
                          children: [
                            Container(
                              width: 120,
                              height: 160,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9EDF5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.book_outlined, size: 56, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: book.available ? Colors.green : Colors.redAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                book.available ? "Disponible (${book.copies ?? 0})" : "Emprunté",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // infos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C50A4))),
                              const SizedBox(height: 6),
                              Row(children: [const Icon(Icons.person_outline, size: 18, color: Colors.grey), const SizedBox(width: 6), Text(book.author, style: const TextStyle(color: Colors.grey))]),
                              const SizedBox(height: 12),

                              // grid-like info rows (2 columns)
                              Wrap(
                                runSpacing: 8,
                                spacing: 24,
                                children: [
                                  infoTile("ISBN", book.id), // model has no isbn field; use id as placeholder
                                  infoTile("Catégorie", book.category),
                                  infoTile("Année", book.year),
                                  infoTile("Copies", "${totalCopies}"),
                                  infoTile("Statut", book.available ? "Disponible" : (book.status ?? "Emprunté")),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: handleEdit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2C50A4),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    child: const Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text("Modifier")]),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: handleDelete,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    child: const Row(children: [Icon(Icons.delete, size: 16), SizedBox(width: 8), Text("Supprimer")]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Description
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                      const SizedBox(height: 8),
                      Text(book.description ?? "Aucun résumé disponible pour ce livre.", style: const TextStyle(height: 1.5, color: Color(0xFF0F172A))),
                    ]),
                  ),
                ),

                const SizedBox(height: 18),

                // Disponibilité stats
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Disponibilité", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        statBox(totalCopies.toString(), "Exemplaires total"),
                        statBox(availableCopies.toString(), "Disponibles"),
                        statBox(onLoanCopies.toString(), "En prêt"),
                      ]),
                    ]),
                  ),
                ),

                const SizedBox(height: 18),

                // Emprunts en cours
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Emprunts en cours", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Column(
                        children: mockCurrentLoans.map((loan) {
                          final bool isLate = loan["status"] == "late";
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE9EDF5), shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.grey)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(loan["user"]!, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text("Emprunté le ${loan["date"]}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: isLate ? Colors.red : const Color(0xFF2C50A4), borderRadius: BorderRadius.circular(12)), child: Text(isLate ? "En retard" : "En cours", style: const TextStyle(color: Colors.white, fontSize: 12))),
                                  const SizedBox(height: 6),
                                  Text("Retour: ${loan["dueDate"]}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                ]),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 18),

                // Historique des emprunts
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Historique des emprunts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Column(
                        children: mockLoanHistory.map((loan) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(loan["user"]!, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text("${loan["date"]} - ${loan["returnDate"]}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))])),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10)), child: const Text("Retourné", style: TextStyle(fontSize: 12))),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    ]),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),

      // Bottom nav (même style que CataloguePage)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))]),
        child: BottomNavigationBar(
          currentIndex: 1, // Catalogue actif (adapté si tu veux mettre autre index)
          onTap: (index) {
            switch (index) {
              case 0:
                GoRouter.of(context).go('/dashboard');
                break;
              case 1:
                GoRouter.of(context).go('/catalogue');
                break;
              case 2:
                GoRouter.of(context).go('/emprunts');
                break;
              case 3:
                GoRouter.of(context).go('/profil');
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
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Catalogue'),
            BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Emprunts'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  // petits widgets réutilisables
  Widget infoTile(String label, String value) {
    return SizedBox(
      width: 180,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
      ]),
    );
  }

  Widget statBox(String number, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C50A4))),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
    ]);
  }

  void handleEdit() {}
}
