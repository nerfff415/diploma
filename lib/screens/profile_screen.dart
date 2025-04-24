import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';
import 'reminders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profileData = await _userService.getUserProfile();
      setState(() {
        _profileData = profileData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ошибка: $_errorMessage',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileItem(
                      'Имя',
                      _profileData?['name'] ?? 'Не указано',
                      Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileItem(
                      'Email',
                      _profileData?['email'] ?? 'Не указан',
                      Icons.email,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileItem(
                      'Дата регистрации',
                      _formatDate(_profileData?['createdAt']),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),

                    // Кнопка уведомлений
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Уведомления'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RemindersScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _authService.signOut();
                            if (mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ошибка при выходе: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Выйти'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Не указана';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return 'Не указана';
    }
  }
}
