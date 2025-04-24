import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получение потока обновлений состояния пользователя
  Stream<User?> get userStream => _auth.authStateChanges();

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Регистрация нового пользователя
  Future<void> register(String email, String password, String name) async {
    try {
      // Создаем пользователя в Firebase Auth
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Добавляем небольшую задержку, чтобы дать Firebase время обновить состояние
      await Future.delayed(const Duration(milliseconds: 1000));

      // Получаем текущего пользователя после создания
      final user = _auth.currentUser;
      if (user != null) {
        // Создаем документ пользователя в Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('Пользователь не был создан');
      }
    } catch (e) {
      print('Error during registration: $e');

      // Проверяем, является ли ошибка проблемой преобразования типов PigeonUserDetails
      if (e.toString().contains('PigeonUserDetails')) {
        // Если текущий пользователь существует, значит регистрация прошла успешно
        if (_auth.currentUser != null) {
          print(
            'Пользователь зарегистрирован успешно, несмотря на ошибку: ${_auth.currentUser?.email}',
          );

          // Создаем документ пользователя в Firestore
          await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });
          return;
        }
      }
      rethrow;
    }
  }

  // Вход в систему
  Future<void> signIn(String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');

      try {
        // Пробуем войти
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Добавляем небольшую задержку, чтобы дать Firebase время обновить состояние
        await Future.delayed(const Duration(milliseconds: 1000));

        // Проверяем, что пользователь действительно вошел
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          print('Current user is null after sign in');
          throw Exception('Ошибка при входе. Попробуйте еще раз');
        }

        print('Sign in successful for user: ${currentUser.email}');
      } catch (e) {
        print('Firebase sign in error: $e');

        // Проверяем, является ли ошибка проблемой преобразования типов PigeonUserDetails
        if (e.toString().contains('PigeonUserDetails')) {
          // Если текущий пользователь существует, значит вход прошел успешно
          if (_auth.currentUser != null) {
            print(
              'User signed in successfully despite PigeonUserDetails error',
            );
            return;
          }
        }

        if (e is FirebaseAuthException) {
          print('Firebase error code: ${e.code}');
          print('Firebase error message: ${e.message}');

          String errorMessage;
          switch (e.code) {
            case 'invalid-credential':
            case 'wrong-password':
              errorMessage = 'Неверный email или пароль';
              break;
            case 'user-not-found':
              errorMessage = 'Пользователь с таким email не найден';
              break;
            case 'user-disabled':
              errorMessage = 'Аккаунт заблокирован';
              break;
            case 'too-many-requests':
              errorMessage = 'Слишком много попыток входа. Попробуйте позже';
              break;
            case 'network-request-failed':
              errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
              break;
            case 'invalid-email':
              errorMessage = 'Некорректный формат email';
              break;
            default:
              errorMessage = 'Ошибка при входе: ${e.message}';
          }

          throw Exception(errorMessage);
        } else {
          print('Non-Firebase error during sign in: $e');
          throw Exception('Произошла ошибка при входе. Попробуйте позже');
        }
      }
    } catch (e) {
      print('Final error in signIn: $e');
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
