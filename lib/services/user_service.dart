import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Создание или обновление профиля пользователя
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.userId)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Ошибка при обновлении профиля: $e');
      rethrow;
    }
  }

  // Получение профиля пользователя
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        throw Exception('Профиль пользователя не найден');
      }

      final data = doc.data()!;

      // Преобразуем Timestamp в DateTime
      final createdAt = data['createdAt'] as Timestamp?;

      return {
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
        'createdAt':
            createdAt?.toDate().millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('Ошибка при получении профиля: $e');
      rethrow;
    }
  }

  // Создание профиля при регистрации
  Future<void> createUserProfile(String userId, String email) async {
    try {
      // Проверяем, существует ли уже профиль
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        // Создаем базовый профиль с email
        final profile = UserProfile(
          userId: userId,
          firstName: '',
          lastName: '',
          email: email,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(userId).set(profile.toMap());
      }
    } catch (e) {
      print('Ошибка при создании профиля: $e');
      rethrow;
    }
  }
}
