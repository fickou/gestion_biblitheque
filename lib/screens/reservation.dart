// lib/screens/reservations_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _reservations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    if (!_apiService.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _error = 'Veuillez vous connecter pour voir vos réservations';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reservations = await _apiService.getReservations();
      
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCancel(BuildContext context, String reservationId, String bookTitle) async {
    try {
      // Demander confirmation
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Annuler la réservation'),
          content: Text('Êtes-vous sûr de vouloir annuler la réservation pour "$bookTitle" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Oui, annuler'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // TODO: Implémenter l'appel API pour annuler la réservation
        // Pour l'instant, on simule l'annulation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réservation "$bookTitle" annulée'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Recharger les réservations
        await _loadReservations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePickup(BuildContext context, String reservationId, String bookTitle) async {
    try {
      // TODO: Implémenter l'appel API pour marquer comme retiré
      // Pour l'instant, on simule le retrait
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$bookTitle" est prêt pour le retrait'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Mettre à jour le statut localement
      setState(() {
        _reservations = _reservations.map((res) {
          if (res['id'] == reservationId) {
            return {...res, 'status': 'Retiré'};
          }
          return res;
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Date inconnue';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  bool _isReservationExpired(String? dateString) {
    if (dateString == null) return false;
    
    try {
      final reserveDate = DateTime.parse(dateString);
      final now = DateTime.now();
      final daysDifference = now.difference(reserveDate).inDays;
      return daysDifference > 7; // Une réservation expire après 7 jours
    } catch (e) {
      return false;
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReservations,
            tooltip: 'Rafraîchir',
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.menu, color: Colors.white, size: 28),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (!_apiService.isAuthenticated)
                ElevatedButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: const Text('Se connecter'),
                ),
              if (_apiService.isAuthenticated)
                ElevatedButton(
                  onPressed: _loadReservations,
                  child: const Text('Réessayer'),
                ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 80),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_reservations.length} réservation(s)",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (_reservations.isNotEmpty)
                      TextButton.icon(
                        onPressed: _loadReservations,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Actualiser'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _reservations.isNotEmpty
                    ? _buildReservationsList()
                    : _buildEmptyState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReservationsList() {
    return Column(
      children: _reservations.map((reservation) {
        final bookTitle = reservation['bookTitle'] ?? 'Titre inconnu';
        final bookAuthor = reservation['bookAuthor'] ?? 'Auteur inconnu';
        final status = reservation['status'] ?? 'Inconnu';
        final reserveDate = reservation['reserveDate'];
        final isExpired = _isReservationExpired(reserveDate);
        final isAvailable = status == 'Disponible';
        final isPending = status == 'En attente';
        final isPickedUp = status == 'Retiré';
        
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
                            const Icon(
                              Icons.book_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                            // Badge d'expiration
                            if (isExpired && isPending)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookAuthor,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            // Badge status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? Colors.green
                                    : isPending
                                        ? isExpired
                                            ? Colors.red
                                            : Colors.orange
                                        : isPickedUp
                                            ? Colors.blue
                                            : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isExpired && isPending ? 'Expiré' : status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Réservé le: ${_formatDate(reserveDate)}",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (isExpired && isPending)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            "(Expiré)",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (reservation['userName'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Par: ${reservation['userName']}",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Bouton Annuler
                      Expanded(
                        child: OutlinedButton(
                          style: ButtonStyle(
                            side: WidgetStateProperty.resolveWith<BorderSide>(
                              (states) {
                                if (states.contains(WidgetState.hovered) ||
                                    states.contains(WidgetState.pressed)) {
                                  return const BorderSide(
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
                            foregroundColor: WidgetStateProperty.resolveWith<Color>(
                              (states) {
                                if (states.contains(WidgetState.hovered) ||
                                    states.contains(WidgetState.pressed)) {
                                  return Colors.white;
                                }
                                return Colors.black;
                              },
                            ),
                            backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                              (states) {
                                if (states.contains(WidgetState.hovered) ||
                                    states.contains(WidgetState.pressed)) {
                                  return const Color(0xFF0D6EFD);
                                }
                                return Colors.transparent;
                              },
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          onPressed: (isExpired || isPickedUp)
                              ? null
                              : () => _handleCancel(
                                    context,
                                    reservation['id'],
                                    bookTitle,
                                  ),
                          child: const Text(
                            "Annuler",
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Bouton Retirer (visible seulement si disponible)
                      if (isAvailable && !isExpired)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _handlePickup(
                              context,
                              reservation['id'],
                              bookTitle,
                            ),
                            child: const Text(
                              "Retirer",
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      // Bouton Réserver à nouveau (si expiré)
                      if (isExpired && isPending)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // TODO: Naviguer vers le catalogue ou réserver à nouveau
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cette réservation a expiré. Veuillez en créer une nouvelle.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            child: const Text(
                              "Réserver à nouveau",
                              style: TextStyle(fontSize: 15),
                            ),
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
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.book_rounded,
            size: 70,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 12),
          Text(
            "Aucune réservation active",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Vos réservations apparaîtront ici",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.go('/catalogue');
            },
            child: const Text('Parcourir le catalogue'),
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == "/dashboard" || location == "/") return 0;
    if (location == "/catalogue") return 1;
    if (location == "/emprunts") return 2;
    if (location == "/reservations") return 3;
    if (location == "/profil") return 4;
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
        context.go("/reservations");
        break;
      case 4:
        context.go("/profil");
        break;
    }
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF0D6EFD),
      unselectedItemColor: Colors.grey,
      currentIndex: _getCurrentIndex(context),
      onTap: (i) => _onTapNav(context, i),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Accueil",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          label: "Catalogue",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: "Emprunts",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark),
          label: "Réservations",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profil",
        ),
      ],
    );
  }
}