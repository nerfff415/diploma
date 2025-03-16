import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stock_notification.dart';
import '../models/medication.dart';
import 'family_group_service.dart';
import 'first_aid_kit_service.dart';

class StockNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FamilyGroupService _groupService = FamilyGroupService();
  final FirstAidKitService _kitService = FirstAidKitService();

  // Коллекция уведомлений о запасах
  CollectionReference get _notificationsCollection =>
      _firestore.collection('stock_notifications');

  // Минимальные пороговые значения для разных единиц измерения
  Map<String, double> get _thresholds => {
    'мг': 500.0, // миллиграммы
    'г': 10.0, // граммы
    'мкг': 1000.0, // микрограммы
    'мл': 50.0, // миллилитры
    'л': 0.1, // литры
    'шт': 5.0, // штуки
    'табл': 5.0, // таблетки
    'кап': 10.0, // капли
    'ед': 5.0, // единицы
  };

  // Проверка, достиг ли медикамент порогового значения
  bool isStockLow(Medication medication) {
    final threshold = _thresholds[medication.dimension] ?? 5.0;
    return medication.quantity <= threshold;
  }

  // Создание уведомления о низком уровне запасов
  Future<String> createStockNotification(
    Medication medication,
    String kitName,
    List<String> userIds,
  ) async {
    try {
      // Получаем текущего пользователя
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Убеждаемся, что текущий пользователь в списке получателей уведомления
      if (!userIds.contains(currentUser.uid)) {
        userIds.add(currentUser.uid);
      }

      // Создаем новое уведомление
      final notification = StockNotification.create(
        medicationId: medication.id,
        medicationName: medication.name,
        kitId: medication.kitId,
        kitName: kitName,
        currentQuantity: medication.quantity,
        dimension: medication.dimension,
        notifiedUserIds: userIds,
      );

      final docRef = await _notificationsCollection.add(notification.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка при создании уведомления о запасах: $e');
      return ''; // Возвращаем пустую строку вместо ошибки
    }
  }

  // Получение уведомлений для пользователя
  Stream<List<StockNotification>> getUserStockNotifications(String userId) {
    try {
      return _notificationsCollection
          .where('notifiedUserIds', arrayContains: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => StockNotification.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении уведомлений о запасах: $e');
      // Возвращаем пустой стрим в случае ошибки
      return Stream.value([]);
    }
  }

  // Отметка уведомления как прочитанного
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Ошибка при отметке уведомления как прочитанного: $e');
      // Игнорируем ошибку
    }
  }

  // Проверка запасов медикамента и создание уведомления при необходимости
  Future<void> checkMedicationStock(Medication medication) async {
    try {
      // Проверяем, достиг ли медикамент порогового значения
      if (!isStockLow(medication)) {
        return; // Запас достаточный, уведомление не требуется
      }

      // Получаем информацию об аптечке
      final kit = await _kitService.getFirstAidKit(medication.kitId);
      if (kit == null) {
        debugPrint('Аптечка не найдена: ${medication.kitId}');
        return;
      }

      // Получаем список пользователей, которым нужно отправить уведомление
      final userIds = <String>[];

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

      // Создаем уведомление
      await createStockNotification(medication, kit.name, userIds);
    } catch (e) {
      debugPrint('Ошибка при проверке запасов медикамента: $e');
      // Игнорируем ошибку
    }
  }
}
