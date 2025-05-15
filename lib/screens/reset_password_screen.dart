import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Основные компоненты
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // Состояния экрана
  String _message = '';
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Обработка запроса на сброс пароля
  void _resetPassword() {
    if (!_validateForm()) return;
    
    _startPasswordReset();
    
    _sendPasswordResetRequest()
      .then(_handleSuccess)
      .catchError(_handleError)
      .whenComplete(_completePasswordReset);
  }
  
  // Валидация формы
  bool _validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }
  
  // Начало процесса сброса пароля
  void _startPasswordReset() {
    setState(() {
      _isLoading = true;
      _message = '';
      _isSuccess = false;
    });
  }
  
  // Отправка запроса на сброс пароля
  Future<void> _sendPasswordResetRequest() async {
    return _authService.resetPassword(_emailController.text.trim());
  }
  
  // Обработка успешного запроса
  void _handleSuccess(_) {
    if (!mounted) return;
    
    setState(() {
      _isSuccess = true;
      _message = 'Инструкции по восстановлению пароля отправлены на указанный адрес';
    });
  }
  
  // Обработка ошибки
  void _handleError(dynamic error) {
    if (!mounted) return;
    
    setState(() {
      _isSuccess = false;
      _message = _getErrorMessage(error);
    });
  }
  
  // Получение сообщения об ошибке
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _mapFirebaseErrorToMessage(error);
    }
    return error.toString();
  }
  
  // Преобразование ошибок Firebase в понятные сообщения
  String _mapFirebaseErrorToMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'Пользователь с таким адресом не найден';
      case 'invalid-email':
        return 'Некорректный формат электронной почты';
      default:
        return 'Произошла ошибка: ${error.message}';
    }
  }
  
  // Завершение процесса сброса пароля
  void _completePasswordReset() {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Возврат на экран входа
  void _navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _buildScreenContent(),
      ),
    );
  }
  
  // Построение AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Восстановление пароля'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );
  }
  
  // Построение содержимого экрана
  Widget _buildScreenContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 32),
              _buildEmailField(),
              const SizedBox(height: 24),
              if (_message.isNotEmpty) _buildMessageContainer(),
              const SizedBox(height: 16),
              _buildActionButton(),
              const SizedBox(height: 24),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }
  
  // Построение заголовка экрана
  Widget _buildHeaderSection() {
    return Column(
      children: const [
        Icon(Icons.lock_reset, size: 80, color: Colors.green),
        SizedBox(height: 24),
        Text(
          'Восстановление пароля',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Введите адрес электронной почты, указанный при регистрации. '
          'Мы отправим инструкции для создания нового пароля.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
  
  // Построение поля ввода email
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'example@mail.com',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      validator: _validateEmail,
    );
  }
  
  // Валидация email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите email';
    }
    
    // Проверка формата email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный email';
    }
    
    return null;
  }
  
  // Построение контейнера с сообщением
  Widget _buildMessageContainer() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isSuccess ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _message,
        style: TextStyle(
          color: _isSuccess ? Colors.green[800] : Colors.red[800],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  // Построение кнопки действия
  Widget _buildActionButton() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ElevatedButton(
      onPressed: _resetPassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Отправить инструкции',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
  
  // Построение ссылки на экран входа
  Widget _buildLoginLink() {
    return TextButton(
      onPressed: _navigateToLogin,
      child: const Text('Вернуться на страницу входа'),
    );
  }
}
