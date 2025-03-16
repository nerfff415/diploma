import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../widgets/bottom_navigation.dart';

/// Обертка для перенаправления пользователя на соответствующий экран
/// в зависимости от статуса аутентификации.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Проверяем состояние аутентификации при инициализации
    _checkAuthState();
  }

  // Метод для проверки состояния аутентификации
  void _checkAuthState() {
    // Добавляем небольшую задержку, чтобы дать Firebase время обновить состояние
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final auth = FirebaseAuth.instance;
        print('Initial auth check: ${auth.currentUser?.email}');
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Если инициализация еще не завершена, показываем индикатор загрузки
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Получаем пользователя из Provider
    final user = Provider.of<User?>(context);

    // Получаем AuthService для дополнительной проверки
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    // Добавляем отладочную информацию
    print('AuthWrapper: Provider user: ${user?.email}');
    print('AuthWrapper: Current Firebase user: ${currentUser?.email}');
    print('AuthWrapper: Is authenticated: ${authService.isAuthenticated}');

    // Проверяем напрямую Firebase Auth
    final firebaseUser = FirebaseAuth.instance.currentUser;
    print('AuthWrapper: Direct Firebase user: ${firebaseUser?.email}');

    // Если пользователь авторизован (проверяем все источники), показываем навигацию с вкладками,
    // иначе показываем экран входа
    if (user != null || currentUser != null || firebaseUser != null) {
      print('AuthWrapper: User is authenticated, showing BottomNavigation');
      return const BottomNavigation();
    } else {
      print('AuthWrapper: User is not authenticated, showing LoginScreen');
      return const LoginScreen();
    }
  }
}
