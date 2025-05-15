import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (!_formKey.currentState!.validate()) return;
    
    _setLoadingState(true);
    
    _executeAuthentication()
      .then(_onAuthenticationSuccess)
      .catchError(_onAuthenticationError)
      .whenComplete(() {
        if (mounted) _setLoadingState(false);
      });
  }
  
  void _setLoadingState(bool isLoading) {
    setState(() => _isLoading = isLoading);
  }
  
  Future<void> _executeAuthentication() async {
    return _authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }
  
  void _onAuthenticationSuccess(_) {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
  
  void _onAuthenticationError(dynamic error) {
    if (!mounted) return;
    
    final errorMessage = _extractErrorMessage(error);
    
    _showErrorDialog(errorMessage);
  }
  
  String _extractErrorMessage(dynamic error) {
    String message = error.toString();
    if (message.startsWith('Exception: ')) {
      message = message.substring(10);
    }
    return message;
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка входа'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_shouldOfferPasswordReset(message)) {
                _showResetPasswordDialog();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  bool _shouldOfferPasswordReset(String errorMessage) {
    return errorMessage.contains('email') || 
           errorMessage.contains('пароль') ||
           errorMessage.contains('найден');
  }

  void _showResetPasswordDialog() {
    final email = _emailController.text.trim();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановление пароля'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Отправить инструкции по восстановлению на email:'),
            const SizedBox(height: 8),
            Text(email),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => _executePasswordReset(email),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
  
  void _executePasswordReset(String email) {
    _authService.resetPassword(email)
      .then((_) => _onPasswordResetSuccess())
      .catchError((e) => _onPasswordResetError(e));
  }
  
  void _onPasswordResetSuccess() {
    if (!mounted) return;
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Инструкции по восстановлению отправлены на ваш email'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _onPasswordResetError(dynamic error) {
    if (!mounted) return;
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка при отправке инструкций: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }
  
  void _navigateToRegistration() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingIndicator() : _buildLoginForm(),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Вход в систему'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }
  
  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            _buildLogo(),
            const SizedBox(height: 24),
            _buildWelcomeText(),
            const SizedBox(height: 32),
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 24),
            _buildLoginButton(),
            const SizedBox(height: 16),
            _buildRegisterLink(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    return const Icon(
      Icons.medical_services,
      size: 80,
      color: Colors.red,
    );
  }
  
  Widget _buildWelcomeText() {
    return Column(
      children: const [
        Text(
          'Добро пожаловать!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Войдите в свой аккаунт',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmail,
    );
  }
  
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите email';
    }
    if (!value.contains('@')) {
      return 'Пожалуйста, введите корректный email';
    }
    return null;
  }
  
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Пароль',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: _togglePasswordVisibility,
        ),
      ),
      obscureText: _obscurePassword,
      validator: _validatePassword,
    );
  }
  
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите пароль';
    }
    return null;
  }
  
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _signIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Войти',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
  
  Widget _buildRegisterLink() {
    return TextButton(
      onPressed: _navigateToRegistration,
      child: const Text('Нет аккаунта? Зарегистрироваться'),
    );
  }
}
