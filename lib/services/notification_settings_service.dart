import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notification_settings.dart';

class NotificationSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Коллекция настроек уведомлений
  CollectionReference get _settingsCollection =>
      _firestore.collection('notification_settings');

  // Получение настроек уведомлений пользователя
  Future<NotificationSettings?> getUserSettings(String userId) async {
    try {
      final querySnapshot =
          await _settingsCollection
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return NotificationSettings.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }

      // Если настройки не найдены, создаем настройки по умолчанию
      final defaultSettings = NotificationSettings.createDefault(userId);
      final docRef = await _settingsCollection.add(defaultSettings.toMap());
      return defaultSettings.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Ошибка при получении настроек уведомлений: $e');
      return null;
    }
  }

  // Обновление настроек уведомлений
  Future<void> updateSettings(NotificationSettings settings) async {
    try {
      await _settingsCollection.doc(settings.id).update(settings.toMap());
    } catch (e) {
      debugPrint('Ошибка при обновлении настроек уведомлений: $e');
      rethrow;
    }
  }

  // Включение/выключение уведомлений
  Future<void> toggleNotifications(String settingsId, bool enabled) async {
    try {
      await _settingsCollection.doc(settingsId).update({
        'enabled': enabled,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Ошибка при изменении статуса уведомлений: $e');
      rethrow;
    }
  }

  // Включение/выключение напоминаний о приеме лекарств
  Future<void> toggleMedicationReminders(
    String settingsId,
    bool enabled,
  ) async {
    try {
      await _settingsCollection.doc(settingsId).update({
        'medicationReminders': enabled,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Ошибка при изменении напоминаний о приеме лекарств: $e');
      rethrow;
    }
  }

  // Включение/выключение напоминаний о сроке годности
  Future<void> toggleExpiryReminders(String settingsId, bool enabled) async {
    try {
      await _settingsCollection.doc(settingsId).update({
        'expiryReminders': enabled,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Ошибка при изменении напоминаний о сроке годности: $e');
      rethrow;
    }
  }

  // Изменение времени напоминания
  Future<void> updateReminderTime(String settingsId, int minutes) async {
    try {
      await _settingsCollection.doc(settingsId).update({
        'reminderTime': minutes,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Ошибка при изменении времени напоминания: $e');
      rethrow;
    }
  }

  // Изменение дней для напоминания о сроке годности
  Future<void> updateExpiryReminderDays(String settingsId, int days) async {
    try {
      await _settingsCollection.doc(settingsId).update({
        'expiryReminderDays': days,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Ошибка при изменении дней напоминания о сроке годности: $e');
      rethrow;
    }
  }
}
