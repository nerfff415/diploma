import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/family_group_service.dart';
import '../services/auth_service.dart';
import '../models/family_group.dart';
import 'family_group_details_screen.dart';
import 'join_group_screen.dart';

class FamilyGroupsScreen extends StatefulWidget {
  const FamilyGroupsScreen({Key? key}) : super(key: key);

  @override
  State<FamilyGroupsScreen> createState() => _FamilyGroupsScreenState();
}

class _FamilyGroupsScreenState extends State<FamilyGroupsScreen> {
  final FamilyGroupService _groupService = FamilyGroupService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Необходимо авторизоваться'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Семейные группы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => _navigateToJoinGroup(context),
            tooltip: 'Присоединиться к группе',
          ),
        ],
      ),
      body: StreamBuilder<List<FamilyGroup>>(
        stream: _groupService.getUserGroups(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'У вас пока нет семейных групп',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateGroupDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Создать группу'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _navigateToJoinGroup(context),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Присоединиться к группе'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _buildGroupCard(context, group);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, FamilyGroup group) {
    final isAdmin = group.adminId == _authService.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToGroupDetails(context, group),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: Icon(Icons.group, color: Colors.red.shade800),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isAdmin)
                          const Text(
                            'Администратор',
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => _navigateToGroupDetails(context, group),
                  ),
                ],
              ),
              if (group.description != null && group.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 56),
                  child: Text(
                    group.description!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGroupDetails(BuildContext context, FamilyGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyGroupDetailsScreen(group: group),
      ),
    );
  }

  void _navigateToJoinGroup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const JoinGroupScreen()),
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isCreating = false;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Создание семейной группы'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название группы',
                          hintText: 'Например: Семья Ивановых',
                        ),
                        maxLength: 50,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание (необязательно)',
                          hintText: 'Краткое описание группы',
                        ),
                        maxLength: 200,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  ElevatedButton(
                    onPressed:
                        isCreating
                            ? null
                            : () async {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Введите название группы'),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                isCreating = true;
                              });

                              try {
                                final userId = _authService.currentUser!.uid;
                                await _groupService.createFamilyGroup(
                                  name: nameController.text.trim(),
                                  adminId: userId,
                                  description:
                                      descriptionController.text
                                              .trim()
                                              .isNotEmpty
                                          ? descriptionController.text.trim()
                                          : null,
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Группа успешно создана'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() {
                                  isCreating = false;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')),
                                );
                              }
                            },
                    child:
                        isCreating
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Создать'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
