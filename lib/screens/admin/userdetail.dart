import 'package:flutter/material.dart';
import '/widgets/notif.dart';
import 'package:go_router/go_router.dart';
import '/services/api_service.dart';
import '/models/user.dart';
import '/models/emprunt.dart';
import '/models/reservation.dart';

class UserDetailPage extends StatefulWidget {
  final String id;
  
  const UserDetailPage({super.key, required this.id});
  
  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final ApiService _apiService = ApiService();
  User? user;
  List<Emprunt> activeLoans = [];
  List<Emprunt> loanHistory = [];
  List<Reservation> reservations = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchUserLoans();
    _fetchUserReservations();
  }

  Future<void> _fetchUserDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final fetchedUser = await _apiService.getUserById(widget.id);
      
      setState(() {
        user = fetchedUser;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des données utilisateur: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserLoans() async {
    try {
      final allLoans = await _apiService.getUserEmprunts(widget.id);
      
      setState(() {
        activeLoans = allLoans.where((loan) => loan.status.toLowerCase() == 'en cours').toList();
        loanHistory = allLoans.where((loan) => 
          loan.status.toLowerCase() == 'retourné' || 
          (loan.returnDate != null && loan.status.toLowerCase() != 'en cours')
        ).toList();
      });
    } catch (e) {
      print('Erreur lors du chargement des emprunts: $e');
    }
  }

  Future<void> _fetchUserReservations() async {
    try {
      final fetchedReservations = await _apiService.getUserReservations(widget.id);
      
      setState(() {
        reservations = fetchedReservations;
      });
    } catch (e) {
      print('Erreur lors du chargement des réservations: $e');
    }
  }

  // CORRECTION 1: Utiliser 'actif' au lieu de 'active'
  Future<void> _handleSuspend() async {
    if (user == null) return;

    try {
      // CORRECTION: utiliser 'actif' et 'suspendu' (français)
      final newStatus = user!.status.toLowerCase() == 'actif' ? 'suspendu' : 'actif';
      await _apiService.updateUserStatus(widget.id, newStatus);
      
      // Recharger les données utilisateur
      await _fetchUserDetails();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur ${newStatus == 'suspendu' ? 'suspendu' : 'réactivé'}'),
          backgroundColor: newStatus == 'suspendu' ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleEdit() async {
    if (user == null) return;

    // Naviguer vers la page d'édition avec les données actuelles
    final result = await context.push(
      '/admin/etudiants/edit/${widget.id}',
      extra: user,
    );

    // Si l'édition a réussi, recharger les données
    if (result == true) {
      await _fetchUserDetails();
    }
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

  // CORRECTION 2: Fonction pour obtenir le libellé du statut
  String _getUserStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
        return 'Actif';
      case 'suspendu':
        return 'Suspendu';
      case 'inactif':
        return 'Inactif';
      default:
        return status;
    }
  }

  // CORRECTION 3: Fonction pour obtenir la couleur du statut
  Color _getUserStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
        return const Color.fromARGB(255, 44, 80, 164); // Bleu
      case 'suspendu':
        return const Color(0xFFEF4444); // Rouge
      case 'inactif':
        return const Color(0xFF64748B); // Gris
      default:
        return const Color(0xFF64748B); // Gris par défaut
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            if (isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: const Color.fromARGB(255, 44, 80, 164),
                  ),
                ),
              )
            else if (errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchUserDetails,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (user == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off,
                        size: 64,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Utilisateur non trouvé',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/admin/etudiants'),
                        child: const Text('Retour à la liste'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(maxWidth: 896),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bouton retour
                        TextButton.icon(
                          onPressed: () => context.go('/admin/etudiants'),
                          icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF64748B)),
                          label: const Text(
                            'Retour aux utilisateurs',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Carte principale de l'utilisateur
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 600) {
                                  return _buildMobileLayout(user!);
                                } else {
                                  return _buildDesktopLayout(user!);
                                }
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Statistiques
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              return _buildMobileStats(user!);
                            } else {
                              return _buildDesktopStats(user!);
                            }
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Emprunts actifs
                        _buildLoansSection(
                          'Emprunts actifs',
                          activeLoans,
                          true,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Réservations
                        _buildReservationsSection(),
                        
                        const SizedBox(height: 24),
                        
                        // Historique des emprunts
                        _buildLoansSection(
                          'Historique des emprunts',
                          loanHistory,
                          false,
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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildDesktopLayout(User user) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 44, 80, 164).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(user.name),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 44, 80, 164),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 24),
            
            // Informations de l'utilisateur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.studentId,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // CORRECTION 4: Utiliser les fonctions de statut
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getUserStatusColor(user.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getUserStatusLabel(user.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Grille d'informations
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12,
                    children: [
                      _buildInfoItem(
                        Icons.mail,
                        'Email',
                        user.email,
                      ),
                      _buildInfoItem(
                        Icons.phone,
                        'Téléphone',
                        user.phone,
                      ),
                      _buildInfoItem(
                        Icons.menu_book,
                        'Département',
                        user.department,
                      ),
                      _buildInfoItem(
                        Icons.school,
                        'Niveau',
                        user.level,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Inscrit depuis le ${user.registrationDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Boutons d'action
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _handleEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Modifier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      
                      // CORRECTION 5: Bouton suspendre avec le bon texte
                      ElevatedButton.icon(
                        onPressed: _handleSuspend,
                        icon: Icon(
                          user.status.toLowerCase() == 'suspendu' ? Icons.check_circle : Icons.block,
                          size: 16,
                        ),
                        label: Text(
                          user.status.toLowerCase() == 'suspendu' ? 'Réactiver' : 'Suspendre',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.status.toLowerCase() == 'suspendu' 
                            ? const Color(0xFF10B981) // Vert pour réactiver
                            : const Color(0xFFEF4444), // Rouge pour suspendre
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 44, 80, 164).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _getInitials(user.name),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 44, 80, 164),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Nom et statut
        Column(
          children: [
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user.studentId,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            // CORRECTION 6: Afficher le bon statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getUserStatusColor(user.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getUserStatusLabel(user.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Informations
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              Icons.mail,
              'Email',
              user.email,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              Icons.phone,
              'Téléphone',
              user.phone,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              Icons.menu_book,
              'Département',
              user.department,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              Icons.school,
              'Niveau',
              user.level,
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Text(
          'Inscrit depuis le ${user.registrationDate}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Boutons d'action
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _handleEdit,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 44, 80, 164),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            
            // CORRECTION 7: Bouton suspendre mobile
            ElevatedButton.icon(
              onPressed: _handleSuspend,
              icon: Icon(
                user.status.toLowerCase() == 'suspendu' ? Icons.check_circle : Icons.block,
                size: 16,
              ),
              label: Text(
                user.status.toLowerCase() == 'suspendu' ? 'Réactiver' : 'Suspendre',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: user.status.toLowerCase() == 'suspendu' 
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStats(User user) {
    // Calculer les statistiques à partir des données réelles
    final totalLoans = activeLoans.length + loanHistory.length;
    final lateLoans = activeLoans.where((loan) => loan.isLate).length;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            totalLoans.toString(),
            'Total emprunts',
            const Color.fromARGB(255, 44, 80, 164),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            activeLoans.length.toString(),
            'En cours',
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            lateLoans.toString(),
            'En retard',
            const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            reservations.length.toString(),
            'Réservations',
            const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStats(User user) {
    // Calculer les statistiques à partir des données réelles
    final totalLoans = activeLoans.length + loanHistory.length;
    final lateLoans = activeLoans.where((loan) => loan.isLate).length;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                totalLoans.toString(),
                'Total emprunts',
                const Color.fromARGB(255, 44, 80, 164),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                activeLoans.length.toString(),
                'En cours',
                const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                lateLoans.toString(),
                'En retard',
                const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                reservations.length.toString(),
                'Réservations',
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoansSection(String title, List<Emprunt> loans, bool isActive) {
    if (loans.isEmpty) {
      return Container();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: loans.map((loan) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFF1F5F9) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: isActive ? null : Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 500) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isActive ? Icons.menu_book : Icons.check_circle,
                                    size: 16,
                                    color: isActive 
                                      ? const Color.fromARGB(255, 44, 80, 164)
                                      : Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loan.displayBookTitle,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Emprunté le ${loan.formattedBorrowDate}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive 
                                      ? _getStatusColor(loan.status).withOpacity(0.1)
                                      : Colors.transparent,
                                    border: isActive 
                                      ? null 
                                      : Border.all(color: const Color(0xFFE5E7EB)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getStatusLabel(loan.status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isActive 
                                        ? _getStatusColor(loan.status)
                                        : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  isActive 
                                    ? 'Retour: ${loan.formattedReturnDate ?? "Non défini"}'
                                    : 'Retourné: ${loan.formattedReturnDate ?? "Non défini"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isActive ? Icons.menu_book : Icons.check_circle,
                                      size: 16,
                                      color: isActive 
                                        ? const Color.fromARGB(255, 44, 80, 164)
                                        : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loan.displayBookTitle,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Emprunté le ${loan.formattedBorrowDate}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
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
                                    color: isActive 
                                      ? _getStatusColor(loan.status).withOpacity(0.1)
                                      : Colors.transparent,
                                    border: isActive 
                                      ? null 
                                      : Border.all(color: const Color(0xFFE5E7EB)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getStatusLabel(loan.status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isActive 
                                        ? _getStatusColor(loan.status)
                                        : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isActive 
                                    ? 'Retour: ${loan.formattedReturnDate ?? "Non défini"}'
                                    : 'Retourné: ${loan.formattedReturnDate ?? "Non défini"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsSection() {
    if (reservations.isEmpty) {
      return Container();
    }

    return Card(
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
              'Réservations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: reservations.map((reservation) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 500) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.schedule,
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
                                        reservation.bookTitle,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Réservé le ${reservation.reserveDate}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                              child: Text(
                                reservation.status == 'pending' ? 'En attente' : 'Confirmée',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.schedule,
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
                                          reservation.bookTitle,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Réservé le ${reservation.reserveDate}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
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
                              child: Text(
                                reservation.status == 'pending' ? 'En attente' : 'Confirmée',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String value, String label, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
        return const Color.fromARGB(255, 44, 80, 164);
      case 'en retard':
        return const Color(0xFFEF4444);
      case 'retourné':
        return Colors.green;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
        return 'En cours';
      case 'en retard':
        return 'En retard';
      case 'retourné':
        return 'Retourné';
      default:
        return status;
    }
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
        currentIndex: 2, // Index pour "Étudiants"
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
        context.go('/profiladmin');
        break;
    }
  }
}