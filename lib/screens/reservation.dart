import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gestion_bibliotheque/models/reservation.dart';

class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  void _handleCancel(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Réservation annulée pour "$title"')),
    );
  }

  void _handlePickup(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$title" est prêt pour le retrait')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        elevation: 0,
        title: const Text(
          "Réservations",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.menu, color: Colors.white, size: 28),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 80),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${reservations.length} réservation(s)",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  reservations.isNotEmpty
                      ? Column(
                          children: reservations.map((res) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Icône livre personnalisée
                                          Container(
                                            width: 64,
                                            height: 88,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Icône livre principale
                                                Icon(Icons.book_rounded,
                                                    size: 40, color: Colors.white),
                                                // Point rouge en haut à droite
                                                
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  res.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  res.author,
                                                  style: TextStyle(color: Colors.grey.shade600),
                                                ),
                                                const SizedBox(height: 8),
                                                // Badge status
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: res.status == "Disponible"
                                                        ? Colors.green
                                                        : Colors.grey.shade300,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    res.status,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: res.status == "Disponible"
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
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
                                          Icon(Icons.calendar_today,
                                              size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Réservé le: ${res.reserveDate}",
                                            style:
                                                TextStyle(color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          // Bouton Annuler avec hover amélioré
                                          Expanded(
                                            child: OutlinedButton(
                                              style: ButtonStyle(
                                                side: MaterialStateProperty.resolveWith<BorderSide>(
                                                  (states) {
                                                    if (states.contains(MaterialState.hovered) ||
                                                        states.contains(MaterialState.pressed)) {
                                                      return BorderSide(
                                                        color: Color(0xFF0D6EFD),
                                                        width: 1.5,
                                                      );
                                                    }
                                                    return BorderSide(
                                                      color: Colors.grey.shade400,
                                                      width: 1.5,
                                                    );
                                                  },
                                                ),
                                                foregroundColor:
                                                    MaterialStateProperty.resolveWith<Color>(
                                                        (states) {
                                                  if (states.contains(MaterialState.hovered) ||
                                                      states.contains(MaterialState.pressed)) {
                                                    return Colors.white; // Texte blanc au survol
                                                  }
                                                  return Colors.black;
                                                }),
                                                backgroundColor:
                                                    MaterialStateProperty.resolveWith<Color?>(
                                                        (states) {
                                                  if (states.contains(MaterialState.hovered) ||
                                                      states.contains(MaterialState.pressed)) {
                                                    return Color(0xFF0D6EFD); // Bleu clair au survol
                                                  }
                                                  return Colors.transparent;
                                                }),
                                                shape: MaterialStateProperty.all(
                                                  RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(8)),
                                                ),
                                                padding: MaterialStateProperty.all(
                                                  const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                              ),
                                              onPressed: () => _handleCancel(context, res.title),
                                              child: const Text("Annuler", style: TextStyle(fontSize: 15)),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Bouton Retirer
                                          if (res.status == "Disponible")
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF0D6EFD),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                onPressed: () => _handlePickup(context, res.title),
                                                child: const Text("Retirer",
                                                    style: TextStyle(fontSize: 15)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : _buildEmptyState(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0D6EFD),
        unselectedItemColor: Colors.grey,
        currentIndex: _getCurrentIndex(context),
        onTap: (i) => _onTapNav(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: "Catalogue"),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: "Emprunts"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.book_rounded, size: 70, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text("Aucune réservation active",
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == "/dashboard") return 0;
    if (location == "/catalogue") return 1;
    if (location == "/emprunts") return 2;
    if (location == "/profil") return 3;
    return 0;
  }

  void _onTapNav(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go("/dashboard");
        break;
      case 1:
        context.go("/catalogue");
        break;
      case 2:
        context.go("/emprunts");
        break;
      case 3:
        context.go("/profil");
        break;
    } 
  }
}