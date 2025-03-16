import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель уведомления о приеме лекарства
class MedicationReminder {
  final String id;
  final String userId;
  final String scheduleId; // ID записи в расписании
  final String medicationId;
  final String medicationName;
  final String kitId;
  final String kitName;
  final DateTime scheduledTime; // Запланированное время приема
  final double dosage;
  final String dimension;
  final bool isRead; // Прочитано ли уведомление
  final DateTime createdAt;
  final DateTime? readAt; // Когда уведомление было прочитано

  MedicationReminder({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.medicationId,
    required this.medicationName,
    required this.kitId,
    required this.kitName,
    required this.scheduledTime,
    required this.dosage,
    required this.dimension,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  // Создание копии с возможностью изменения полей
  MedicationReminder copyWith({
    String? id,
    String? userId,
    String? scheduleId,
    String? medicationId,
    String? medicationName,
    String? kitId,
    String? kitName,
    DateTime? scheduledTime,
    double? dosage,
    String? dimension,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduleId: scheduleId ?? this.scheduleId,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      kitId: kitId ?? this.kitId,
      kitName: kitName ?? this.kitName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      dosage: dosage ?? this.dosage,
      dimension: dimension ?? this.dimension,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Создание из данных Firestore
  factory MedicationReminder.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return MedicationReminder(
      id: docId,
      userId: data['userId'] ?? '',
      scheduleId: data['scheduleId'] ?? '',
      medicationId: data['medicationId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      kitId: data['kitId'] ?? '',
      kitName: data['kitName'] ?? '',
      scheduledTime:
          data['scheduledTime'] != null
              ? (data['scheduledTime'] is Timestamp
                  ? (data['scheduledTime'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['scheduledTime']))
              : DateTime.now(),
      dosage: (data['dosage'] ?? 0).toDouble(),
      dimension: data['dimension'] ?? '',
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
      'scheduleId': scheduleId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'kitId': kitId,
      'kitName': kitName,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'dosage': dosage,
      'dimension': dimension,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
    };
  }

  // Создание нового уведомления о приеме лекарства
  static MedicationReminder create({
    required String userId,
    required String scheduleId,
    required String medicationId,
    required String medicationName,
    required String kitId,
    required String kitName,
    required DateTime scheduledTime,
    required double dosage,
    required String dimension,
  }) {
    final now = DateTime.now();
    return MedicationReminder(
      id: '', // ID будет присвоен Firestore
      userId: userId,
      scheduleId: scheduleId,
      medicationId: medicationId,
      medicationName: medicationName,
      kitId: kitId,
      kitName: kitName,
      scheduledTime: scheduledTime,
      dosage: dosage,
      dimension: dimension,
      isRead: false,
      createdAt: now,
      readAt: null,
    );
  }
}
