import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/family_group.dart';
import '../models/group_member.dart';
import '../models/group_kit.dart';
import '../models/access_code.dart';
import '../models/user_profile.dart';

class FamilyGroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Создание новой семейной группы
  Future<String> createFamilyGroup({
    required String name,
    required String adminId,
    String? description,
  }) async {
    try {
      // Создаем документ группы
      final groupRef = _firestore.collection('family_groups').doc();
      final group = FamilyGroup(
        id: groupRef.id,
        name: name,
        adminId: adminId,
        description: description,
        createdAt: DateTime.now(),
      );

      await groupRef.set(group.toMap());

      // Добавляем создателя как администратора группы
      final member = GroupMember.create(
        groupId: groupRef.id,
        userId: adminId,
        role: MemberRole.admin,
        status: MemberStatus.active,
      );

      await _firestore
          .collection('group_members')
          .doc(member.id)
          .set(member.toMap());

      return groupRef.id;
    } catch (e) {
      print('Ошибка при создании семейной группы: $e');
      rethrow;
    }
  }

  // Получение группы по ID
  Future<FamilyGroup?> getFamilyGroup(String groupId) async {
    try {
      final doc =
          await _firestore.collection('family_groups').doc(groupId).get();
      if (doc.exists && doc.data() != null) {
        return FamilyGroup.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Ошибка при получении семейной группы: $e');
      rethrow;
    }
  }

  // Обновление информации о группе
  Future<void> updateFamilyGroup(FamilyGroup group) async {
    try {
      await _firestore
          .collection('family_groups')
          .doc(group.id)
          .update(group.toMap());
    } catch (e) {
      print('Ошибка при обновлении семейной группы: $e');
      rethrow;
    }
  }

  // Удаление группы
  Future<void> deleteFamilyGroup(String groupId) async {
    try {
      // Удаляем группу
      await _firestore.collection('family_groups').doc(groupId).delete();

      // Удаляем всех участников группы
      final memberDocs =
          await _firestore
              .collection('group_members')
              .where('groupId', isEqualTo: groupId)
              .get();

      for (var doc in memberDocs.docs) {
        await doc.reference.delete();
      }

      // Удаляем все связи с аптечками
      final kitDocs =
          await _firestore
              .collection('group_kits')
              .where('groupId', isEqualTo: groupId)
              .get();

      for (var doc in kitDocs.docs) {
        await doc.reference.delete();
      }

      // Деактивируем все коды доступа
      final codeDocs =
          await _firestore
              .collection('access_codes')
              .where('groupId', isEqualTo: groupId)
              .get();

      for (var doc in codeDocs.docs) {
        await doc.reference.update({'isActive': false});
      }
    } catch (e) {
      print('Ошибка при удалении семейной группы: $e');
      rethrow;
    }
  }

  // Получение всех групп пользователя
  Stream<List<FamilyGroup>> getUserGroups(String userId) {
    try {
      // Получаем ID групп, в которых пользователь является участником
      return _firestore
          .collection('group_members')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .asyncMap((memberSnapshot) async {
            final groupIds =
                memberSnapshot.docs
                    .map((doc) => doc.data()['groupId'] as String)
                    .toList();

            if (groupIds.isEmpty) {
              return <FamilyGroup>[];
            }

            // Получаем информацию о группах
            final groupDocs =
                await _firestore
                    .collection('family_groups')
                    .where(FieldPath.documentId, whereIn: groupIds)
                    .get();

            return groupDocs.docs
                .map((doc) => FamilyGroup.fromMap(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      print('Ошибка при получении групп пользователя: $e');
      rethrow;
    }
  }

  // Добавление аптечки в группу
  Future<void> addKitToGroup(String groupId, String kitId) async {
    try {
      final groupKit = GroupKit.create(groupId: groupId, kitId: kitId);

      await _firestore
          .collection('group_kits')
          .doc(groupKit.id)
          .set(groupKit.toMap());
    } catch (e) {
      print('Ошибка при добавлении аптечки в группу: $e');
      rethrow;
    }
  }

  // Удаление аптечки из группы
  Future<void> removeKitFromGroup(String groupId, String kitId) async {
    try {
      final id = '${groupId}_$kitId';
      await _firestore.collection('group_kits').doc(id).delete();
    } catch (e) {
      print('Ошибка при удалении аптечки из группы: $e');
      rethrow;
    }
  }

  // Получение всех аптечек группы
  Future<List<String>> getGroupKits(String groupId) async {
    try {
      final docs =
          await _firestore
              .collection('group_kits')
              .where('groupId', isEqualTo: groupId)
              .get();

      return docs.docs.map((doc) => doc.data()['kitId'] as String).toList();
    } catch (e) {
      print('Ошибка при получении аптечек группы: $e');
      rethrow;
    }
  }

  // Добавление участника в группу
  Future<void> addMemberToGroup({
    required String groupId,
    required String userId,
    MemberRole role = MemberRole.viewer,
    MemberStatus status = MemberStatus.pending,
  }) async {
    try {
      final member = GroupMember.create(
        groupId: groupId,
        userId: userId,
        role: role,
        status: status,
      );

      await _firestore
          .collection('group_members')
          .doc(member.id)
          .set(member.toMap());
    } catch (e) {
      print('Ошибка при добавлении участника в группу: $e');
      rethrow;
    }
  }

  // Обновление роли участника
  Future<void> updateMemberRole(
    String groupId,
    String userId,
    MemberRole role,
  ) async {
    try {
      final id = '${groupId}_$userId';
      await _firestore.collection('group_members').doc(id).update({
        'role': role.toString().split('.').last,
      });
    } catch (e) {
      print('Ошибка при обновлении роли участника: $e');
      rethrow;
    }
  }

  // Обновление статуса участника
  Future<void> updateMemberStatus(
    String groupId,
    String userId,
    MemberStatus status,
  ) async {
    try {
      final id = '${groupId}_$userId';
      await _firestore.collection('group_members').doc(id).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      print('Ошибка при обновлении статуса участника: $e');
      rethrow;
    }
  }

  // Удаление участника из группы
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      final id = '${groupId}_$userId';
      await _firestore.collection('group_members').doc(id).delete();
    } catch (e) {
      print('Ошибка при удалении участника из группы: $e');
      rethrow;
    }
  }

  // Получение всех участников группы
  Stream<List<GroupMember>> getGroupMembers(String groupId) {
    try {
      return _firestore
          .collection('group_members')
          .where('groupId', isEqualTo: groupId)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => GroupMember.fromMap(doc.data(), doc.id))
                    .toList(),
          );
    } catch (e) {
      print('Ошибка при получении участников группы: $e');
      rethrow;
    }
  }

  // Генерация уникального кода доступа
  String generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final segments = List.generate(
      3,
      (_) =>
          List.generate(4, (_) => chars[random.nextInt(chars.length)]).join(),
    );
    return 'FAM-${segments.join("-")}';
  }

  // Создание кода доступа для группы
  Future<String> createGroupAccessCode(String groupId, String createdBy) async {
    try {
      final code = generateAccessCode();
      final accessCode = AccessCode.createForGroup(
        code: code,
        groupId: groupId,
        createdBy: createdBy,
      );

      await _firestore
          .collection('access_codes')
          .doc(code)
          .set(accessCode.toMap());

      return code;
    } catch (e) {
      print('Ошибка при создании кода доступа для группы: $e');
      rethrow;
    }
  }

  // Создание кода доступа для аптечки
  Future<String> createKitAccessCode(String kitId, String createdBy) async {
    try {
      final code = generateAccessCode();
      final accessCode = AccessCode.createForKit(
        code: code,
        kitId: kitId,
        createdBy: createdBy,
      );

      await _firestore
          .collection('access_codes')
          .doc(code)
          .set(accessCode.toMap());

      return code;
    } catch (e) {
      print('Ошибка при создании кода доступа для аптечки: $e');
      rethrow;
    }
  }

  // Проверка кода доступа
  Future<AccessCode?> validateAccessCode(String code) async {
    try {
      final doc = await _firestore.collection('access_codes').doc(code).get();
      if (doc.exists && doc.data() != null) {
        final accessCode = AccessCode.fromMap(doc.data()!, code);

        if (accessCode.isValid) {
          return accessCode;
        }
      }
      return null;
    } catch (e) {
      print('Ошибка при проверке кода доступа: $e');
      rethrow;
    }
  }

  // Присоединение к группе по коду доступа
  Future<bool> joinGroupByCode(String code, String userId) async {
    try {
      final accessCode = await validateAccessCode(code);

      if (accessCode != null &&
          accessCode.type == AccessCodeType.group &&
          accessCode.groupId != null) {
        // Добавляем пользователя в группу
        await addMemberToGroup(
          groupId: accessCode.groupId!,
          userId: userId,
          status:
              MemberStatus.pending, // Ожидание подтверждения администратором
        );

        return true;
      }

      return false;
    } catch (e) {
      print('Ошибка при присоединении к группе по коду: $e');
      return false;
    }
  }

  // Получение информации о пользователях группы
  Future<List<UserProfile>> getGroupMembersProfiles(String groupId) async {
    try {
      final memberDocs =
          await _firestore
              .collection('group_members')
              .where('groupId', isEqualTo: groupId)
              .get();

      final userIds =
          memberDocs.docs.map((doc) => doc.data()['userId'] as String).toList();

      if (userIds.isEmpty) {
        return [];
      }

      // Получаем профили пользователей
      final userDocs =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: userIds)
              .get();

      return userDocs.docs.map((doc) {
        final data = doc.data();

        // Функция для безопасного преобразования даты
        DateTime? parseDate(dynamic value) {
          if (value == null) return null;
          if (value is Timestamp) return value.toDate();
          if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
          return null;
        }

        return UserProfile(
          userId: doc.id,
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          middleName: data['middleName'],
          phoneNumber: data['phoneNumber'],
          birthDate: parseDate(data['birthDate']),
          email: data['email'] ?? '',
          createdAt: parseDate(data['createdAt']),
          updatedAt: parseDate(data['updatedAt']),
        );
      }).toList();
    } catch (e) {
      print('Ошибка при получении профилей участников группы: $e');
      rethrow;
    }
  }

  // Проверка, является ли пользователь участником группы
  Future<bool> isUserGroupMember(String userId, String groupId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('group_members')
              .where('userId', isEqualTo: userId)
              .where('groupId', isEqualTo: groupId)
              .where('status', isEqualTo: 'active')
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Ошибка при проверке участия пользователя в группе: $e');
      return false;
    }
  }

  // Проверка, принадлежит ли аптечка группе
  Future<bool> isKitInGroup(String kitId, String groupId) async {
    try {
      final id = '${groupId}_$kitId';
      final docSnapshot =
          await _firestore.collection('group_kits').doc(id).get();

      return docSnapshot.exists;
    } catch (e) {
      print('Ошибка при проверке принадлежности аптечки группе: $e');
      return false;
    }
  }

  // Получение списка групп, к которым принадлежит аптечка
  Future<List<String>> getGroupsForKit(String kitId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('group_kits')
              .where('kitId', isEqualTo: kitId)
              .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['groupId'] as String)
          .toList();
    } catch (e) {
      print('Ошибка при получении групп для аптечки: $e');
      return [];
    }
  }

  // Получение всех групп, в которых есть аптечка
  Future<List<String>> getGroupsWithKit(String kitId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('group_kits')
              .where('kitId', isEqualTo: kitId)
              .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['groupId'] as String)
          .toList();
    } catch (e) {
      print('Ошибка при получении групп с аптечкой: $e');
      return [];
    }
  }

  // Проверка, имеет ли пользователь доступ к аптечке через группу
  Future<bool> hasUserAccessToKit(String userId, String kitId) async {
    try {
      // Получаем все группы, в которых есть аптечка
      final groupIds = await getGroupsWithKit(kitId);

      // Если аптечка не принадлежит ни одной группе, то доступа нет
      if (groupIds.isEmpty) {
        return false;
      }

      // Проверяем, является ли пользователь участником хотя бы одной из этих групп
      for (final groupId in groupIds) {
        final isMember = await isUserGroupMember(userId, groupId);
        if (isMember) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Ошибка при проверке доступа пользователя к аптечке: $e');
      return false;
    }
  }
}
