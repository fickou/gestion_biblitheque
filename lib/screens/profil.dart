import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/user.dart';
import '/services/api_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  
  void _handleLogout(BuildContext context) async {
    try {
      // Appeler la méthode logout du service
      await ApiService().logout();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Déconnexion réussie")),
      );
      
      // Utilisation de GoRouter pour la navigation
      context.go('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la déconnexion: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService().currentUser; // Récupérer l'utilisateur depuis ApiService

    // Vérifier si l'utilisateur est connecté
    if (!ApiService().isAuthenticated || user == null) {
      // Rediriger vers la page de connexion si non authentifié
      Future.delayed(Duration.zero, () {
        context.go('/login');
      });
      
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
            Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF2C50A4),
                  child: Text(
                    _getAvatarText(user),
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
                  user.role.name ?? 'Utilisateur',
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
                    _infoRow(Icons.confirmation_num, "Matricule", user.matricule ?? 'N/A'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.shield_outlined, "Rôle", user.role.name ?? 'Utilisateur'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Boutons ---
            _actionButton(context, Icons.person, "Modifier mon profil", onTap: () {
              _showEditProfileDialog(context, user);
            }),
            _actionButton(context, Icons.notifications_none, "Paramètres de notifications", onTap: () {
              _showNotificationSettings(context);
            }),
            _actionButton(context, Icons.settings, "Paramètres", onTap: () {
              _showSettings(context);
            }),

            const SizedBox(height: 16),

            // --- Section Admin (si applicable) ---
            if (user.role.name.toLowerCase() == 'admin' || user.role.name.toLowerCase() == 'administrateur')
              Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    "Administration",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2C50A4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _actionButton(
                    context, 
                    Icons.admin_panel_settings, 
                    "Gestion des utilisateurs", 
                    onTap: () => context.go('/admin/users'),
                  ),
                  _actionButton(
                    context, 
                    Icons.analytics, 
                    "Statistiques", 
                    onTap: () => context.go('/admin/stats'),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // --- Déconnexion ---
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                "Se déconnecter",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _handleLogout(context),
            ),

            const SizedBox(height: 16),

            // --- Info de session ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Session",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: ApiService().isAuthenticated ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ApiService().isAuthenticated ? "Connecté" : "Déconnecté",
                        style: TextStyle(
                          color: ApiService().isAuthenticated ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ----- Bottom Navigation -----
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 44, 80, 164),
        unselectedItemColor: const Color(0xFF64748B),
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

  // Méthode pour déterminer l'index actuel
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/dashboard') return 0;
    if (location == '/catalogue') return 1;
    if (location == '/emprunts') return 2;
    if (location == '/profil') return 3;
    return 0;
  }

  // Navigation pour la bottom bar
  void _onItemTapped(int index, BuildContext context) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
          side: BorderSide(color: Colors.grey.shade300),
        ),
        icon: Icon(icon, color: const Color(0xFF2C50A4)),
        label: Text(label, style: const TextStyle(color: Colors.black)),
        onPressed: onTap,
      ),
    );
  }

  // Méthode pour générer le texte de l'avatar
  String _getAvatarText(User user) {
    if (user.name.isNotEmpty) {
      // Prendre les initiales du nom
      final nameParts = user.name.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else if (nameParts[0].isNotEmpty) {
        return nameParts[0][0].toUpperCase();
      }
    }
    // Si pas de nom, utiliser l'email
    if (user.email.isNotEmpty) {
      return user.email[0].toUpperCase();
    }
    return '?';
  }

  // Méthodes pour les dialogues
  void _showEditProfileDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le profil"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "Nom complet",
                  hintText: "Entrez votre nom",
                ),
                controller: TextEditingController(text: user.name),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Email",
                  hintText: "Entrez votre email",
                ),
                controller: TextEditingController(text: user.email),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Matricule",
                  hintText: "Entrez votre matricule",
                ),
                controller: TextEditingController(text: user.matricule ?? ''),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter la mise à jour du profil
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fonctionnalité à venir")),
              );
            },
            child: const Text("Sauvegarder"),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Paramètres de notifications"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _notificationSwitch("Rappels de retour", true),
              _notificationSwitch("Nouveaux livres", true),
              _notificationSwitch("Promotions", false),
              _notificationSwitch("Annonces", true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  Widget _notificationSwitch(String label, bool initialValue) {
    return StatefulBuilder(
      builder: (context, setState) {
        return SwitchListTile(
          title: Text(label),
          value: initialValue,
          onChanged: (value) {
            setState(() {});
          },
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Langue"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text("Thème"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text("Confidentialité"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text("Aide"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("À propos"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("À propos"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Application Bibliothèque",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Version: 1.0.0"),
            Text("Utilisateur: ${ApiService().currentUser?.name}"),
            Text("Rôle: ${ApiService().currentUser?.role ?? 'Utilisateur'}"),
            const SizedBox(height: 16),
            const Text(
              "© 2024 Bibliothèque. Tous droits réservés.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }
}