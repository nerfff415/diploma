import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medication_reminder.dart';
import '../models/expiry_reminder.dart';
import '../models/medication.dart';
import '../models/medication_schedule.dart';
import 'medication_service.dart';
import 'medication_schedule_service.dart';
import 'first_aid_kit_service.dart';
import 'family_group_service.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MedicationService _medicationService = MedicationService();
  final MedicationScheduleService _scheduleService =
      MedicationScheduleService();
  final FirstAidKitService _kitService = FirstAidKitService();
  final FamilyGroupService _groupService = FamilyGroupService();

  // Коллекции уведомлений
  CollectionReference get _medicationRemindersCollection =>
      _firestore.collection('medication_reminders');

  CollectionReference get _expiryRemindersCollection =>
      _firestore.collection('expiry_reminders');

  // Создание уведомления о приеме лекарства
  Future<String> createMedicationReminder(MedicationSchedule schedule) async {
    try {
      // Получаем текущего пользователя
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Создаем уведомление
      final reminder = MedicationReminder.create(
        userId: schedule.userId,
        scheduleId: schedule.id,
        medicationId: schedule.medicationId,
        medicationName: schedule.medicationName,
        kitId: schedule.kitId,
        kitName: schedule.kitName,
        scheduledTime: schedule.date,
        dosage: schedule.dosage,
        dimension: schedule.dimension,
      );

      final docRef = await _medicationRemindersCollection.add(reminder.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка при создании уведомления о приеме лекарства: $e');
      return ''; // Возвращаем пустую строку вместо ошибки
    }
  }

  // Создание уведомления о сроке годности
  Future<String> createExpiryReminder(
    Medication medication,
    String kitName,
  ) async {
    try {
      // Получаем текущего пользователя
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Получаем список пользователей, которым нужно отправить уведомление
      final userIds = <String>[];

      // Получаем информацию об аптечке
      final kit = await _kitService.getFirstAidKit(medication.kitId);
      if (kit == null) {
        throw Exception('Аптечка не найдена');
      }

      // Добавляем владельца аптечки
      userIds.add(kit.userId);

      // Проверяем, принадлежит ли аптечка какой-либо группе
      final groupIds = await _groupService.getGroupsForKit(medication.kitId);

      // Для каждой группы получаем список участников
      for (final groupId in groupIds) {
        final members = await _groupService.getGroupMembersProfiles(groupId);
        for (final member in members) {
          if (!userIds.contains(member.userId)) {
            userIds.add(member.userId);
          }
        }
      }

      // Создаем уведомления для каждого пользователя
      final reminderIds = <String>[];
      for (final userId in userIds) {
        final reminder = ExpiryReminder.create(
          userId: userId,
          medicationId: medication.id,
          medicationName: medication.name,
          kitId: medication.kitId,
          kitName: kitName,
          expiryDate: medication.expiryDate,
        );

        final docRef = await _expiryRemindersCollection.add(reminder.toMap());
        reminderIds.add(docRef.id);
      }

      return reminderIds.isNotEmpty ? reminderIds.first : '';
    } catch (e) {
      debugPrint('Ошибка при создании уведомления о сроке годности: $e');
      return ''; // Возвращаем пустую строку вместо ошибки
    }
  }

  // Получение уведомлений о приеме лекарств для пользователя
  Stream<List<MedicationReminder>> getUserMedicationReminders(String userId) {
    try {
      return _medicationRemindersCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('scheduledTime', descending: false)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => MedicationReminder.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении уведомлений о приеме лекарств: $e');
      return Stream.value([]);
    }
  }

  // Получение уведомлений о сроке годности для пользователя
  Stream<List<ExpiryReminder>> getUserExpiryReminders(String userId) {
    try {
      return _expiryRemindersCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('daysRemaining', descending: false)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => ExpiryReminder.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении уведомлений о сроке годности: $e');
      return Stream.value([]);
    }
  }

  // Отметка уведомления о приеме лекарства как прочитанного
  Future<void> markMedicationReminderAsRead(String reminderId) async {
    try {
      await _medicationRemindersCollection.doc(reminderId).update({
        'isRead': true,
        'readAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint(
        'Ошибка при отметке уведомления о приеме лекарства как прочитанного: $e',
      );
      // Игнорируем ошибку
    }
  }

  // Отметка уведомления о сроке годности как прочитанного
  Future<void> markExpiryReminderAsRead(String reminderId) async {
    try {
      await _expiryRemindersCollection.doc(reminderId).update({
        'isRead': true,
        'readAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint(
        'Ошибка при отметке уведомления о сроке годности как прочитанного: $e',
      );
      // Игнорируем ошибку
    }
  }

  // Проверка и создание уведомлений о приеме лекарств на сегодня
  Future<void> checkAndCreateMedicationReminders(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Получаем расписания на сегодня
      final schedules =
          await _scheduleService
              .getSchedulesForPeriod(userId, startOfDay, endOfDay)
              .first;

      // Для каждого расписания создаем уведомление, если его еще нет
      for (final schedule in schedules) {
        // Проверяем, не создано ли уже уведомление для этого расписания
        final existingReminders =
            await _medicationRemindersCollection
                .where('scheduleId', isEqualTo: schedule.id)
                .get();

        if (existingReminders.docs.isEmpty) {
          await createMedicationReminder(schedule);
        }
      }
    } catch (e) {
      debugPrint(
        'Ошибка при проверке и создании уведомлений о приеме лекарств: $e',
      );
      // Игнорируем ошибку
    }
  }

  // Проверка и создание уведомлений о сроке годности
  Future<void> checkAndCreateExpiryReminders(
    String userId, {
    int daysThreshold = 30,
  }) async {
    try {
      // Получаем все аптечки пользователя
      final userKits = await _kitService.getUserFirstAidKits(userId).first;

      // Для каждой аптечки получаем медикаменты с истекающим сроком годности
      for (final kit in userKits) {
        final medications =
            await _medicationService
                .getSoonExpiringMedications(
                  kit.id,
                  daysThreshold: daysThreshold,
                )
                .first;

        // Для каждого медикамента создаем уведомление, если его еще нет
        for (final medication in medications) {
          // Проверяем, не создано ли уже уведомление для этого медикамента
          final existingReminders =
              await _expiryRemindersCollection
                  .where('medicationId', isEqualTo: medication.id)
                  .where('userId', isEqualTo: userId)
                  .where('isRead', isEqualTo: false)
                  .get();

          if (existingReminders.docs.isEmpty) {
            await createExpiryReminder(medication, kit.name);
          }
        }
      }

      // Также проверяем аптечки из групп пользователя
      final groupMemberships = await _groupService.getUserGroups(userId).first;

      for (final group in groupMemberships) {
        final kitIds = await _groupService.getGroupKits(group.id);

        for (final kitId in kitIds) {
          final kit = await _kitService.getFirstAidKit(kitId);
          if (kit == null) continue;

          final medications =
              await _medicationService
                  .getSoonExpiringMedications(
                    kitId,
                    daysThreshold: daysThreshold,
                  )
                  .first;

          for (final medication in medications) {
            // Проверяем, не создано ли уже уведомление для этого медикамента
            final existingReminders =
                await _expiryRemindersCollection
                    .where('medicationId', isEqualTo: medication.id)
                    .where('userId', isEqualTo: userId)
                    .where('isRead', isEqualTo: false)
                    .get();

            if (existingReminders.docs.isEmpty) {
              await createExpiryReminder(medication, kit.name);
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
        'Ошибка при проверке и создании уведомлений о сроке годности: $e',
      );
      // Игнорируем ошибку
    }
  }
}
