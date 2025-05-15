import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with ValidationMixin {
  // Контроллеры для управления полями формы
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Сервис аутентификации
  final _authService = AuthService();

  // Состояние экрана
  bool _isLoading = false;

  @override
  void dispose() {
    // Освобождение ресурсов
    _disposeControllers();
    super.dispose();
  }
  
  // Метод для освобождения контроллеров
  void _disposeControllers() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
  }

  // Обработка регистрации
  void _register() {
    if (!_validateForm()) return;
    
    _setLoadingState(true);
    
    _createAccount()
      .then(_onRegistrationSuccess)
      .catchError(_onRegistrationError)
      .whenComplete(_finalizeRegistration);
  }
  
  // Валидация формы
  bool _validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }
  
  // Установка состояния загрузки
  void _setLoadingState(bool isLoading) {
    if (mounted) {
      setState(() {
        _isLoading = isLoading;
      });
    }
  }
  
  // Создание учетной записи
  Future<void> _createAccount() async {
    return _authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
    );
  }
  
  // Обработка успешной регистрации
  void _onRegistrationSuccess(_) {
    if (!mounted) return;
    
    _showSuccessMessage();
    _navigateBack();
  }
  
  // Отображение сообщения об успехе
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Учетная запись создана! Теперь вы можете войти.'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  // Возврат на предыдущий экран
  void _navigateBack() {
    Navigator.pop(context);
  }
  
  // Обработка ошибки регистрации
  void _onRegistrationError(dynamic error) {
    if (!mounted) return;
    
    final errorMessage = _getErrorMessage(error);
    _showErrorMessage(errorMessage);
  }
  
  // Получение сообщения об ошибке
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('email-already-in-use')) {
      return 'Этот email уже используется';
    } else if (errorString.contains('weak-password')) {
      return 'Пароль недостаточно надежный';
    } else if (errorString.contains('invalid-email')) {
      return 'Указан некорректный email';
    }
    
    return 'Не удалось создать учетную запись';
  }
  
  // Отображение сообщения об ошибке
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  // Завершение процесса регистрации
  void _finalizeRegistration() {
    _setLoadingState(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingIndicator() : _buildRegistrationForm(),
    );
  }
  
  // Построение AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Регистрация'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );
  }
  
  // Построение индикатора загрузки
  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }
  
  // Построение формы регистрации
  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNameField(),
            const SizedBox(height: 16),
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildConfirmPasswordField(),
            const SizedBox(height: 24),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }
  
  // Построение поля ввода имени
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Имя',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      validator: validateName,
    );
  }
  
  // Построение поля ввода email
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: validateEmail,
    );
  }
  
  // Построение поля ввода пароля
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: const InputDecoration(
        labelText: 'Пароль',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock),
      ),
      obscureText: true,
      validator: validatePassword,
    );
  }
  
  // Построение поля подтверждения пароля
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: const InputDecoration(
        labelText: 'Подтверждение пароля',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock),
      ),
      obscureText: true,
      validator: (value) => validateConfirmPassword(value, _passwordController.text),
    );
  }
  
  // Построение кнопки регистрации
  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Зарегистрироваться',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

// Миксин для валидации полей формы
mixin ValidationMixin {
  // Валидация имени
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите имя';
    }
    return null;
  }
  
  // Валидация email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите email';
    }
    if (!value.contains('@')) {
      return 'Пожалуйста, введите корректный email';
    }
    return null;
  }
  
  // Валидация пароля
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }
    return null;
  }
  
  // Валидация подтверждения пароля
  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, подтвердите пароль';
    }
    if (value != password) {
      return 'Пароли не совпадают';
    }
    return null;
  }
}
