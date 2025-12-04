// lib/models/notif.dart
import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String type; // "late", "loan", "return", "user", "reservation"
  final String title;
  final String message;
  final String time;
  final bool read;
  final String iconName; // "AlertCircle", "BookOpen", "CheckCircle", etc.

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.read,
    required this.iconName,
  });

  // Méthode pour convertir en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'time': time,
      'read': read,
      'iconName': iconName,
    };
  }

  // Méthode pour créer depuis un Map
  static NotificationItem fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      time: map['time'] ?? '',
      read: map['read'] ?? false,
      iconName: map['iconName'] ?? '',
    );
  }

  // Convertir iconName en IconData
  IconData get iconData {
    switch (iconName) {
      case 'AlertCircle':
        return Icons.warning;
      case 'BookOpen':
        return Icons.menu_book;
      case 'CheckCircle':
        return Icons.check_circle;
      case 'User':
        return Icons.person;
      case 'Clock':
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  // Couleur de l'icône basée sur le type
  Color get iconColor {
    switch (type) {
      case 'late':
        return Colors.red;
      case 'loan':
        return Colors.blue;
      case 'return':
        return Colors.green;
      case 'user':
        return Colors.blue;
      case 'reservation':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      type: 'late',
      title: 'Livre en retard',
      message: "Le livre 'Introduction à l'Algorithmique' emprunté par Amadou Diallo est en retard de 3 jours.",
      time: 'Il y a 5 minutes',
      read: false,
      iconName: 'AlertCircle',
    ),
    NotificationItem(
      id: '2',
      type: 'loan',
      title: 'Nouvel emprunt',
      message: "Fatou Sall a emprunté 'Data Mining et Machine Learning'.",
      time: 'Il y a 15 minutes',
      read: false,
      iconName: 'BookOpen',
    ),
    NotificationItem(
      id: '3',
      type: 'return',
      title: 'Retour de livre',
      message: "Moussa Ndiaye a retourné 'Python pour la Data Science'.",
      time: 'Il y a 1 heure',
      read: true,
      iconName: 'CheckCircle',
    ),
    NotificationItem(
      id: '4',
      type: 'user',
      title: 'Nouvel utilisateur',
      message: "Aïssatou Ba s'est inscrite dans le système.",
      time: 'Il y a 2 heures',
      read: true,
      iconName: 'User',
    ),
    NotificationItem(
      id: '5',
      type: 'late',
      title: 'Livre en retard',
      message: "Le livre 'Bases de données avancées' emprunté par Ibrahima Sarr est en retard de 7 jours.",
      time: 'Il y a 3 heures',
      read: false,
      iconName: 'AlertCircle',
    ),
    NotificationItem(
      id: '6',
      type: 'reservation',
      title: 'Nouvelle réservation',
      message: "Mariama Sy a réservé 'Deep Learning avec TensorFlow'.",
      time: 'Il y a 4 heures',
      read: true,
      iconName: 'Clock',
    ),
    NotificationItem(
      id: '7',
      type: 'return',
      title: 'Retour de livre',
      message: "Cheikh Fall a retourné 'Intelligence Artificielle'.",
      time: 'Hier',
      read: true,
      iconName: 'CheckCircle',
    ),
    NotificationItem(
      id: '8',
      type: 'loan',
      title: 'Nouvel emprunt',
      message: "Amadou Diallo a emprunté 'Systèmes Distribués'.",
      time: 'Hier',
      read: true,
      iconName: 'BookOpen',
    ),
  ];

  List<NotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((notification) => !notification.read).length;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((notification) => notification.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = NotificationItem(
        id: notification.id,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        time: notification.time,
        read: true,
        iconName: notification.iconName,
      );
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      final notification = _notifications[i];
      _notifications[i] = NotificationItem(
        id: notification.id,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        time: notification.time,
        read: true,
        iconName: notification.iconName,
      );
    }
  }

  void delete(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
  }

  void clearAll() {
    _notifications.clear();
  }
}