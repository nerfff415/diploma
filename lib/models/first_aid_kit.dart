import 'package:cloud_firestore/cloud_firestore.dart';

class FirstAidKit {
  final String id;
  final String name;
  final String userId;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  FirstAidKit({
    required this.id,
    required this.name,
    required this.userId,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  // Метод для создания копии объекта FirstAidKit с возможностью изменения полей
  FirstAidKit copyWith({
    String? id,
    String? name,
    String? userId,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirstAidKit(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Создание объекта из данных Firestore
  factory FirstAidKit.fromFirestore(Map<String, dynamic> data, String docId) {
    return FirstAidKit(
      id: docId,
      name: data['name'] ?? '',
      userId: data['userId'] ?? '',
      description: data['description'],
      createdAt:
          data['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
              : DateTime.now(),
    );
  }

  // Преобразование объекта в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userId': userId,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
