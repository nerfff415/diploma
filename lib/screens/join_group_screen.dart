import 'package:flutter/material.dart';
import '../services/family_group_service.dart';
import '../services/auth_service.dart';
import '../models/access_code.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({Key? key}) : super(key: key);

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final FamilyGroupService _groupService = FamilyGroupService();
  final AuthService _authService = AuthService();

  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Присоединиться к группе')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Введите код доступа, который вам предоставил администратор группы:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Код доступа',
                hintText: 'Например: FAM-ABCD-1234',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (value) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isJoining ? null : _joinGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isJoining
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Присоединиться',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Или создайте свою группу',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Здесь можно добавить логику для перехода к созданию группы
              },
              icon: const Icon(Icons.add),
              label: const Text('Создать новую группу'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinGroup() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Введите код доступа';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser?.uid;

      if (userId == null) {
        setState(() {
          _isJoining = false;
          _errorMessage = 'Необходимо авторизоваться';
        });
        return;
      }

      // Проверяем код доступа
      final accessCode = await _groupService.validateAccessCode(code);

      if (accessCode == null) {
        setState(() {
          _isJoining = false;
          _errorMessage = 'Недействительный код доступа';
        });
        return;
      }

      if (!accessCode.isValid) {
        setState(() {
          _isJoining = false;
          _errorMessage = 'Срок действия кода истек';
        });
        return;
      }

      if (accessCode.type == AccessCodeType.group &&
          accessCode.groupId != null) {
        // Присоединяемся к группе
        final success = await _groupService.joinGroupByCode(code, userId);

        if (success) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Запрос на присоединение отправлен'),
              ),
            );
          }
        } else {
          setState(() {
            _isJoining = false;
            _errorMessage = 'Не удалось присоединиться к группе';
          });
        }
      } else {
        setState(() {
          _isJoining = false;
          _errorMessage = 'Этот код не предназначен для присоединения к группе';
        });
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
        _errorMessage = 'Ошибка: $e';
      });
    }
  }
}
