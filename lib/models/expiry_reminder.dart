import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель уведомления о скором истечении срока годности лекарства
class ExpiryReminder {
  final String id;
  final String userId;
  final String medicationId;
  final String medicationName;
  final String kitId;
  final String kitName;
  final DateTime expiryDate; // Дата истечения срока годности
  final int daysRemaining; // Сколько дней осталось до истечения срока
  final bool isRead; // Прочитано ли уведомление
  final DateTime createdAt;
  final DateTime? readAt; // Когда уведомление было прочитано

  ExpiryReminder({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.medicationName,
    required this.kitId,
    required this.kitName,
    required this.expiryDate,
    required this.daysRemaining,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  // Создание копии с возможностью изменения полей
  ExpiryReminder copyWith({
    String? id,
    String? userId,
    String? medicationId,
    String? medicationName,
    String? kitId,
    String? kitName,
    DateTime? expiryDate,
    int? daysRemaining,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return ExpiryReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      kitId: kitId ?? this.kitId,
      kitName: kitName ?? this.kitName,
      expiryDate: expiryDate ?? this.expiryDate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Создание из данных Firestore
  factory ExpiryReminder.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return ExpiryReminder(
      id: docId,
      userId: data['userId'] ?? '',
      medicationId: data['medicationId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      kitId: data['kitId'] ?? '',
      kitName: data['kitName'] ?? '',
      expiryDate:
          data['expiryDate'] != null
              ? (data['expiryDate'] is Timestamp
                  ? (data['expiryDate'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['expiryDate']))
              : DateTime.now(),
      daysRemaining: data['daysRemaining'] ?? 0,
      isRead: data['isRead'] ?? false,
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['createdAt']))
              : DateTime.now(),
      readAt:
          data['readAt'] != null
              ? (data['readAt'] is Timestamp
                  ? (data['readAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['readAt']))
              : null,
    );
  }

  // Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'kitId': kitId,
      'kitName': kitName,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'daysRemaining': daysRemaining,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
    };
  }

  // Создание нового уведомления о сроке годности
  static ExpiryReminder create({
    required String userId,
    required String medicationId,
    required String medicationName,
    required String kitId,
    required String kitName,
    required DateTime expiryDate,
  }) {
    final now = DateTime.now();
    final daysRemaining = expiryDate.difference(now).inDays;

    return ExpiryReminder(
      id: '', // ID будет присвоен Firestore
      userId: userId,
      medicationId: medicationId,
      medicationName: medicationName,
      kitId: kitId,
      kitName: kitName,
      expiryDate: expiryDate,
      daysRemaining: daysRemaining,
      isRead: false,
      createdAt: now,
      readAt: null,
    );
  }
}
