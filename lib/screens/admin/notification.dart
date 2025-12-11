import 'package:flutter/material.dart';
import 'package:gestion_bibliotheque/models/notif.dart';
import 'package:gestion_bibliotheque/widgets/notif.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsService _notificationsService = NotificationsService();
  String activeTab = 'all';
  final List<String> tabs = ['all', 'unread', 'late', 'loan', 'return'];

  void handleMarkAsRead(String id) {
    setState(() {
      _notificationsService.markAsRead(id);
    });
    _showSuccessSnackbar('Notification marquée comme lue');
  }

  void handleMarkAllAsRead() {
    setState(() {
      _notificationsService.markAllAsRead();
    });
    _showSuccessSnackbar('Toutes les notifications marquées comme lues');
  }

  void handleDelete(String id) {
    setState(() {
      _notificationsService.delete(id);
    });
    _showSuccessSnackbar('Notification supprimée');
  }

  void handleClearAll() {
    setState(() {
      _notificationsService.clearAll();
    });
    _showSuccessSnackbar('Toutes les notifications supprimées');
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<NotificationItem> getFilteredNotifications() {
    if (activeTab == 'all') return _notificationsService.notifications;
    if (activeTab == 'unread') {
      return _notificationsService.notifications.where((n) => !n.read).toList();
    }
    return _notificationsService.notifications.where((n) => n.type == activeTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notificationsService.unreadCount;
    final filteredNotifications = getFilteredNotifications();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header IDENTIQUE aux autres pages
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec boutons - MODIFIÉ POUR ÉVITER LE DÉBORDEMENT
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 500) {
                          // Version mobile - boutons en dessous
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Notifications',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$unreadCount notification${unreadCount > 1 ? 's' : ''} non lue${unreadCount > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactButton(
                                      'Tout marquer',
                                      Icons.check_circle,
                                      const Color(0xFF64748B),
                                      handleMarkAllAsRead,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactButton(
                                      'Tout supprimer',
                                      Icons.delete,
                                      Colors.red,
                                      handleClearAll,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          // Version desktop - boutons à droite
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Notifications',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$unreadCount notification${unreadCount > 1 ? 's' : ''} non lue${unreadCount > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _buildCompactButton(
                                    'Tout marquer',
                                    Icons.check_circle,
                                    const Color(0xFF64748B),
                                    handleMarkAllAsRead,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCompactButton(
                                    'Tout supprimer',
                                    Icons.delete,
                                    Colors.red,
                                    handleClearAll,
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 400) {
                            // Version mobile pour les tabs - utilisation de SingleChildScrollView horizontal
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: tabs.map((tab) {
                                  final isActive = activeTab == tab;
                                  final tabLabel = _getTabLabel(tab);
                                  final count = _getTabCount(tab);
                                  
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: tab != 'return' ? const BorderSide(color: Color(0xFFE2E8F0)) : BorderSide.none,
                                      ),
                                    ),
                                    child: Material(
                                      color: isActive ? const Color.fromARGB(255, 44, 80, 164) : Colors.white,
                                      borderRadius: _getBorderRadiusForTab(tab),
                                      child: InkWell(
                                        onTap: () => setState(() => activeTab = tab),
                                        borderRadius: _getBorderRadiusForTab(tab),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                          child: Column(
                                            children: [
                                              Text(
                                                tabLabel,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isActive ? Colors.white : const Color(0xFF64748B),
                                                ),
                                              ),
                                              if (count > 0)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isActive ? Colors.white : const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    '$count',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isActive ? const Color.fromARGB(255, 44, 80, 164) : const Color(0xFF475569),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          } else {
                            // Version desktop pour les tabs
                            return Row(
                              children: tabs.map((tab) {
                                final isActive = activeTab == tab;
                                final tabLabel = _getTabLabel(tab);
                                final count = _getTabCount(tab);
                                
                                return Expanded(
                                  child: Material(
                                    color: isActive ? const Color.fromARGB(255, 44, 80, 164) : Colors.white,
                                    borderRadius: _getBorderRadiusForTab(tab),
                                    child: InkWell(
                                      onTap: () => setState(() => activeTab = tab),
                                      borderRadius: _getBorderRadiusForTab(tab),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: tab != 'return' ? const BorderSide(color: Color(0xFFE2E8F0)) : BorderSide.none,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              tabLabel,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isActive ? Colors.white : const Color(0xFF64748B),
                                              ),
                                            ),
                                            if (count > 0)
                                              Container(
                                                margin: const EdgeInsets.only(top: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isActive ? Colors.white : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '$count',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isActive ? const Color.fromARGB(255, 44, 80, 164) : const Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Liste des notifications
                    if (filteredNotifications.isEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color(0xFFE2E8F0).withOpacity(0.4),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 48,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Aucune notification',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: filteredNotifications.map((notification) {
                          final isUnread = !notification.read;
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: const Color(0xFFE2E8F0).withOpacity(0.4),
                                width: isUnread ? 0 : 1,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: isUnread ? const Border(
                                  left: BorderSide(
                                    color: Color.fromARGB(255, 44, 80, 164),
                                    width: 4,
                                  ),
                                ) : null,
                                borderRadius: BorderRadius.circular(12),
                                color: isUnread ? const Color.fromARGB(255, 44, 80, 164).withOpacity(0.05) : Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icône
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isUnread 
                                            ? const Color.fromARGB(255, 44, 80, 164).withOpacity(0.2)
                                            : const Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        notification.iconData,
                                        size: 20,
                                        color: notification.iconColor,
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    // Contenu
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: isUnread ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isUnread)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(255, 44, 80, 164),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'Nouveau',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          Text(
                                            notification.message,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF64748B),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                notification.time,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                              
                                              Row(
                                                children: [
                                                  if (isUnread)
                                                    TextButton(
                                                      onPressed: () => handleMarkAsRead(notification.id),
                                                      style: TextButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        minimumSize: Size.zero,
                                                      ),
                                                      child: const Text(
                                                        'Marquer comme lu',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Color.fromARGB(255, 44, 80, 164),
                                                        ),
                                                      ),
                                                    ),
                                                  IconButton(
                                                    onPressed: () => handleDelete(notification.id),
                                                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    
                    const SizedBox(height: 80), // Espace pour le bottom navigation
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
  
  // Widget pour créer un bouton compact
  Widget _buildCompactButton(String text, IconData icon, Color textColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: Colors.white,
        side: BorderSide(color: textColor.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // Header IDENTIQUE aux autres pages
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
          // Note: On est déjà sur la page notifications, donc on désactive l'icône
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: const Color(0xFF64748B),
            onPressed: null, // Désactivé car on est déjà sur la page
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: const Color(0xFF64748B),
            onPressed: () => context.go('/profiladmin'),
          ),
        ],
      ),
    );
  }
  
  String _getTabLabel(String tab) {
    switch (tab) {
      case 'all': return 'Tout';
      case 'unread': return 'Non lues';
      case 'late': return 'Retards';
      case 'loan': return 'Emprunts';
      case 'return': return 'Retours';
      default: return tab;
    }
  }
  
  int _getTabCount(String tab) {
    final notifications = _notificationsService.notifications;
    switch (tab) {
      case 'all': return notifications.length;
      case 'unread': return notifications.where((n) => !n.read).length;
      case 'late': return notifications.where((n) => n.type == 'late').length;
      case 'loan': return notifications.where((n) => n.type == 'loan').length;
      case 'return': return notifications.where((n) => n.type == 'return').length;
      default: return 0;
    }
  }
  
  BorderRadius _getBorderRadiusForTab(String tab) {
    if (tab == 'all') {
      return const BorderRadius.only(
        topLeft: Radius.circular(8),
        bottomLeft: Radius.circular(8),
      );
    } else if (tab == 'return') {
      return const BorderRadius.only(
        topRight: Radius.circular(8),
        bottomRight: Radius.circular(8),
      );
    }
    return BorderRadius.zero;
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
        currentIndex: _getCurrentIndex(context),
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
  
  int _getCurrentIndex(BuildContext context) {
    return 0;
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