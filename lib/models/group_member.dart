import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberRole { admin, editor, viewer }

enum MemberStatus { active, pending, removed }

class GroupMember {
  final String id; // Формат: {group_id}_{user_id}
  final String groupId;
  final String userId;
  final MemberRole role;
  final MemberStatus status;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'userId': userId,
      'role': role.toString().split('.').last,
      'status': status.toString().split('.').last,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map, String docId) {
    return GroupMember(
      id: docId,
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      role: _roleFromString(map['role'] ?? 'viewer'),
      status: _statusFromString(map['status'] ?? 'pending'),
      joinedAt:
          map['joinedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['joinedAt'])
              : DateTime.now(),
    );
  }

  static MemberRole _roleFromString(String roleStr) {
    switch (roleStr) {
      case 'admin':
        return MemberRole.admin;
      case 'editor':
        return MemberRole.editor;
      case 'viewer':
      default:
        return MemberRole.viewer;
    }
  }

  static MemberStatus _statusFromString(String statusStr) {
    switch (statusStr) {
      case 'active':
        return MemberStatus.active;
      case 'removed':
        return MemberStatus.removed;
      case 'pending':
      default:
        return MemberStatus.pending;
    }
  }

  // Создание нового участника группы
  static GroupMember create({
    required String groupId,
    required String userId,
    MemberRole role = MemberRole.viewer,
    MemberStatus status = MemberStatus.pending,
  }) {
    final id = '${groupId}_$userId';
    return GroupMember(
      id: id,
      groupId: groupId,
      userId: userId,
      role: role,
      status: status,
      joinedAt: DateTime.now(),
    );
  }

  // Обновление роли участника
  GroupMember updateRole(MemberRole newRole) {
    return GroupMember(
      id: this.id,
      groupId: this.groupId,
      userId: this.userId,
      role: newRole,
      status: this.status,
      joinedAt: this.joinedAt,
    );
  }

  // Обновление статуса участника
  GroupMember updateStatus(MemberStatus newStatus) {
    return GroupMember(
      id: this.id,
      groupId: this.groupId,
      userId: this.userId,
      role: this.role,
      status: newStatus,
      joinedAt: this.joinedAt,
    );
  }
}
