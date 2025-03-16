import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!, userId);
      }
      return null;
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
