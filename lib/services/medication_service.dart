import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'stock_notification_service.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StockNotificationService _stockNotificationService =
      StockNotificationService();

  // Коллекция медикаментов
  CollectionReference get _medicationsCollection =>
      _firestore.collection('medications');

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Создание нового медикамента
  Future<String> createMedication(Medication medication) async {
    try {
      final docRef = await _medicationsCollection.add(medication.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка при создании медикамента: $e');
      rethrow;
    }
  }

  // Получение медикамента по ID
  Future<Medication?> getMedicationById(String medicationId) async {
    try {
      final docSnapshot = await _medicationsCollection.doc(medicationId).get();
      if (docSnapshot.exists) {
        return Medication.fromFirestore(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка при получении медикамента: $e');
      rethrow;
    }
  }

  // Обновление медикамента
  Future<void> updateMedication(Medication medication) async {
    try {
      await _medicationsCollection
          .doc(medication.id)
          .update(medication.toMap());
    } catch (e) {
      debugPrint('Ошибка при обновлении медикамента: $e');
      rethrow;
    }
  }

  // Удаление медикамента
  Future<void> deleteMedication(String medicationId) async {
    try {
      await _medicationsCollection.doc(medicationId).delete();
    } catch (e) {
      debugPrint('Ошибка при удалении медикамента: $e');
      rethrow;
    }
  }

  // Уменьшение количества медикамента
  Future<void> decreaseMedicationQuantity(
    String medicationId,
    double amount,
  ) async {
    try {
      // Получаем текущий медикамент
      final medication = await getMedicationById(medicationId);
      if (medication == null) {
        throw Exception('Медикамент не найден');
      }

      // Проверяем, достаточно ли количества
      if (medication.quantity < amount) {
        throw Exception(
          'Недостаточное количество медикамента. Доступно: ${medication.quantity} ${medication.dimension}',
        );
      }

      // Обновляем количество
      final updatedQuantity = medication.quantity - amount;
      await _medicationsCollection.doc(medicationId).update({
        'quantity': updatedQuantity,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Проверяем, не достиг ли запас минимального уровня
      final updatedMedication = medication.copyWith(quantity: updatedQuantity);
      await _stockNotificationService.checkMedicationStock(updatedMedication);
    } catch (e) {
      debugPrint('Ошибка при уменьшении количества медикамента: $e');
      rethrow;
    }
  }

  // Увеличение количества медикамента
  Future<void> increaseMedicationQuantity(
    String medicationId,
    double amount,
  ) async {
    try {
      // Получаем текущий медикамент
      final medication = await getMedicationById(medicationId);
      if (medication == null) {
        throw Exception('Медикамент не найден');
      }

      // Обновляем количество
      final updatedQuantity = medication.quantity + amount;
      await _medicationsCollection.doc(medicationId).update({
        'quantity': updatedQuantity,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Ошибка при увеличении количества медикамента: $e');
      rethrow;
    }
  }

  // Получение списка медикаментов для конкретной аптечки
  Stream<List<Medication>> getMedicationsForKit(String kitId) {
    try {
      return _medicationsCollection
          .where('kitId', isEqualTo: kitId)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => Medication.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении списка медикаментов: $e');
      rethrow;
    }
  }

  // Получение списка медикаментов по категории для конкретной аптечки
  Stream<List<Medication>> getMedicationsByCategory(
    String kitId,
    String category,
  ) {
    try {
      return _medicationsCollection
          .where('kitId', isEqualTo: kitId)
          .where('category', isEqualTo: category)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => Medication.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении списка медикаментов по категории: $e');
      rethrow;
    }
  }

  // Получение списка просроченных медикаментов
  Stream<List<Medication>> getExpiredMedications(String kitId) {
    final now = DateTime.now();
    try {
      return _medicationsCollection
          .where('kitId', isEqualTo: kitId)
          .where('expiryDate', isLessThan: now.millisecondsSinceEpoch)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => Medication.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении списка просроченных медикаментов: $e');
      rethrow;
    }
  }

  // Получение списка медикаментов, срок годности которых истекает в ближайшее время
  Stream<List<Medication>> getSoonExpiringMedications(
    String kitId, {
    int daysThreshold = 30,
  }) {
    final now = DateTime.now();
    final thresholdDate = now.add(Duration(days: daysThreshold));

    try {
      return _medicationsCollection
          .where('kitId', isEqualTo: kitId)
          .where(
            'expiryDate',
            isGreaterThanOrEqualTo: now.millisecondsSinceEpoch,
          )
          .where(
            'expiryDate',
            isLessThanOrEqualTo: thresholdDate.millisecondsSinceEpoch,
          )
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => Medication.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint(
        'Ошибка при получении списка медикаментов с истекающим сроком годности: $e',
      );
      rethrow;
    }
  }

  // Поиск медикаментов по названию
  Stream<List<Medication>> searchMedicationsByName(String kitId, String query) {
    if (query.isEmpty) {
      return getMedicationsForKit(kitId);
    }

    final queryLower = query.toLowerCase();

    try {
      return _medicationsCollection
          .where('kitId', isEqualTo: kitId)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => Medication.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .where(
                      (medication) =>
                          medication.name.toLowerCase().contains(queryLower),
                    )
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при поиске медикаментов: $e');
      rethrow;
    }
  }

  // Получение медикаментов с низким запасом для конкретной аптечки
  Stream<List<Medication>> getLowStockMedications(
    String kitId, {
    double threshold = 0.2, // 20% от начального количества по умолчанию
  }) {
    try {
      return _medicationsCollection
          .where('kitId', isEqualTo: kitId)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => Medication.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .where((medication) => isLowStock(medication, threshold))
                    .toList(),
          );
    } catch (e) {
      debugPrint('Ошибка при получении медикаментов с низким запасом: $e');
      rethrow;
    }
  }

  // Проверка, является ли запас медикамента низким
  bool isLowStock(Medication medication, double threshold) {
    // Для простоты считаем, что если количество меньше 5 единиц, то запас низкий
    // В реальном приложении можно использовать более сложную логику
    if (medication.dimension == 'шт' ||
        medication.dimension == 'табл' ||
        medication.dimension == 'капс') {
      return medication.quantity <= 5;
    }

    // Для жидкостей и других форм используем порог в процентах
    // Предполагаем, что начальное количество было больше текущего
    // Для точной проверки нужно хранить начальное количество в базе данных
    return medication.quantity <=
        threshold * 100; // Предполагаем, что начальное количество было 100
  }

  // Получение всех медикаментов с низким запасом для пользователя
  Future<List<Medication>> getAllLowStockMedications(
    String userId, {
    double threshold = 0.2,
  }) async {
    try {
      // Получаем все аптечки пользователя
      final userKitsSnapshot =
          await _firestore
              .collection('first_aid_kits')
              .where('userId', isEqualTo: userId)
              .get();

      final userKitIds = userKitsSnapshot.docs.map((doc) => doc.id).toList();

      // Если нет аптечек, возвращаем пустой список
      if (userKitIds.isEmpty) {
        return [];
      }

      // Получаем все медикаменты из аптечек пользователя
      final List<Medication> allMedications = [];

      // Firestore не поддерживает запросы с большим количеством элементов в whereIn,
      // поэтому разбиваем запрос на части по 10 элементов
      for (var i = 0; i < userKitIds.length; i += 10) {
        final end = (i + 10 < userKitIds.length) ? i + 10 : userKitIds.length;
        final batch = userKitIds.sublist(i, end);

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
                .where((medication) => isLowStock(medication, threshold))
                .toList();

        allMedications.addAll(medications);
      }

      return allMedications;
    } catch (e) {
      debugPrint('Ошибка при получении всех медикаментов с низким запасом: $e');
      rethrow;
    }
  }
}
