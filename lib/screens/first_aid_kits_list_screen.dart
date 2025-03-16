import 'package:flutter/material.dart';
import '../models/first_aid_kit.dart';
import '../services/first_aid_kit_service.dart';
import '../services/auth_service.dart';
import 'add_first_aid_kit_screen.dart';
import 'first_aid_kit_details_screen.dart';

class FirstAidKitsListScreen extends StatefulWidget {
  const FirstAidKitsListScreen({super.key});

  @override
  State<FirstAidKitsListScreen> createState() => _FirstAidKitsListScreenState();
}

class _FirstAidKitsListScreenState extends State<FirstAidKitsListScreen> {
  final FirstAidKitService _service = FirstAidKitService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Мои аптечки'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Необходимо авторизоваться')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои аптечки'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<FirstAidKit>>(
        stream: _service.getUserFirstAidKits(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final kits = snapshot.data ?? [];

          if (kits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'У вас пока нет аптечек',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddKit(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Создать аптечку'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kits.length,
            itemBuilder: (context, index) {
              final kit = kits[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.red,
                    ),
                  ),
                  title: Text(
                    kit.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kit.description != null &&
                          kit.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(kit.description!),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Создана: ${_formatDate(kit.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _navigateToKitDetails(context, kit.id),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(context, kit),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddKit(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Метод для выхода из аккаунта
  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      // Навигация на экран входа выполнится автоматически через AuthWrapper
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при выходе: $e')));
      }
    }
  }

  // Метод для перехода на экран создания аптечки
  void _navigateToAddKit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFirstAidKitScreen()),
    );
  }

  // Метод для перехода на экран деталей аптечки
  void _navigateToKitDetails(BuildContext context, String kitId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirstAidKitDetailsScreen(firstAidKitId: kitId),
      ),
    );
  }

  // Метод для отображения диалога удаления аптечки
  Future<void> _showDeleteDialog(BuildContext context, FirstAidKit kit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удаление аптечки'),
            content: Text(
              'Вы уверены, что хотите удалить аптечку "${kit.name}"?',
            ),
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
                child: const Text('Удалить'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.deleteFirstAidKit(kit.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Аптечка удалена')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при удалении аптечки: $e')),
        );
      }
    }
  }

  // Метод для форматирования даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
