import 'package:flutter/material.dart';
import '/widgets/notif.dart';
import 'package:go_router/go_router.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  // Données du profil
  final Map<String, dynamic> adminProfile = {
    'name': 'Dr. Oumar Diop',
    'email': 'oumar.diop@ugb.edu.sn',
    'role': 'Administrateur Principal',
    'department': 'Bibliothèque UFR SAT',
    'phone': '+221 77 999 88 77',
    'joinDate': 'Janvier 2022'
  };

  // État des switches
  bool darkMode = false;
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool twoFactorAuth = false;
  bool weeklySummary = false;

  // Contrôleurs pour les champs de formulaire
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les données existantes
    _nameController.text = adminProfile['name'];
    _emailController.text = adminProfile['email'];
    _phoneController.text = adminProfile['phone'];
    _departmentController.text = adminProfile['department'];
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _handleSaveProfile() {
    // Mettre à jour les données du profil
    setState(() {
      adminProfile['name'] = _nameController.text;
      adminProfile['email'] = _emailController.text;
      adminProfile['phone'] = _phoneController.text;
      adminProfile['department'] = _departmentController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil mis à jour avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleChangePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonction de changement de mot de passe à venir'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleLogout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Déconnexion réussie'),
        backgroundColor: Colors.green,
      ),
    );
    // Naviguer vers la page de connexion
    context.go('/login');
  }

  String _getInitials(String name) {
    List<String> parts = name.split(' ');
    String initials = '';
    for (var part in parts) {
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
      }
    }
    return initials;
  }

  @override
  Widget build(BuildContext context) {
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
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 16),
                    _buildSecurityCard(),
                    const SizedBox(height: 16),
                    _buildNotificationsCard(),
                    const SizedBox(height: 16),
                    _buildPreferencesCard(),
                    const SizedBox(height: 16),
                    _buildLogoutCard(),
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
            onPressed: () => context.go('/profiladmin'), // Ajouter cette ligne
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFE2E8F0).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mon Profil',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gérez vos informations personnelles et vos préférences',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Avatar and info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFD6E4FF),
                  child: Text(
                    _getInitials(adminProfile['name']),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 44, 80, 164),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminProfile['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        adminProfile['role'],
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${adminProfile['department']} • Membre depuis ${adminProfile['joinDate']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: BorderSide(color: const Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: const Color(0xFF0F172A),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Changer la photo',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Divider
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
            // Profile form
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid for form fields
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          _buildFormField('Nom complet', _nameController),
                          const SizedBox(height: 12),
                          _buildFormField('Email', _emailController, isEmail: true),
                          const SizedBox(height: 12),
                          _buildFormField('Téléphone', _phoneController),
                          const SizedBox(height: 12),
                          _buildFormField('Département', _departmentController),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField('Nom complet', _nameController),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField('Email', _emailController, isEmail: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField('Téléphone', _phoneController),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField('Département', _departmentController),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
                // Save buttons
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // Annuler les modifications
                          _nameController.text = adminProfile['name'];
                          _emailController.text = adminProfile['email'];
                          _phoneController.text = adminProfile['phone'];
                          _departmentController.text = adminProfile['department'];
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          side: BorderSide(color: const Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleSaveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.save,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Enregistrer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {bool isEmail = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            hintText: label,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color.fromARGB(255, 44, 80, 164)),
            ),
          ),
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return _buildSettingsCard(
      icon: Icons.lock,
      title: 'Sécurité',
      description: 'Gérez votre mot de passe et la sécurité',
      children: [
        _buildSettingItem(
          title: 'Mot de passe',
          description: 'Dernière modification il y a 3 mois',
          action: OutlinedButton(
            onPressed: _handleChangePassword,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              side: BorderSide(color: const Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Changer',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItem(
          title: 'Authentification à deux facteurs',
          description: 'Sécurisez votre compte avec 2FA',
          action: Switch(
            value: twoFactorAuth,
            onChanged: (value) {
              setState(() {
                twoFactorAuth = value;
              });
            },
            activeThumbColor: const Color.fromARGB(255, 44, 80, 164),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsCard() {
    return _buildSettingsCard(
      icon: Icons.notifications,
      title: 'Notifications',
      description: 'Configurez vos préférences de notification',
      children: [
        _buildSettingItem(
          title: 'Notifications par email',
          description: 'Recevez des notifications importantes par email',
          action: Switch(
            value: emailNotifications,
            onChanged: (value) {
              setState(() {
                emailNotifications = value;
              });
            },
            activeThumbColor: const Color.fromARGB(255, 44, 80, 164),
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItem(
          title: 'Notifications push',
          description: 'Notifications en temps réel sur l\'application',
          action: Switch(
            value: pushNotifications,
            onChanged: (value) {
              setState(() {
                pushNotifications = value;
              });
            },
            activeThumbColor: const Color.fromARGB(255, 44, 80, 164),
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItem(
          title: 'Résumé hebdomadaire',
          description: 'Rapport d\'activité chaque lundi',
          action: Switch(
            value: weeklySummary,
            onChanged: (value) {
              setState(() {
                weeklySummary = value;
              });
            },
            activeThumbColor: const Color.fromARGB(255, 44, 80, 164),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard() {
    return _buildSettingsCard(
      icon: Icons.language,
      title: 'Préférences',
      description: 'Personnalisez l\'apparence de l\'application',
      children: [
        _buildSettingItem(
          title: 'Mode sombre',
          description: 'Utilisez l\'interface en mode sombre',
          action: Switch(
            value: darkMode,
            onChanged: (value) {
              setState(() {
                darkMode = value;
              });
            },
            activeThumbColor: const Color.fromARGB(255, 44, 80, 164),
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItem(
          title: 'Langue',
          description: 'Français',
          action: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              side: BorderSide(color: const Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Changer',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }

Widget _buildLogoutCard() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: const Color(0xFFE2E8F0).withOpacity(0.4),
        width: 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texte explicatif
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se déconnecter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Déconnectez-vous de votre compte administrateur',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Bouton de déconnexion
          ElevatedButton(
            onPressed: _handleLogout,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Déconnexion',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFE2E8F0).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: const Color.fromARGB(255, 44, 80, 164),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Divider
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
            // Settings items
            Column(
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String description,
    required Widget action,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        action,
      ],
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
        currentIndex: 4,
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
            icon: Icon(Icons.home),
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
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context) {
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
        // On est déjà sur la page paramètres
        break;
    }
  }
}