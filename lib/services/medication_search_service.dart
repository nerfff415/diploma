import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/first_aid_kit.dart';
import '../models/family_group.dart';
import '../models/group_kit.dart';
import 'first_aid_kit_service.dart';
import 'family_group_service.dart';

class MedicationSearchResult {
  final Medication medication;
  final String kitName;
  final String? groupName; // Null, если аптечка не принадлежит группе

  MedicationSearchResult({
    required this.medication,
    required this.kitName,
    this.groupName,
  });
}

class MedicationSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirstAidKitService _kitService = FirstAidKitService();
  final FamilyGroupService _groupService = FamilyGroupService();

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Нечеткий поиск медикаментов по названию
  Future<List<MedicationSearchResult>> searchMedications(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        return [];
      }

      // Получаем все аптечки пользователя
      final userKitsSnapshot =
          await _firestore
              .collection('first_aid_kits')
              .where('userId', isEqualTo: userId)
              .get();

      final userKitIds = userKitsSnapshot.docs.map((doc) => doc.id).toList();

      // Получаем группы пользователя
      final groupMembersSnapshot =
          await _firestore
              .collection('group_members')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .get();

      final groupIds =
          groupMembersSnapshot.docs
              .map((doc) => doc.data()['groupId'] as String)
              .toList();

      // Получаем аптечки из групп
      final List<String> groupKitIds = [];
      for (final groupId in groupIds) {
        final groupKitsSnapshot =
            await _firestore
                .collection('group_kits')
                .where('groupId', isEqualTo: groupId)
                .get();

        groupKitIds.addAll(
          groupKitsSnapshot.docs
              .map((doc) => doc.data()['kitId'] as String)
              .toList(),
        );
      }

      // Объединяем все ID аптечек
      final allKitIds = [...userKitIds, ...groupKitIds].toSet().toList();

      if (allKitIds.isEmpty) {
        return [];
      }

      // Получаем все медикаменты из аптечек пользователя
      final List<Medication> allMedications = [];

      // Firestore не поддерживает запросы с большим количеством элементов в whereIn,
      // поэтому разбиваем запрос на части по 10 элементов
      for (var i = 0; i < allKitIds.length; i += 10) {
        final end = (i + 10 < allKitIds.length) ? i + 10 : allKitIds.length;
        final batch = allKitIds.sublist(i, end);

        final medicationsSnapshot =
            await _firestore
                .collection('medications')
                .where('kitId', whereIn: batch)
                .get();

        final medications =
            medicationsSnapshot.docs
                .map(
                  (doc) => Medication.fromFirestore(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();

        allMedications.addAll(medications);
      }

      // Фильтруем медикаменты по запросу (нечеткий поиск)
      final queryLower = query.toLowerCase();
      final filteredMedications =
          allMedications
              .where(
                (medication) =>
                    medication.name.toLowerCase().contains(queryLower) ||
                    _calculateLevenshteinDistance(
                          medication.name.toLowerCase(),
                          queryLower,
                        ) <=
                        3,
              ) // Допускаем до 3 ошибок
              .toList();

      // Получаем информацию об аптечках
      final kitIds =
          filteredMedications
              .map((medication) => medication.kitId)
              .toSet()
              .toList();

      final kits = await _kitService.getFirstAidKitsByIds(kitIds);

      // Создаем карту аптечек для быстрого доступа
      final kitMap = {for (var kit in kits) kit.id: kit};

      // Получаем информацию о группах и аптечках в группах
      final groupKitsSnapshot =
          await _firestore
              .collection('group_kits')
              .where('kitId', whereIn: kitIds)
              .get();

      // Создаем карту связей аптечка -> группа
      final Map<String, String> kitToGroupMap = {};
      final Set<String> groupIdsToFetch = {};

      for (final doc in groupKitsSnapshot.docs) {
        final groupKit = GroupKit.fromMap(doc.data(), doc.id);
        kitToGroupMap[groupKit.kitId] = groupKit.groupId;
        groupIdsToFetch.add(groupKit.groupId);
      }

      // Получаем информацию о группах
      final Map<String, FamilyGroup> groupMap = {};
      if (groupIdsToFetch.isNotEmpty) {
        for (var i = 0; i < groupIdsToFetch.length; i += 10) {
          final end =
              (i + 10 < groupIdsToFetch.length)
                  ? i + 10
                  : groupIdsToFetch.length;
          final batch = groupIdsToFetch.toList().sublist(i, end);

          final groupsSnapshot =
              await _firestore
                  .collection('family_groups')
                  .where(FieldPath.documentId, whereIn: batch)
                  .get();

          for (final doc in groupsSnapshot.docs) {
            final group = FamilyGroup.fromMap(doc.data(), doc.id);
            groupMap[group.id] = group;
          }
        }
      }

      // Формируем результаты поиска
      final results =
          filteredMedications.map((medication) {
            final kit = kitMap[medication.kitId];
            final kitName = kit?.name ?? 'Неизвестная аптечка';

            String? groupName;
            final groupId = kitToGroupMap[medication.kitId];
            if (groupId != null) {
              groupName = groupMap[groupId]?.name;
            }

            return MedicationSearchResult(
              medication: medication,
              kitName: kitName,
              groupName: groupName,
            );
          }).toList();

      // Сортируем результаты по релевантности
      results.sort((a, b) {
        final aDistance = _calculateLevenshteinDistance(
          a.medication.name.toLowerCase(),
          queryLower,
        );
        final bDistance = _calculateLevenshteinDistance(
          b.medication.name.toLowerCase(),
          queryLower,
        );
        return aDistance.compareTo(bDistance);
      });

      return results;
    } catch (e) {
      debugPrint('Ошибка при поиске медикаментов: $e');
      return [];
    }
  }

  // Расчет расстояния Левенштейна для нечеткого поиска
  int _calculateLevenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> previousRow = List<int>.generate(b.length + 1, (i) => i);
    List<int> currentRow = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      currentRow[0] = i + 1;

      for (int j = 0; j < b.length; j++) {
        int insertCost = previousRow[j + 1] + 1;
        int deleteCost = currentRow[j] + 1;
        int replaceCost = previousRow[j] + (a[i] != b[j] ? 1 : 0);

        currentRow[j + 1] = [
          insertCost,
          deleteCost,
          replaceCost,
        ].reduce((value, element) => value < element ? value : element);
      }

      previousRow = List<int>.from(currentRow);
    }

    return currentRow[b.length];
  }
}
