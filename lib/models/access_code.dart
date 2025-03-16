import 'package:cloud_firestore/cloud_firestore.dart';

enum AccessCodeType { kit, group }

class AccessCode {
  final String code;
  final String? kitId;
  final String? groupId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final AccessCodeType type;

  AccessCode({
    required this.code,
    this.kitId,
    this.groupId,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'kitId': kitId,
      'groupId': groupId,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'type': type.toString().split('.').last,
    };
  }

  factory AccessCode.fromMap(Map<String, dynamic> map, String code) {
    return AccessCode(
      code: code,
      kitId: map['kitId'],
      groupId: map['groupId'],
      createdBy: map['createdBy'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : DateTime.now(),
      expiresAt:
          map['expiresAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'])
              : DateTime.now().add(const Duration(days: 7)),
      isActive: map['isActive'] ?? true,
      type: _typeFromString(map['type'] ?? 'kit'),
    );
  }

  static AccessCodeType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'group':
        return AccessCodeType.group;
      case 'kit':
      default:
        return AccessCodeType.kit;
    }
  }

  // Создание кода доступа для аптечки
  static AccessCode createForKit({
    required String code,
    required String kitId,
    required String createdBy,
    DateTime? expiresAt,
  }) {
    return AccessCode(
      code: code,
      kitId: kitId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 7)),
      isActive: true,
      type: AccessCodeType.kit,
    );
  }

  // Создание кода доступа для группы
  static AccessCode createForGroup({
    required String code,
    required String groupId,
    required String createdBy,
    DateTime? expiresAt,
  }) {
    return AccessCode(
      code: code,
      groupId: groupId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 7)),
      isActive: true,
      type: AccessCodeType.group,
    );
  }

  // Деактивация кода доступа
  AccessCode deactivate() {
    return AccessCode(
      code: this.code,
      kitId: this.kitId,
      groupId: this.groupId,
      createdBy: this.createdBy,
      createdAt: this.createdAt,
      expiresAt: this.expiresAt,
      isActive: false,
      type: this.type,
    );
  }

  // Проверка, истек ли срок действия кода
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Проверка, действителен ли код
  bool get isValid => isActive && !isExpired;
}
