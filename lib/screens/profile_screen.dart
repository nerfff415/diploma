import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';
import 'reminders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;

  // Контроллеры для полей формы
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Загрузка профиля пользователя
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final profile = await _userService.getUserProfile(userId);

        setState(() {
          _userProfile = profile;

          // Если профиль существует, заполняем поля формы
          if (profile != null) {
            _firstNameController.text = profile.firstName;
            _lastNameController.text = profile.lastName;
            _middleNameController.text = profile.middleName ?? '';
            _phoneController.text = profile.phoneNumber ?? '';
            _birthDate = profile.birthDate;
          } else {
            // Если профиля нет, создаем базовый с email
            _userService.createUserProfile(
              userId,
              _authService.currentUser?.email ?? '',
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки профиля: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Сохранение профиля
  Future<void> _saveProfile() async {
    if (_authService.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser!.uid;
      final email = _authService.currentUser!.email ?? '';

      // Создаем новый профиль или обновляем существующий
      final updatedProfile = UserProfile(
        userId: userId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        middleName:
            _middleNameController.text.isEmpty
                ? null
                : _middleNameController.text,
        phoneNumber:
            _phoneController.text.isEmpty ? null : _phoneController.text,
        birthDate: _birthDate,
        email: email,
        createdAt: _userProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _userService.updateUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
        _isEditing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Профиль успешно обновлен')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении профиля: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Выбор даты рождения
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _isEditing ? _buildEditForm() : _buildProfileView(),
              ),
    );
  }

  // Виджет для просмотра профиля
  Widget _buildProfileView() {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.red.shade100,
            child: Text(
              _getInitials(),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Имя и фамилия
        Center(
          child: Text(
            '${_userProfile?.firstName} ${_userProfile?.lastName}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        if (_userProfile?.middleName != null &&
            _userProfile!.middleName!.isNotEmpty)
          Center(
            child: Text(
              _userProfile!.middleName!,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 32),
        const Divider(),

        // Email
        _buildInfoRow(
          icon: Icons.email,
          title: 'Email',
          value: _userProfile?.email ?? '',
        ),

        // Телефон
        if (_userProfile?.phoneNumber != null &&
            _userProfile!.phoneNumber!.isNotEmpty)
          _buildInfoRow(
            icon: Icons.phone,
            title: 'Телефон',
            value: _userProfile!.phoneNumber!,
          ),

        // Дата рождения
        if (_userProfile?.birthDate != null)
          _buildInfoRow(
            icon: Icons.cake,
            title: 'Дата рождения',
            value: dateFormat.format(_userProfile!.birthDate!),
          ),

        const SizedBox(height: 32),
        const Divider(),

        // Настройки
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Настройки',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Уведомления
        ListTile(
          leading: const Icon(Icons.notifications, color: Colors.red),
          title: const Text('Уведомления'),
          subtitle: const Text(
            'Просмотр напоминаний о приеме, сроках годности и запасах',
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RemindersScreen()),
            );
          },
        ),

        // Выход из аккаунта
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Выйти из аккаунта'),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Выход из аккаунта'),
                    content: const Text('Вы уверены, что хотите выйти?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Выйти'),
                      ),
                    ],
                  ),
            );

            if (confirmed == true) {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            }
          },
        ),
      ],
    );
  }

  // Виджет для редактирования профиля
  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Имя
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Фамилия
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Фамилия',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Отчество
        TextFormField(
          controller: _middleNameController,
          decoration: const InputDecoration(
            labelText: 'Отчество (необязательно)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Телефон
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Телефон',
            border: OutlineInputBorder(),
            prefixText: '+7 ',
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Дата рождения
        InkWell(
          onTap: _selectBirthDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Дата рождения',
              border: OutlineInputBorder(),
            ),
            child: Text(
              _birthDate != null
                  ? DateFormat('dd.MM.yyyy').format(_birthDate!)
                  : 'Выберите дату',
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Кнопки действий
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Отменяем изменения и возвращаем исходные значения
                  if (_userProfile != null) {
                    _firstNameController.text = _userProfile!.firstName;
                    _lastNameController.text = _userProfile!.lastName;
                    _middleNameController.text = _userProfile!.middleName ?? '';
                    _phoneController.text = _userProfile!.phoneNumber ?? '';
                    _birthDate = _userProfile!.birthDate;
                  }
                  _isEditing = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
              ),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ],
    );
  }

  // Вспомогательный виджет для отображения информации
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.red),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  // Получение инициалов для аватара
  String _getInitials() {
    if (_userProfile == null) return '';

    String initials = '';

    if (_userProfile!.firstName.isNotEmpty) {
      initials += _userProfile!.firstName[0];
    }

    if (_userProfile!.lastName.isNotEmpty) {
      initials += _userProfile!.lastName[0];
    }

    return initials.toUpperCase();
  }
}
