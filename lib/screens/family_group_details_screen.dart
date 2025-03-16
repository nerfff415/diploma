import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/family_group_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/family_group.dart';
import '../models/group_member.dart';
import '../models/user_profile.dart';
import '../services/first_aid_kit_service.dart';
import '../models/first_aid_kit.dart';
import 'first_aid_kit_details_screen.dart';

class FamilyGroupDetailsScreen extends StatefulWidget {
  final FamilyGroup group;

  const FamilyGroupDetailsScreen({Key? key, required this.group})
    : super(key: key);

  @override
  State<FamilyGroupDetailsScreen> createState() =>
      _FamilyGroupDetailsScreenState();
}

class _FamilyGroupDetailsScreenState extends State<FamilyGroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  final FamilyGroupService _groupService = FamilyGroupService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  late TabController _tabController;
  String? _accessCode;
  bool _isGeneratingCode = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isAdmin = widget.group.adminId == _authService.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Участники'), Tab(text: 'Аптечки')],
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditGroupDialog(context),
              tooltip: 'Редактировать группу',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareDialog(context),
            tooltip: 'Поделиться',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMembersTab(), _buildKitsTab()],
      ),
    );
  }

  Widget _buildMembersTab() {
    return StreamBuilder<List<GroupMember>>(
      stream: _groupService.getGroupMembers(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return const Center(child: Text('В группе нет участников'));
        }

        return FutureBuilder<List<UserProfile>>(
          future: _groupService.getGroupMembersProfiles(widget.group.id),
          builder: (context, profilesSnapshot) {
            if (profilesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final profiles = profilesSnapshot.data ?? [];

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final profile = profiles.firstWhere(
                  (p) => p.userId == member.userId,
                  orElse:
                      () => UserProfile(
                        userId: member.userId,
                        firstName: '',
                        lastName: '',
                        email: '',
                      ),
                );

                return _buildMemberCard(context, member, profile);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    GroupMember member,
    UserProfile profile,
  ) {
    final isCurrentUser = member.userId == _authService.currentUser?.uid;
    final isAdmin = member.role == MemberRole.admin;
    final isPending = member.status == MemberStatus.pending;

    String roleName = '';
    Color roleColor = Colors.grey;

    switch (member.role) {
      case MemberRole.admin:
        roleName = 'Администратор';
        roleColor = Colors.red;
        break;
      case MemberRole.editor:
        roleName = 'Редактор';
        roleColor = Colors.blue;
        break;
      case MemberRole.viewer:
        roleName = 'Наблюдатель';
        roleColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Text(
            _getInitials(profile),
            style: TextStyle(
              color: Colors.red.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${profile.firstName} ${profile.lastName}',
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile.email, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: roleColor),
                  ),
                  child: Text(
                    roleName,
                    style: TextStyle(color: roleColor, fontSize: 12),
                  ),
                ),
                if (isPending)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'Ожидает подтверждения',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing:
            _isAdmin && !isCurrentUser
                ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'admin':
                        _updateMemberRole(member, MemberRole.admin);
                        break;
                      case 'editor':
                        _updateMemberRole(member, MemberRole.editor);
                        break;
                      case 'viewer':
                        _updateMemberRole(member, MemberRole.viewer);
                        break;
                      case 'approve':
                        _updateMemberStatus(member, MemberStatus.active);
                        break;
                      case 'remove':
                        _showRemoveMemberDialog(context, member, profile);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        if (isPending)
                          const PopupMenuItem(
                            value: 'approve',
                            child: Text('Подтвердить'),
                          ),
                        const PopupMenuItem(
                          value: 'admin',
                          child: Text('Сделать администратором'),
                        ),
                        const PopupMenuItem(
                          value: 'editor',
                          child: Text('Сделать редактором'),
                        ),
                        const PopupMenuItem(
                          value: 'viewer',
                          child: Text('Сделать наблюдателем'),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Удалить из группы'),
                        ),
                      ],
                )
                : null,
      ),
    );
  }

  Widget _buildKitsTab() {
    return FutureBuilder<List<String>>(
      future: _groupService.getGroupKits(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final kitIds = snapshot.data ?? [];

        if (kitIds.isEmpty) {
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
                  'В группе нет аптечек',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _showAddKitDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить аптечку'),
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

        // Получаем информацию о каждой аптечке
        final firstAidKitService = FirstAidKitService();
        return FutureBuilder<List<FirstAidKit>>(
          future: firstAidKitService.getFirstAidKitsByIds(kitIds),
          builder: (context, kitsSnapshot) {
            if (kitsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (kitsSnapshot.hasError) {
              return Center(child: Text('Ошибка: ${kitsSnapshot.error}'));
            }

            final kits = kitsSnapshot.data ?? [];

            return Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: kits.length,
                  itemBuilder: (context, index) {
                    final kit = kits[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: const Icon(
                            Icons.medical_services,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          kit.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            kit.description != null &&
                                    kit.description!.isNotEmpty
                                ? Text(kit.description!)
                                : null,
                        trailing:
                            _isAdmin
                                ? IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed:
                                      () =>
                                          _showRemoveKitDialog(context, kit.id),
                                )
                                : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => FirstAidKitDetailsScreen(
                                    firstAidKitId: kit.id,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                if (_isAdmin)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: () => _showAddKitDialog(context),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.add),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showShareDialog(BuildContext context) async {
    setState(() {
      _isGeneratingCode = true;
    });

    try {
      final userId = _authService.currentUser!.uid;
      final code = await _groupService.createGroupAccessCode(
        widget.group.id,
        userId,
      );

      setState(() {
        _accessCode = code;
        _isGeneratingCode = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Пригласить в группу'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Поделитесь этим кодом с человеком, которого хотите пригласить в группу:',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _accessCode!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _accessCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Код скопирован в буфер обмена',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Код действителен в течение 7 дней.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingCode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при создании кода доступа: $e')),
      );
    }
  }

  Future<void> _showEditGroupDialog(BuildContext context) async {
    final nameController = TextEditingController(text: widget.group.name);
    final descriptionController = TextEditingController(
      text: widget.group.description ?? '',
    );
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Редактирование группы'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название группы',
                        ),
                        maxLength: 50,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание (необязательно)',
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
                        isUpdating
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
                                isUpdating = true;
                              });

                              try {
                                final updatedGroup = widget.group.copyWith(
                                  name: nameController.text.trim(),
                                  description:
                                      descriptionController.text
                                              .trim()
                                              .isNotEmpty
                                          ? descriptionController.text.trim()
                                          : null,
                                );

                                await _groupService.updateFamilyGroup(
                                  updatedGroup,
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Группа успешно обновлена'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() {
                                  isUpdating = false;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')),
                                );
                              }
                            },
                    child:
                        isUpdating
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Сохранить'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _showRemoveMemberDialog(
    BuildContext context,
    GroupMember member,
    UserProfile profile,
  ) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удаление участника'),
            content: Text(
              'Вы уверены, что хотите удалить ${profile.firstName} ${profile.lastName} из группы?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _groupService.removeMemberFromGroup(
                      member.groupId,
                      member.userId,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Участник удален из группы'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );
  }

  Future<void> _showAddKitDialog(BuildContext context) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Необходимо авторизоваться')),
      );
      return;
    }

    // Получаем список аптечек пользователя
    final firstAidKitService = FirstAidKitService();
    List<FirstAidKit> userKits = [];

    try {
      // Получаем текущие аптечки группы
      final groupKitIds = await _groupService.getGroupKits(widget.group.id);

      // Получаем все аптечки пользователя
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StreamBuilder<List<FirstAidKit>>(
            stream: firstAidKitService.getUserFirstAidKits(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AlertDialog(
                  content: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return AlertDialog(
                  title: const Text('Ошибка'),
                  content: Text(
                    'Не удалось загрузить аптечки: ${snapshot.error}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Закрыть'),
                    ),
                  ],
                );
              }

              userKits = snapshot.data ?? [];

              // Фильтруем аптечки, которые уже добавлены в группу
              final availableKits =
                  userKits
                      .where((kit) => !groupKitIds.contains(kit.id))
                      .toList();

              if (availableKits.isEmpty) {
                return AlertDialog(
                  title: const Text('Добавление аптечки'),
                  content: const Text(
                    'У вас нет аптечек, которые можно добавить в эту группу. '
                    'Все ваши аптечки уже добавлены или вам нужно создать новую аптечку.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Закрыть'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Здесь можно добавить переход на экран создания аптечки
                      },
                      child: const Text('Создать аптечку'),
                    ),
                  ],
                );
              }

              return AlertDialog(
                title: const Text('Добавление аптечки'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableKits.length,
                    itemBuilder: (context, index) {
                      final kit = availableKits[index];
                      return ListTile(
                        title: Text(kit.name),
                        subtitle: Text(kit.description ?? ''),
                        onTap: () async {
                          try {
                            await _groupService.addKitToGroup(
                              widget.group.id,
                              kit.id,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Аптечка добавлена в группу'),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ошибка при добавлении аптечки: $e',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _showRemoveKitDialog(BuildContext context, String kitId) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удаление аптечки'),
            content: const Text(
              'Вы уверены, что хотите удалить эту аптечку из группы?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _groupService.removeKitFromGroup(
                      widget.group.id,
                      kitId,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Аптечка удалена из группы'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );
  }

  void _updateMemberRole(GroupMember member, MemberRole role) async {
    try {
      await _groupService.updateMemberRole(member.groupId, member.userId, role);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Роль участника обновлена')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _updateMemberStatus(GroupMember member, MemberStatus status) async {
    try {
      await _groupService.updateMemberStatus(
        member.groupId,
        member.userId,
        status,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Статус участника обновлен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  String _getInitials(UserProfile profile) {
    if (profile.firstName.isEmpty && profile.lastName.isEmpty) {
      return '?';
    }

    String initials = '';

    if (profile.firstName.isNotEmpty) {
      initials += profile.firstName[0];
    }

    if (profile.lastName.isNotEmpty) {
      initials += profile.lastName[0];
    }

    return initials.toUpperCase();
  }
}
