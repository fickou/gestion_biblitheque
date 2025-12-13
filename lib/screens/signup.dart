import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/iconelivre.dart';
import '../providers/auth_provider.dart'; // Ajoutez cette importation

class Signup extends ConsumerStatefulWidget { // Changez StatefulWidget à ConsumerStatefulWidget
  const Signup({super.key});

  @override
  ConsumerState<Signup> createState() => _SignupState();
}

class _SignupState extends ConsumerState<Signup> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Étudiant';
  bool _isLoading = false; // Ajoutez un état de chargement

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _matriculeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleInscription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      
      final result = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        matricule: _matriculeController.text.trim(),
        role: _selectedRole,
      );

      if (result['success'] == true) {
        // Message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Déterminer la redirection basée sur le rôle
        String redirectPath;
        if (_selectedRole == 'Administrateur' || _selectedRole == 'Bibliothécaire') {
          redirectPath = '/admin/dashboard';
        } else {
          redirectPath = '/dashboard';
        }

        // Attendre un peu avant la redirection
        await Future.delayed(const Duration(milliseconds: 500));
        
        // ➤ Redirection GoRouter vers le dashboard approprié
        if (mounted) {
          context.go(redirectPath);
        }
      } else {
        // Afficher l'erreur de Firebase
        final errorMessage = result['error'] ?? 'Erreur lors de l\'inscription';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromARGB(255, 44, 80, 164),
                  const Color.fromARGB(255, 44, 80, 164).withOpacity(0.9),
                  const Color.fromARGB(255, 44, 80, 164).withOpacity(0.8),
                ],
              ),
            ),
          ),

          // Floating icons
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.1,
                child: Stack(
                  children: const [
                    FloatingBookIcon(top: 40, left: 40, size: 80, delay: 0),
                    FloatingBookIcon(top: 128, right: 80, size: 64, delay: 1000),
                    FloatingBookIcon(bottom: 80, left: 128, size: 96, delay: 2000),
                    FloatingBookIcon(bottom: 160, right: 40, size: 72, delay: 500),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Bouton retour
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back, 
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _isLoading 
                            ? null 
                            : () => context.go('/login'),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Logo rond
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset('assets/images/logo.png'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Formulaire
                    Card(
                      elevation: 24,
                      color: Colors.white.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nomController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nom',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez entrer votre nom';
                                        }
                                        return null;
                                      },
                                      enabled: !_isLoading,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _prenomController,
                                      decoration: const InputDecoration(
                                        labelText: 'Prénom',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez entrer votre prénom';
                                        }
                                        return null;
                                      },
                                      enabled: !_isLoading,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre email';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                    return 'Format d\'email invalide';
                                  }
                                  return null;
                                },
                                enabled: !_isLoading,
                              ),

                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _matriculeController,
                                decoration: const InputDecoration(
                                  labelText: 'Matricule',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre matricule';
                                  }
                                  return null;
                                },
                                enabled: !_isLoading,
                              ),

                              const SizedBox(height: 20),

                              DropdownButtonFormField(
                                value: _selectedRole,
                                items: [
                                  'Étudiant',
                                  'Enseignant',
                                  'Bibliothécaire', // Ajouté pour cohérence
                                  'Administrateur'
                                ].map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  );
                                }).toList(),
                                onChanged: _isLoading 
                                    ? null 
                                    : (value) {
                                        setState(() {
                                          _selectedRole = value as String;
                                        });
                                      },
                                decoration: const InputDecoration(
                                  labelText: 'Rôle',
                                ),
                              ),

                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Mot de passe',
                                  hintText: 'Minimum 6 caractères',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Entrez un mot de passe';
                                  }
                                  if (value.length < 6) {
                                    return 'Minimum 6 caractères';
                                  }
                                  return null;
                                },
                                enabled: !_isLoading,
                              ),

                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Confirmer mot de passe',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Confirmez le mot de passe';
                                  }
                                  return null;
                                },
                                enabled: !_isLoading,
                              ),

                              const SizedBox(height: 25),

                              // 🔥 BOUTON INSCRIPTION
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleInscription,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Inscription en cours...',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          "S'inscrire",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Center(
                                child: TextButton(
                                  onPressed: _isLoading 
                                      ? null 
                                      : () => context.go('/login'),
                                  child: const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 44, 80, 164),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}