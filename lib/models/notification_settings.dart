import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettings {
  final String id;
  final String userId;
  final bool enabled;
  final bool medicationReminders;
  final bool expiryReminders;
  final int reminderTime; // Время напоминания в минутах до приема
  final int expiryReminderDays; // За сколько дней напоминать о сроке годности
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationSettings({
    required this.id,
    required this.userId,
    required this.enabled,
    required this.medicationReminders,
    required this.expiryReminders,
    required this.reminderTime,
    required this.expiryReminderDays,
    required this.createdAt,
    required this.updatedAt,
  });

  // Создание копии с возможностью изменения полей
  NotificationSettings copyWith({
    String? id,
    String? userId,
    bool? enabled,
    bool? medicationReminders,
    bool? expiryReminders,
    int? reminderTime,
    int? expiryReminderDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      enabled: enabled ?? this.enabled,
      medicationReminders: medicationReminders ?? this.medicationReminders,
      expiryReminders: expiryReminders ?? this.expiryReminders,
      reminderTime: reminderTime ?? this.reminderTime,
      expiryReminderDays: expiryReminderDays ?? this.expiryReminderDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Создание из данных Firestore
  factory NotificationSettings.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return NotificationSettings(
      id: docId,
      userId: data['userId'] ?? '',
      enabled: data['enabled'] ?? true,
      medicationReminders: data['medicationReminders'] ?? true,
      expiryReminders: data['expiryReminders'] ?? true,
      reminderTime: data['reminderTime'] ?? 30,
      expiryReminderDays: data['expiryReminderDays'] ?? 7,
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['createdAt']))
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] is Timestamp
                  ? (data['updatedAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['updatedAt']))
              : DateTime.now(),
    );
  }

  // Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'enabled': enabled,
      'medicationReminders': medicationReminders,
      'expiryReminders': expiryReminders,
      'reminderTime': reminderTime,
      'expiryReminderDays': expiryReminderDays,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Создание настроек по умолчанию
  static NotificationSettings createDefault(String userId) {
    final now = DateTime.now();
    return NotificationSettings(
      id: '',
      userId: userId,
      enabled: true,
      medicationReminders: true,
      expiryReminders: true,
      reminderTime: 30,
      expiryReminderDays: 7,
      createdAt: now,
      updatedAt: now,
    );
  }
}
