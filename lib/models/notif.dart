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

  final List<NotificationItem> _notifications = [];

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