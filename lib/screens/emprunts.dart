import 'package:flutter/material.dart';
import '../models/emprunt.dart';

class EmpruntsPage extends StatelessWidget {
  const EmpruntsPage({super.key});

  void handleExtend(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Prêt prolongé pour "$title"')),
    );
  }

  void handleReturn(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$title" marqué comme retourné')),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // ← Important
          children: [
            Image.asset('assets/images/ufr.png', height: 36),
            const SizedBox(width: 8),
            const Text(
              'Mes emprunts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'accueil') Navigator.pushNamed(context, '/home');
              if (value == 'parametres') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ouverture des paramètres...')),
                );
              }
              if (value == 'quitter') Navigator.pop(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'accueil',
                child: Row(
                  children: [
                    Icon(Icons.home, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Accueil')
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'parametres',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey),
                    SizedBox(width: 10),
                    Text('Paramètres')
                  ],
                ),
              ),
              const PopupMenuItem(
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: emprunts.isNotEmpty
            ? ListView.separated(
                itemCount: emprunts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final emprunt = emprunts[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9EDF5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.book, size: 30, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emprunt.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      emprunt.author,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: emprunt.status == "En retard"
                                            ? Colors.red
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        emprunt.status,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text("Emprunté le: ${emprunt.borrowDate}",
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text("À retourner le: ${emprunt.returnDate}",
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => handleExtend(context, emprunt.title),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2C50A4),
                                    side: const BorderSide(color: Color(0xFF2C50A4)),
                                  ),
                                  child: const Text("Prolonger"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => handleReturn(context, emprunt.title),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2C50A4),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Retourner"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.book, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text("Aucun emprunt en cours", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
      ),
    );
  }
}