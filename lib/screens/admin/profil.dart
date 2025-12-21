import 'package:flutter/material.dart';
import '/widgets/notif.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/providers/auth_provider.dart';

class AdminProfilePage extends ConsumerWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _AdminProfilePageContent();
  }
}

class _AdminProfilePageContent extends ConsumerStatefulWidget {
  const _AdminProfilePageContent();

  @override
  ConsumerState<_AdminProfilePageContent> createState() => __AdminProfilePageContentState();
}

class __AdminProfilePageContentState extends ConsumerState<_AdminProfilePageContent> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  bool darkMode = false;
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool twoFactorAuth = false;
  bool weeklySummary = false;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm(ref);
    });
  }

  void _initializeForm(WidgetRef ref) {
    final userAsync = ref.read(completeUserProvider);
    final user = userAsync.value;
    if (user != null) {
      // Utilisez ?? '' pour gérer le cas null
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = '+221 77 999 88 77';
      _departmentController.text = 'Bibliothèque UFR SAT';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile(WidgetRef ref) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      print('=== SAUVEGARDE DU PROFIL ===');
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Erreur lors de la sauvegarde: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleChangePassword(WidgetRef ref) async {
    try {
      final authService = ref.read(authServiceProvider);
      final currentUser = ref.read(completeUserProvider).value;
      
      if (currentUser?.email != null) {
        // Vérifiez le nom exact de la méthode dans votre AuthService
        // Si c'est 'changePassword' au lieu de 'sendPasswordResetEmail'
        await authService.changePassword(currentUser!.email!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de réinitialisation envoyé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      print('Erreur lors du changement de mot de passe: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi de l\'email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogout(WidgetRef ref) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déconnexion réussie'),
          backgroundColor: Colors.green,
        ),
      );
      
      context.go('/login');
    } catch (error) {
      print('Erreur lors de la déconnexion: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la déconnexion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getInitials(String? name) { // Accepte String?
    if (name == null || name.isEmpty) return 'AD';
    return _generateAvatarText(name);
  }

  String _generateAvatarText(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '$first$second'.toUpperCase();
    }
    final length = name.length;
    if (length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name.toUpperCase();
  }

  String _formatJoinDate(DateTime? createdAt) {
    if (createdAt != null) {
      final date = createdAt;
      final months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
    return 'Janvier 2022';
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isLoggedInProvider);
    final completeUserAsync = ref.watch(completeUserProvider);
    
    if (!isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return completeUserAsync.when(
      data: (completeUser) {
        if (completeUser == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Vérifier si l'utilisateur est admin
        if (!completeUser.isAdmin) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Accès réservé aux administrateurs',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return _buildProfileContent(context, completeUser, ref);
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromARGB(255, 44, 80, 164),
            ),
          ),
        ),
      ),
      error: (error, stack) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.refresh(completeUserProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                  ),
                  child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, CompleteUser user, WidgetRef ref) {
    final joinDate = _formatJoinDate(user.createdAt);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(ref),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileCard(user, joinDate, ref),
                    const SizedBox(height: 16),
                    _buildSecurityCard(ref),
                    const SizedBox(height: 16),
                    _buildNotificationsCard(),
                    const SizedBox(height: 16),
                    _buildPreferencesCard(),
                    const SizedBox(height: 16),
                    _buildLogoutCard(ref),
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

  Widget _buildHeader(WidgetRef ref) {
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
            onPressed: () {
              final currentLocation = GoRouterState.of(context).uri.toString();
              if (!currentLocation.contains('/profiladmin')) {
                context.go('/profiladmin');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(CompleteUser user, String joinDate, WidgetRef ref) {
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFD6E4FF),
                  child: Text(
                    _getInitials(user.name), // Maintenant ça fonctionne
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
                        user.name ?? 'Administrateur', // Gestion du null
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.role.name ?? 'Administrateur',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_departmentController.text} • Membre depuis $joinDate • Matricule: ${user.matricule}',
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          _buildFormField('Nom complet', _nameController),
                          const SizedBox(height: 12),
                          _buildFormField('Email', _emailController, isEmail: true, enabled: false),
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
                                child: _buildFormField('Email', _emailController, isEmail: true, enabled: false),
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
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : () {
                          _nameController.text = user.name ?? '';
                          _emailController.text = user.email ?? '';
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
                        onPressed: _isSaving ? null : () => _handleSaveProfile(ref),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          backgroundColor: _isSaving 
                              ? Colors.grey 
                              : const Color.fromARGB(255, 44, 80, 164),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
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

  Widget _buildFormField(String label, TextEditingController controller, 
      {bool isEmail = false, bool enabled = true}) {
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
          enabled: enabled,
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
            filled: !enabled,
            fillColor: const Color(0xFFF8FAFC),
          ),
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        ),
      ],
    );
  }

  Widget _buildSecurityCard(WidgetRef ref) {
    return _buildSettingsCard(
      icon: Icons.lock,
      title: 'Sécurité',
      description: 'Gérez votre mot de passe et la sécurité',
      children: [
        _buildSettingItem(
          title: 'Mot de passe',
          description: 'Dernière modification il y a 3 mois',
          action: OutlinedButton(
            onPressed: () => _handleChangePassword(ref),
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

  Widget _buildLogoutCard(WidgetRef ref) {
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
            ElevatedButton(
              onPressed: () => _handleLogout(ref),
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
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
        break;
    }
  }
}

extension StringExtension on String {
  String get name => this;
}
