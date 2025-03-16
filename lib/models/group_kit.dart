import 'package:cloud_firestore/cloud_firestore.dart';

class GroupKit {
  final String id; // Формат: {group_id}_{kit_id}
  final String groupId;
  final String kitId;
  final DateTime addedAt;

  GroupKit({
    required this.id,
    required this.groupId,
    required this.kitId,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'kitId': kitId,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory GroupKit.fromMap(Map<String, dynamic> map, String docId) {
    return GroupKit(
      id: docId,
      groupId: map['groupId'] ?? '',
      kitId: map['kitId'] ?? '',
      addedAt:
          map['addedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['addedAt'])
              : DateTime.now(),
    );
  }

  // Создание новой связи группы и аптечки
  static GroupKit create({required String groupId, required String kitId}) {
    final id = '${groupId}_$kitId';
    return GroupKit(
      id: id,
      groupId: groupId,
      kitId: kitId,
      addedAt: DateTime.now(),
    );
  }
}
