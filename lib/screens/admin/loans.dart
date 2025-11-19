import 'package:flutter/material.dart';
import '../../models/book.dart';

class EmpruntsPage extends StatefulWidget {
  const EmpruntsPage({super.key});

  @override
  State<EmpruntsPage> createState() => _EmpruntsPageState();
}

class _EmpruntsPageState extends State<EmpruntsPage> {
  List<Book> loans = Book.emprunts;
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Filtrer par titre ou auteur
    final filteredLoans = loans.where((loan) {
      final q = searchQuery.toLowerCase();
      return loan.title.toLowerCase().contains(q) ||
          loan.author.toLowerCase().contains(q);
    }).toList();

    final lateCount = loans.where((loan) => loan.status == "En retard").length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des emprunts"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ---- TITRE + BADGE ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Gestion des emprunts",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${loans.length} emprunts actifs",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (lateCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 18),
                        const SizedBox(width: 5),
                        Text("$lateCount en retard",
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 15),

            // ---- BARRE DE RECHERCHE ----
            TextField(
              decoration: InputDecoration(
                hintText: "Rechercher par livre ou utilisateur...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),

            const SizedBox(height: 15),

            // ---- LISTE DES EMPRUNTS ----
            Expanded(
              child: ListView.builder(
                itemCount: filteredLoans.length,
                itemBuilder: (context, index) {
                  final loan = filteredLoans[index];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // --- Infos du livre ---
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loan.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  loan.author,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),

                                const SizedBox(height: 8),

                                // Badge statut
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: loan.status == "En retard"
                                        ? Colors.red.shade200
                                        : Colors.green.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    loan.status ?? "En cours",
                                    style: TextStyle(
                                      color: loan.status == "En retard"
                                          ? Colors.red.shade900
                                          : Colors.green.shade900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- Dates ---
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Emprunté le",
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                              Text(
                                loan.borrowDate ?? "-",
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Retour prévu",
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                              Text(
                                loan.returnDate ?? "-",
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),

                          const SizedBox(width: 15),

                          // ---- BOUTON RETOURNER ----
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                loans.removeWhere((l) => l.id == loan.id);
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('"${loan.title}" a été retourné.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text("Retourner"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
