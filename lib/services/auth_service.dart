import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Инициализация сервисов Firebase
  final _authProvider = FirebaseAuth.instance;
  final _dbProvider = FirebaseFirestore.instance;
  final _userProvider = UserService();

  // Поток состояния аутентификации
  Stream<User?> get userStream => _authProvider.authStateChanges();

  // Текущий пользователь
  User? get currentUser => _authProvider.currentUser;

  // Создание новой учетной записи
  Future<void> register(String email, String password, String name) async {
    UserCredential? credential;
    
    try {
      // Шаг 1: Создание записи в системе аутентификации
      credential = await _authProvider.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Ожидание обновления состояния
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Шаг 2: Проверка успешного создания и сохранение профиля
      if (credential.user != null) {
        await _saveUserProfile(credential.user!.uid, name, email);
      } else {
        throw Exception('Ошибка создания учетной записи');
      }
    } on FirebaseAuthException catch (authError) {
      _handleRegistrationError(authError);
    } catch (e) {
      // Обработка особого случая с PigeonUserDetails
      if (_isPigeonUserDetailsError(e) && _authProvider.currentUser != null) {
        await _saveUserProfile(_authProvider.currentUser!.uid, name, email);
        return;
      }
      rethrow;
    }
  }
  
  // Сохранение профиля пользователя в базе данных
  Future<void> _saveUserProfile(String userId, String name, String email) async {
    await _dbProvider.collection('users').doc(userId).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Проверка на специфическую ошибку PigeonUserDetails
  bool _isPigeonUserDetailsError(dynamic error) {
    return error.toString().contains('PigeonUserDetails');
  }
  
  // Обработка ошибок регистрации
  void _handleRegistrationError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        throw Exception('Этот email уже используется');
      case 'invalid-email':
        throw Exception('Некорректный формат email');
      case 'operation-not-allowed':
        throw Exception('Регистрация с email и паролем отключена');
      case 'weak-password':
        throw Exception('Пароль слишком простой');
      default:
        throw Exception('Ошибка регистрации: ${e.message}');
    }
  }

  // Вход в систему
  Future<void> signIn(String email, String password) async {
    try {
      // Попытка аутентификации
      await _performSignIn(email, password);
      
      // Проверка состояния после аутентификации
      if (_authProvider.currentUser == null) {
        throw Exception('Не удалось выполнить вход');
      }
    } on FirebaseAuthException catch (authError) {
      throw _mapAuthExceptionToUserMessage(authError);
    } catch (e) {
      // Проверка на специфическую ошибку PigeonUserDetails
      if (_isPigeonUserDetailsError(e) && _authProvider.currentUser != null) {
        return; // Вход успешен несмотря на ошибку
      }
      throw Exception('Произошла ошибка при входе');
    }
  }
  
  // Выполнение процесса входа
  Future<void> _performSignIn(String email, String password) async {
    await _authProvider.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Ожидание обновления состояния
    await Future.delayed(const Duration(milliseconds: 1000));
  }
  
  // Преобразование технических ошибок в понятные пользователю сообщения
  Exception _mapAuthExceptionToUserMessage(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        message = 'Неверный email или пароль';
        break;
      case 'user-not-found':
        message = 'Пользователь с таким email не найден';
        break;
      case 'user-disabled':
        message = 'Аккаунт заблокирован';
        break;
      case 'too-many-requests':
        message = 'Слишком много попыток входа. Попробуйте позже';
        break;
      case 'network-request-failed':
        message = 'Ошибка сети. Проверьте подключение к интернету';
        break;
      case 'invalid-email':
        message = 'Некорректный формат email';
        break;
      default:
        message = 'Ошибка при входе: ${e.message}';
    }
    
    return Exception(message);
  }

  // Выход из системы
  Future<void> signOut() async {
    try {
      await _authProvider.signOut();
    } catch (e) {
      throw Exception('Не удалось выполнить выход из системы');
    }
  }

  // Восстановление пароля
  Future<void> resetPassword(String email) async {
    try {
      await _authProvider.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapPasswordResetExceptionToUserMessage(e);
    } catch (e) {
      throw Exception('Ошибка при восстановлении пароля');
    }
  }
  
  // Преобразование ошибок восстановления пароля в понятные сообщения
  Exception _mapPasswordResetExceptionToUserMessage(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'user-not-found':
        message = 'Пользователь с таким email не найден';
        break;
      case 'invalid-email':
        message = 'Некорректный формат email';
        break;
      default:
        message = 'Ошибка при восстановлении пароля: ${e.message}';
    }
    
    return Exception(message);
  }

  // Проверка состояния аутентификации
  bool get isAuthenticated => currentUser != null;

  // Получение email текущего пользователя
  String? get userEmail => currentUser?.email;
}
