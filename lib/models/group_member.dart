import 'package:cloud_firestore/cloud_firestore.dart';

// Original role and status enums
enum MemberRole { admin, editor, viewer }

enum MemberStatus { active, pending, removed }

// Original GroupMember class
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

// Redefining member permission levels with different names
enum TeamMemberAccess { 
  supervisor,  // Previously admin
  contributor, // Previously editor
  observer     // Previously viewer
}

// Redefining member participation states
enum ParticipationStatus { 
  confirmed,  // Previously active
  awaiting,   // Previously pending
  revoked     // Previously removed
}

class TeamParticipant {
  // Unique identifier for the participant record
  final String identifier; // Previously id
  
  // References to related entities
  final String teamId;     // Previously groupId
  final String personId;   // Previously userId
  
  // Permission and state information
  final TeamMemberAccess accessLevel;
  final ParticipationStatus memberStatus;
  
  // Tracking information
  final DateTime enrollmentDate; // Previously joinedAt

  TeamParticipant({
    required this.identifier,
    required this.teamId,
    required this.personId,
    required this.accessLevel,
    required this.memberStatus,
    required this.enrollmentDate,
  });

  // Convert to database format
  Map<String, dynamic> toDataMap() {
    return {
      'teamId': teamId,
      'personId': personId,
      'accessLevel': accessLevel.toString().split('.').last,
      'memberStatus': memberStatus.toString().split('.').last,
      'enrollmentDate': enrollmentDate.millisecondsSinceEpoch,
    };
  }

  // Create from database data
  factory TeamParticipant.fromDataMap(Map<String, dynamic> data, String recordId) {
    return TeamParticipant(
      identifier: recordId,
      teamId: data['teamId'] ?? '',
      personId: data['personId'] ?? '',
      accessLevel: _parseAccessLevel(data['accessLevel'] ?? 'observer'),
      memberStatus: _parseParticipationStatus(data['memberStatus'] ?? 'awaiting'),
      enrollmentDate:
          data['enrollmentDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['enrollmentDate'])
              : DateTime.now(),
    );
  }

  // Helper method to parse access level string
  static TeamMemberAccess _parseAccessLevel(String levelString) {
    switch (levelString) {
      case 'supervisor':
        return TeamMemberAccess.supervisor;
      case 'contributor':
        return TeamMemberAccess.contributor;
      case 'observer':
      default:
        return TeamMemberAccess.observer;
    }
  }

  // Helper method to parse participation status string
  static ParticipationStatus _parseParticipationStatus(String statusString) {
    switch (statusString) {
      case 'confirmed':
        return ParticipationStatus.confirmed;
      case 'revoked':
        return ParticipationStatus.revoked;
      case 'awaiting':
      default:
        return ParticipationStatus.awaiting;
    }
  }

  // Factory method to create a new team participant
  static TeamParticipant createNew({
    required String teamId,
    required String personId,
    TeamMemberAccess accessLevel = TeamMemberAccess.observer,
    ParticipationStatus memberStatus = ParticipationStatus.awaiting,
  }) {
    final compositeId = '${teamId}_${personId}';
    return TeamParticipant(
      identifier: compositeId,
      teamId: teamId,
      personId: personId,
      accessLevel: accessLevel,
      memberStatus: memberStatus,
      enrollmentDate: DateTime.now(),
    );
  }

  // Create a copy with updated access level
  TeamParticipant withUpdatedAccessLevel(TeamMemberAccess newAccessLevel) {
    return TeamParticipant(
      identifier: this.identifier,
      teamId: this.teamId,
      personId: this.personId,
      accessLevel: newAccessLevel,
      memberStatus: this.memberStatus,
      enrollmentDate: this.enrollmentDate,
    );
  }

  // Create a copy with updated participation status
  TeamParticipant withUpdatedStatus(ParticipationStatus newStatus) {
    return TeamParticipant(
      identifier: this.identifier,
      teamId: this.teamId,
      personId: this.personId,
      accessLevel: this.accessLevel,
      memberStatus: newStatus,
      enrollmentDate: this.enrollmentDate,
    );
  }
}
