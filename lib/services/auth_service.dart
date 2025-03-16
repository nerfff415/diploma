import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Получение потока обновлений состояния пользователя
  Stream<User?> get userStream => _auth.authStateChanges();

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Регистрация с помощью email и пароля
  Future<bool> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Возвращаем true, если регистрация успешна и пользователь создан
      if (userCredential.user != null) {
        // Создаем базовый профиль пользователя
        await _userService.createUserProfile(userCredential.user!.uid, email);
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка при регистрации: $e');
      // Проверяем, является ли ошибка проблемой преобразования типов PigeonUserDetails
      if (e.toString().contains('PigeonUserDetails')) {
        // Если пользователь был успешно создан, но возникла ошибка преобразования,
        // проверяем, есть ли текущий пользователь
        if (_auth.currentUser != null) {
          // Создаем базовый профиль пользователя
          await _userService.createUserProfile(_auth.currentUser!.uid, email);
          return true; // Пользователь создан успешно, несмотря на ошибку
        }
      }
      rethrow;
    }
  }

  // Вход с помощью email и пароля
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Возвращаем true, если вход успешен
      return userCredential.user != null;
    } catch (e) {
      print('Ошибка при входе: $e');
      // Проверяем, является ли ошибка проблемой преобразования типов PigeonUserDetails
      if (e.toString().contains('PigeonUserDetails')) {
        // Добавляем небольшую задержку, чтобы дать Firebase время обновить состояние
        await Future.delayed(const Duration(milliseconds: 1000));

        // Если пользователь успешно вошел, но возникла ошибка преобразования,
        // проверяем, есть ли текущий пользователь
        if (_auth.currentUser != null) {
          print(
            'Пользователь вошел успешно, несмотря на ошибку: ${_auth.currentUser?.email}',
          );
          return true; // Пользователь вошел успешно, несмотря на ошибку
        }

        // Если текущего пользователя нет, попробуем войти еще раз
        try {
          print('Пробуем войти повторно после ошибки PigeonUserDetails');
          // Пробуем войти снова, но без обработки исключений
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Проверяем еще раз после повторной попытки
          if (_auth.currentUser != null) {
            print('Повторный вход успешен: ${_auth.currentUser?.email}');
            return true;
          }
        } catch (retryError) {
          print('Ошибка при повторном входе: $retryError');
          // Игнорируем ошибку повторной попытки
        }
      }
      rethrow;
    }
  }

  // Выход из аккаунта
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Ошибка при выходе: $e');
      rethrow;
    }
  }

  // Сброс пароля
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Ошибка при сбросе пароля: $e');
      rethrow;
    }
  }

  // Проверка, аутентифицирован ли пользователь
  bool get isAuthenticated => currentUser != null;

  // Получение email пользователя
  String? get userEmail => currentUser?.email;
}
