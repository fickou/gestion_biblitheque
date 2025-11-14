import 'package:flutter/material.dart';
import '../models/user.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _handleLogout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Déconnexion réussie")),
    );
    // Ici tu peux naviguer vers la page login
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser; // ton modèle User

    return Scaffold(
      // ----- AppBar -----
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C50A4),
        title: const Text(
          "Mon profil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ----- Corps de la page -----
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Avatar + nom + rôle ---
           // --- Avatar + nom + rôle ---
        Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF2C50A4),
              child: Text(
                user.avatarText,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user.role,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),

            const SizedBox(height: 16),

            // --- Infos utilisateur ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(Icons.mail_outline, "Email", user.email),
                    const SizedBox(height: 8),
                    _infoRow(Icons.confirmation_num, "Matricule", user.matricule),
                    const SizedBox(height: 8),
                    _infoRow(Icons.shield_outlined, "Rôle", user.role),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Boutons ---
            _actionButton(context, Icons.person, "Modifier mon profil", onTap: () {}),
            _actionButton(context, Icons.notifications_none, "Paramètres de notifications", onTap: () {}),
            _actionButton(context, Icons.settings, "Paramètres", onTap: () {}),

            const SizedBox(height: 16),

            // --- Déconnexion ---
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                "Se déconnecter",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
      ),

      // ----- Bottom Navigation -----
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: const Color(0xFF2C50A4),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Catalogue"),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: "Emprunts"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  // Méthode utilitaire pour afficher les lignes d'info
  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2C50A4)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // Boutons d'action
  Widget _actionButton(BuildContext context, IconData icon, String label, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: Icon(icon, color: const Color(0xFF2C50A4)),
        label: Text(label, style: const TextStyle(color: Colors.black)),
        onPressed: onTap,
      ),
    );
  }
}
