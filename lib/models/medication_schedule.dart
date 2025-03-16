import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MedicationSchedule {
  final String id;
  final String userId; // ID пользователя, создавшего запись
  final String medicationId; // ID медикамента
  final String medicationName; // Название медикамента (для быстрого доступа)
  final String kitId; // ID аптечки, из которой взят медикамент
  final String kitName; // Название аптечки (для быстрого доступа)
  final DateTime date; // Дата приема
  final TimeOfDay time; // Время приема
  final double dosage; // Дозировка
  final String dimension; // Единица измерения (таблетки, мл и т.д.)
  final bool taken; // Принято ли лекарство
  final DateTime? takenAt; // Когда было принято лекарство
  final String? notes; // Дополнительные заметки
  final bool notificationEnabled; // Включены ли уведомления для этого приема
  final int notificationMinutesBefore; // За сколько минут до приема уведомлять
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationSchedule({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.medicationName,
    required this.kitId,
    required this.kitName,
    required this.date,
    required this.time,
    required this.dosage,
    required this.dimension,
    required this.taken,
    this.takenAt,
    this.notes,
    required this.notificationEnabled,
    required this.notificationMinutesBefore,
    required this.createdAt,
    required this.updatedAt,
  });

  // Создание копии с возможностью изменения полей
  MedicationSchedule copyWith({
    String? id,
    String? userId,
    String? medicationId,
    String? medicationName,
    String? kitId,
    String? kitName,
    DateTime? date,
    TimeOfDay? time,
    double? dosage,
    String? dimension,
    bool? taken,
    DateTime? takenAt,
    String? notes,
    bool? notificationEnabled,
    int? notificationMinutesBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      kitId: kitId ?? this.kitId,
      kitName: kitName ?? this.kitName,
      date: date ?? this.date,
      time: time ?? this.time,
      dosage: dosage ?? this.dosage,
      dimension: dimension ?? this.dimension,
      taken: taken ?? this.taken,
      takenAt: takenAt ?? this.takenAt,
      notes: notes ?? this.notes,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationMinutesBefore:
          notificationMinutesBefore ?? this.notificationMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Создание из данных Firestore
  factory MedicationSchedule.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    // Преобразование времени из строки в TimeOfDay
    TimeOfDay timeFromString(String timeString) {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return MedicationSchedule(
      id: docId,
      userId: data['userId'] ?? '',
      medicationId: data['medicationId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      kitId: data['kitId'] ?? '',
      kitName: data['kitName'] ?? '',
      date:
          data['date'] != null
              ? (data['date'] is Timestamp
                  ? (data['date'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['date']))
              : DateTime.now(),
      time:
          data['time'] != null ? timeFromString(data['time']) : TimeOfDay.now(),
      dosage: (data['dosage'] ?? 0).toDouble(),
      dimension: data['dimension'] ?? '',
      taken: data['taken'] ?? false,
      takenAt:
          data['takenAt'] != null
              ? (data['takenAt'] is Timestamp
                  ? (data['takenAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['takenAt']))
              : null,
      notes: data['notes'],
      notificationEnabled: data['notificationEnabled'] ?? true,
      notificationMinutesBefore: data['notificationMinutesBefore'] ?? 30,
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
    // Преобразование TimeOfDay в строку для хранения
    String timeToString(TimeOfDay time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return {
      'userId': userId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'kitId': kitId,
      'kitName': kitName,
      'date': date.millisecondsSinceEpoch,
      'time': timeToString(time),
      'dosage': dosage,
      'dimension': dimension,
      'taken': taken,
      'takenAt': takenAt?.millisecondsSinceEpoch,
      'notes': notes,
      'notificationEnabled': notificationEnabled,
      'notificationMinutesBefore': notificationMinutesBefore,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Создание нового расписания приема
  static MedicationSchedule create({
    required String userId,
    required String medicationId,
    required String medicationName,
    required String kitId,
    required String kitName,
    required DateTime date,
    required TimeOfDay time,
    required double dosage,
    required String dimension,
    String? notes,
    bool notificationEnabled = true,
    int notificationMinutesBefore = 30,
  }) {
    final now = DateTime.now();
    return MedicationSchedule(
      id: '', // ID будет присвоен Firestore
      userId: userId,
      medicationId: medicationId,
      medicationName: medicationName,
      kitId: kitId,
      kitName: kitName,
      date: date,
      time: time,
      dosage: dosage,
      dimension: dimension,
      taken: false,
      takenAt: null,
      notes: notes,
      notificationEnabled: notificationEnabled,
      notificationMinutesBefore: notificationMinutesBefore,
      createdAt: now,
      updatedAt: now,
    );
  }
}
