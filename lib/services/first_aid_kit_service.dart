import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/first_aid_kit.dart';

class FirstAidKitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Создание новой аптечки
  Future<String> createFirstAidKit({
    required String name,
    required String userId,
    String? description,
  }) async {
    try {
      // Создаем документ аптечки
      final kitRef = _firestore.collection('first_aid_kits').doc();
      final kit = {
        'name': name,
        'userId': userId,
        'description': description,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await kitRef.set(kit);
      return kitRef.id;
    } catch (e) {
      print('Ошибка при создании аптечки: $e');
      rethrow;
    }
  }

  // Получение аптечки по ID
  Future<FirstAidKit?> getFirstAidKit(String kitId) async {
    try {
      final doc =
          await _firestore.collection('first_aid_kits').doc(kitId).get();
      if (doc.exists && doc.data() != null) {
        return FirstAidKit.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Ошибка при получении аптечки: $e');
      rethrow;
    }
  }

  // Обновление информации об аптечке
  Future<void> updateFirstAidKit(FirstAidKit kit) async {
    try {
      await _firestore.collection('first_aid_kits').doc(kit.id).update({
        'name': kit.name,
        'description': kit.description,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Ошибка при обновлении аптечки: $e');
      rethrow;
    }
  }

  // Удаление аптечки
  Future<void> deleteFirstAidKit(String kitId) async {
    try {
      await _firestore.collection('first_aid_kits').doc(kitId).delete();
    } catch (e) {
      print('Ошибка при удалении аптечки: $e');
      rethrow;
    }
  }

  // Получение всех аптечек пользователя
  Stream<List<FirstAidKit>> getUserFirstAidKits(String userId) {
    try {
      return _firestore
          .collection('first_aid_kits')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => FirstAidKit.fromFirestore(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      print('Ошибка при получении аптечек пользователя: $e');
      rethrow;
    }
  }

  // Получение аптечек по списку ID
  Future<List<FirstAidKit>> getFirstAidKitsByIds(List<String> kitIds) async {
    try {
      if (kitIds.isEmpty) {
        return [];
      }

      final kits = <FirstAidKit>[];

      // Firestore не поддерживает запросы с большим количеством элементов в whereIn,
      // поэтому разбиваем запрос на части по 10 элементов
      for (var i = 0; i < kitIds.length; i += 10) {
        final end = (i + 10 < kitIds.length) ? i + 10 : kitIds.length;
        final batch = kitIds.sublist(i, end);

        final snapshot =
            await _firestore
                .collection('first_aid_kits')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        kits.addAll(
          snapshot.docs
              .map((doc) => FirstAidKit.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
      }

      return kits;
    } catch (e) {
      print('Ошибка при получении аптечек по ID: $e');
      rethrow;
    }
  }
}
