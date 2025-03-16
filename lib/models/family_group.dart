import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroup {
  final String id;
  final String name;
  final String adminId;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FamilyGroup({
    required this.id,
    required this.name,
    required this.adminId,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminId': adminId,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt':
          updatedAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory FamilyGroup.fromMap(Map<String, dynamic> map, String docId) {
    return FamilyGroup(
      id: docId,
      name: map['name'] ?? '',
      adminId: map['adminId'] ?? '',
      description: map['description'],
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : null,
    );
  }

  FamilyGroup copyWith({String? name, String? description}) {
    return FamilyGroup(
      id: this.id,
      name: name ?? this.name,
      adminId: this.adminId,
      description: description ?? this.description,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
