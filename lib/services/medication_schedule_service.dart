import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/medication.dart';
import '../models/medication_schedule.dart';
import 'medication_service.dart';
import 'first_aid_kit_service.dart';
import 'family_group_service.dart';

class MedicationScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirstAidKitService _kitService = FirstAidKitService();
  final FamilyGroupService _groupService = FamilyGroupService();
  final MedicationService _medicationService = MedicationService();

  // Коллекция расписаний приема лекарств
  CollectionReference get _schedulesCollection =>
      _firestore.collection('medication_schedules');

  // Создание нового расписания
  Future<String> createSchedule(MedicationSchedule schedule) async {
    try {
      // Проверяем, что медикамент существует
      final medication = await _medicationService.getMedicationById(
        schedule.medicationId,
      );
      if (medication == null) {
        throw Exception('Медикамент не найден');
      }

      // Создаем расписание
      final docRef = await _schedulesCollection.add(schedule.toMap());

      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка при создании расписания: $e');
      rethrow;
    }
  }

  // Получение расписания по ID
  Future<MedicationSchedule?> getScheduleById(String scheduleId) async {
    try {
      final docSnapshot = await _schedulesCollection.doc(scheduleId).get();
      if (!docSnapshot.exists) {
        return null;
      }

      return MedicationSchedule.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      debugPrint('Ошибка при получении расписания: $e');
      return null;
    }
  }

  // Получение всех расписаний пользователя
  Stream<List<MedicationSchedule>> getUserSchedules(String userId) {
    try {
      return _schedulesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => MedicationSchedule.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении расписаний пользователя: $e');
      return Stream.value([]);
    }
  }

  // Получение расписаний для конкретной аптечки
  Stream<List<MedicationSchedule>> getKitSchedules(String kitId) {
    try {
      return _schedulesCollection
          .where('kitId', isEqualTo: kitId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => MedicationSchedule.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении расписаний аптечки: $e');
      return Stream.value([]);
    }
  }

  // Получение расписаний для конкретного медикамента
  Stream<List<MedicationSchedule>> getMedicationSchedules(String medicationId) {
    try {
      return _schedulesCollection
          .where('medicationId', isEqualTo: medicationId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => MedicationSchedule.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении расписаний медикамента: $e');
      return Stream.value([]);
    }
  }

  // Получение расписаний на определенный период
  Stream<List<MedicationSchedule>> getSchedulesForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      // Нормализуем даты (убираем время)
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      return _schedulesCollection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
          .where('date', isLessThanOrEqualTo: end.millisecondsSinceEpoch)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => MedicationSchedule.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении расписаний за период: $e');
      return Stream.value([]);
    }
  }

  // Получение расписаний на сегодня
  Stream<List<MedicationSchedule>> getTodaySchedules(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getSchedulesForPeriod(userId, startOfDay, endOfDay);
  }

  // Обновление расписания
  Future<void> updateSchedule(MedicationSchedule schedule) async {
    try {
      await _schedulesCollection.doc(schedule.id).update(schedule.toMap());
    } catch (e) {
      debugPrint('Ошибка при обновлении расписания: $e');
      rethrow;
    }
  }

  // Удаление расписания
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _schedulesCollection.doc(scheduleId).delete();
    } catch (e) {
      debugPrint('Ошибка при удалении расписания: $e');
      rethrow;
    }
  }

  // Отметка о приеме лекарства
  Future<void> markAsTaken(String scheduleId) async {
    try {
      // Получаем текущее расписание
      final schedule = await getScheduleById(scheduleId);
      if (schedule == null) {
        throw Exception('Расписание не найдено');
      }

      // Проверяем, что лекарство еще не отмечено как принятое
      if (schedule.taken) {
        return; // Уже отмечено
      }

      // Получаем медикамент из аптечки
      final medication = await _medicationService.getMedicationById(
        schedule.medicationId,
      );

      if (medication == null) {
        throw Exception('Медикамент не найден в аптечке');
      }

      // Проверяем, достаточно ли количества для списания
      if (medication.quantity < schedule.dosage) {
        throw Exception(
          'Недостаточное количество медикамента в аптечке. Доступно: ${medication.quantity} ${medication.dimension}',
        );
      }

      // Уменьшаем количество медикамента в аптечке
      await _medicationService.decreaseMedicationQuantity(
        schedule.medicationId,
        schedule.dosage,
      );

      // Обновляем расписание
      final updatedSchedule = schedule.copyWith(
        taken: true,
        takenAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _schedulesCollection
          .doc(scheduleId)
          .update(updatedSchedule.toMap());
    } catch (e) {
      debugPrint('Ошибка при отметке о приеме лекарства: $e');
      rethrow;
    }
  }

  // Отмена отметки о приеме лекарства
  Future<void> markAsNotTaken(String scheduleId) async {
    try {
      // Получаем текущее расписание
      final schedule = await getScheduleById(scheduleId);
      if (schedule == null) {
        throw Exception('Расписание не найдено');
      }

      // Проверяем, что лекарство отмечено как принятое
      if (!schedule.taken) {
        return; // Уже не отмечено
      }

      // Возвращаем количество медикамента в аптечку
      await _medicationService.increaseMedicationQuantity(
        schedule.medicationId,
        schedule.dosage,
      );

      // Обновляем расписание
      final updatedSchedule = schedule.copyWith(
        taken: false,
        takenAt: null,
        updatedAt: DateTime.now(),
      );

      await _schedulesCollection
          .doc(scheduleId)
          .update(updatedSchedule.toMap());
    } catch (e) {
      debugPrint('Ошибка при отмене отметки о приеме лекарства: $e');
      rethrow;
    }
  }

  // Получение статистики по приему лекарств за период
  Future<Map<String, dynamic>> getStatistics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Нормализуем даты (убираем время)
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      // Получаем все расписания за период
      final querySnapshot =
          await _schedulesCollection
              .where('userId', isEqualTo: userId)
              .where(
                'date',
                isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
              )
              .where('date', isLessThanOrEqualTo: end.millisecondsSinceEpoch)
              .get();

      final schedules =
          querySnapshot.docs
              .map(
                (doc) => MedicationSchedule.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // Общая статистика
      final totalScheduled = schedules.length;
      final totalTaken = schedules.where((s) => s.taken).length;
      final completionRate =
          totalScheduled > 0
              ? ((totalTaken / totalScheduled) * 100).toStringAsFixed(1)
              : '0';

      // Статистика по медикаментам
      final medicationStats = <String, Map<String, dynamic>>{};

      for (final schedule in schedules) {
        if (!medicationStats.containsKey(schedule.medicationId)) {
          medicationStats[schedule.medicationId] = {
            'name': schedule.medicationName,
            'scheduled': 0,
            'taken': 0,
          };
        }

        medicationStats[schedule.medicationId]!['scheduled'] =
            medicationStats[schedule.medicationId]!['scheduled'] + 1;

        if (schedule.taken) {
          medicationStats[schedule.medicationId]!['taken'] =
              medicationStats[schedule.medicationId]!['taken'] + 1;
        }
      }

      return {
        'totalScheduled': totalScheduled,
        'totalTaken': totalTaken,
        'completionRate': completionRate,
        'medicationStats': medicationStats,
      };
    } catch (e) {
      debugPrint('Ошибка при получении статистики: $e');
      rethrow;
    }
  }

  // Получение всех доступных медикаментов для пользователя
  Future<List<Medication>> getAvailableMedications(String userId) async {
    try {
      // Получаем все аптечки пользователя
      final userKitsSnapshot =
          await _firestore
              .collection('first_aid_kits')
              .where('userId', isEqualTo: userId)
              .get();

      final userKitIds = userKitsSnapshot.docs.map((doc) => doc.id).toList();

      // Получаем все группы пользователя
      final userGroupsSnapshot =
          await _firestore
              .collection('group_members')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .get();

      final userGroupIds =
          userGroupsSnapshot.docs
              .map((doc) => doc.data()['groupId'] as String)
              .toList();

      // Получаем все аптечки из групп пользователя
      final List<String> groupKitIds = [];
      for (final groupId in userGroupIds) {
        final kitIds = await _groupService.getGroupKits(groupId);
        groupKitIds.addAll(kitIds);
      }

      // Объединяем все ID аптечек
      final allKitIds = [...userKitIds, ...groupKitIds];

      // Если нет доступных аптечек, возвращаем пустой список
      if (allKitIds.isEmpty) {
        return [];
      }

      // Получаем все медикаменты из доступных аптечек
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

      return allMedications;
    } catch (e) {
      debugPrint('Ошибка при получении доступных медикаментов: $e');
      rethrow;
    }
  }
}
