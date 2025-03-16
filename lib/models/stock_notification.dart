import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель уведомления о низком уровне запасов медикамента
class StockNotification {
  final String id;
  final String medicationId;
  final String medicationName;
  final String kitId;
  final String kitName;
  final double currentQuantity;
  final String dimension;
  final DateTime createdAt;
  final bool isRead;
  final List<String>
  notifiedUserIds; // Список пользователей, которым отправлено уведомление

  StockNotification({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.kitId,
    required this.kitName,
    required this.currentQuantity,
    required this.dimension,
    required this.createdAt,
    required this.isRead,
    required this.notifiedUserIds,
  });

  // Создание копии с возможностью изменения полей
  StockNotification copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    String? kitId,
    String? kitName,
    double? currentQuantity,
    String? dimension,
    DateTime? createdAt,
    bool? isRead,
    List<String>? notifiedUserIds,
  }) {
    return StockNotification(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      kitId: kitId ?? this.kitId,
      kitName: kitName ?? this.kitName,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      dimension: dimension ?? this.dimension,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      notifiedUserIds: notifiedUserIds ?? this.notifiedUserIds,
    );
  }

  // Создание из данных Firestore
  factory StockNotification.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return StockNotification(
      id: docId,
      medicationId: data['medicationId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      kitId: data['kitId'] ?? '',
      kitName: data['kitName'] ?? '',
      currentQuantity: (data['currentQuantity'] ?? 0).toDouble(),
      dimension: data['dimension'] ?? '',
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['createdAt']))
              : DateTime.now(),
      isRead: data['isRead'] ?? false,
      notifiedUserIds: List<String>.from(data['notifiedUserIds'] ?? []),
    );
  }

  // Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'medicationId': medicationId,
      'medicationName': medicationName,
      'kitId': kitId,
      'kitName': kitName,
      'currentQuantity': currentQuantity,
      'dimension': dimension,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'notifiedUserIds': notifiedUserIds,
    };
  }

  // Создание нового уведомления
  static StockNotification create({
    required String medicationId,
    required String medicationName,
    required String kitId,
    required String kitName,
    required double currentQuantity,
    required String dimension,
    required List<String> notifiedUserIds,
  }) {
    return StockNotification(
      id: '', // ID будет присвоен Firestore
      medicationId: medicationId,
      medicationName: medicationName,
      kitId: kitId,
      kitName: kitName,
      currentQuantity: currentQuantity,
      dimension: dimension,
      createdAt: DateTime.now(),
      isRead: false,
      notifiedUserIds: notifiedUserIds,
    );
  }
}
