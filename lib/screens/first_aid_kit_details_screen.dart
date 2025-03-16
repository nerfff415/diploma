import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/first_aid_kit.dart';
import '../models/medication.dart';
import '../services/first_aid_kit_service.dart';
import '../services/medication_service.dart';
import '../services/auth_service.dart';
import '../services/family_group_service.dart';
import 'add_medication_screen.dart';
import 'edit_medication_screen.dart';

class FirstAidKitDetailsScreen extends StatefulWidget {
  final String firstAidKitId;

  const FirstAidKitDetailsScreen({super.key, required this.firstAidKitId});

  @override
  State<FirstAidKitDetailsScreen> createState() =>
      _FirstAidKitDetailsScreenState();
}

class _FirstAidKitDetailsScreenState extends State<FirstAidKitDetailsScreen> {
  final FirstAidKitService _kitService = FirstAidKitService();
  final MedicationService _medicationService = MedicationService();
  final AuthService _authService = AuthService();
  final FamilyGroupService _groupService = FamilyGroupService();

  String _selectedCategory = 'all'; // 'all' означает все категории
  bool _hasAccess =
      false; // Флаг, указывающий, имеет ли пользователь доступ к аптечке

  @override
  void initState() {
    super.initState();
    // Проверяем доступ пользователя к аптечке
    _checkAccess();
  }

  // Метод для проверки доступа пользователя к аптечке
  Future<void> _checkAccess() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _hasAccess = false;
      });
      return;
    }

    try {
      // Получаем аптечку
      final kit = await _kitService.getFirstAidKit(widget.firstAidKitId);
      if (kit == null) {
        setState(() {
          _hasAccess = false;
        });
        return;
      }

      // Проверяем, является ли пользователь владельцем аптечки
      final isOwner = kit.userId == userId;
      if (isOwner) {
        setState(() {
          _hasAccess = true;
        });
        return;
      }

      // Проверяем, имеет ли пользователь доступ к аптечке через группу
      final hasAccessThroughGroup = await _groupService.hasUserAccessToKit(
        userId,
        widget.firstAidKitId,
      );
      setState(() {
        _hasAccess = hasAccessThroughGroup;
      });
    } catch (e) {
      print('Ошибка при проверке доступа: $e');
      setState(() {
        _hasAccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали аптечки'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<FirstAidKit?>(
        future: _kitService.getFirstAidKit(widget.firstAidKitId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final kit = snapshot.data;
          if (kit == null) {
            return const Center(child: Text('Аптечка не найдена'));
          }

          final isOwner = kit.userId == _authService.currentUser?.uid;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информация об аптечке
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              child: const Icon(
                                Icons.medical_services,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kit.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (kit.description != null &&
                                      kit.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(kit.description!),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Создана: ${_formatDate(kit.createdAt)}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.update, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Обновлена: ${_formatDate(kit.updatedAt)}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        if (!isOwner && _hasAccess)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Доступ через группу',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Секция для лекарств
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Лекарства',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOwner ||
                        _hasAccess) // Разрешаем добавлять медикаменты владельцу и участникам группы
                      ElevatedButton.icon(
                        onPressed: () => _navigateToAddMedication(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Фильтр по категориям
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('all', 'Все', Icons.all_inclusive),
                      ...MedicationCategory.values.map(
                        (category) => _buildCategoryChip(
                          category.name,
                          category.name,
                          category.icon,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Список лекарств
                StreamBuilder<List<Medication>>(
                  stream:
                      _selectedCategory == 'all'
                          ? _medicationService.getMedicationsForKit(
                            widget.firstAidKitId,
                          )
                          : _medicationService.getMedicationsByCategory(
                            widget.firstAidKitId,
                            _selectedCategory,
                          ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Ошибка: ${snapshot.error}'));
                    }

                    final medications = snapshot.data ?? [];

                    if (medications.isEmpty) {
                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.medication_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedCategory == 'all'
                                      ? 'В этой аптечке пока нет лекарств'
                                      : 'В категории "${_selectedCategory}" нет лекарств',
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                if (isOwner && _selectedCategory == 'all')
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _navigateToAddMedication(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Добавить лекарство'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: medications.length,
                      itemBuilder: (context, index) {
                        final medication = medications[index];
                        final isExpired = medication.expiryDate.isBefore(
                          DateTime.now(),
                        );
                        final daysUntilExpiry =
                            medication.expiryDate
                                .difference(DateTime.now())
                                .inDays;
                        final isExpiringSoon =
                            daysUntilExpiry <= 30 && daysUntilExpiry > 0;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isExpired
                                      ? Colors.red.shade100
                                      : isExpiringSoon
                                      ? Colors.orange.shade100
                                      : Colors.blue.shade100,
                              child: Icon(
                                medication.formEnum.icon,
                                color:
                                    isExpired
                                        ? Colors.red
                                        : isExpiringSoon
                                        ? Colors.orange
                                        : Colors.blue,
                              ),
                            ),
                            title: Text(
                              medication.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isExpired ? Colors.red : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${medication.formEnum.name} • ${medication.quantityWithDimension}',
                                ),
                                Text(
                                  'Срок годности: ${_formatDate(medication.expiryDate)}',
                                  style: TextStyle(
                                    color:
                                        isExpired
                                            ? Colors.red
                                            : isExpiringSoon
                                            ? Colors.orange
                                            : Colors.grey.shade600,
                                    fontWeight:
                                        isExpired || isExpiringSoon
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            trailing:
                                isOwner
                                    ? IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed:
                                          () => _showMedicationOptions(
                                            context,
                                            medication,
                                          ),
                                    )
                                    : null,
                            onTap:
                                () =>
                                    _showMedicationDetails(context, medication),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Кнопки действий
                if (isOwner) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showEditKitDialog(context, kit),
                        icon: const Icon(Icons.edit),
                        label: const Text('Редактировать'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showDeleteDialog(context, kit),
                        icon: const Icon(Icons.delete),
                        label: const Text('Удалить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Метод для создания чипа категории
  Widget _buildCategoryChip(String value, String label, IconData icon) {
    final isSelected = _selectedCategory == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = value;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // Метод для перехода на экран добавления медикамента
  void _navigateToAddMedication(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(kitId: widget.firstAidKitId),
      ),
    );

    if (result == true) {
      setState(() {
        // Обновление списка медикаментов произойдет автоматически через StreamBuilder
      });
    }
  }

  // Метод для отображения деталей медикамента
  void _showMedicationDetails(BuildContext context, Medication medication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    radius: 24,
                    child: Icon(
                      medication.formEnum.icon,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          medication.formEnum.name,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow(
                Icons.category,
                'Категория',
                medication.categoryEnum.name,
              ),
              _buildDetailRow(
                Icons.format_list_numbered,
                'Количество',
                medication.quantityWithDimension,
              ),
              _buildDetailRow(
                Icons.calendar_today,
                'Срок годности',
                _formatDate(medication.expiryDate),
                isExpired: medication.expiryDate.isBefore(DateTime.now()),
              ),
              if (medication.description != null &&
                  medication.description!.isNotEmpty)
                _buildDetailRow(
                  Icons.description,
                  'Описание',
                  medication.description!,
                ),
              if (medication.barcode != null && medication.barcode!.isNotEmpty)
                _buildDetailRow(
                  Icons.qr_code,
                  'Штрих-код',
                  medication.barcode!,
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Метод для построения строки с деталями
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isExpired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isExpired ? Colors.red : Colors.grey.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isExpired ? Colors.red : null,
                    fontWeight: isExpired ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Метод для отображения опций медикамента (редактирование, удаление)
  void _showMedicationOptions(BuildContext context, Medication medication) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditMedication(context, medication);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Удалить',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteMedicationDialog(context, medication);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Метод для перехода на экран редактирования медикамента
  void _navigateToEditMedication(
    BuildContext context,
    Medication medication,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMedicationScreen(medication: medication),
      ),
    );

    if (result == true) {
      setState(() {
        // Обновление списка медикаментов произойдет автоматически через StreamBuilder
      });
    }
  }

  // Метод для отображения диалога удаления медикамента
  Future<void> _showDeleteMedicationDialog(
    BuildContext context,
    Medication medication,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удаление медикамента'),
            content: Text(
              'Вы уверены, что хотите удалить "${medication.name}"?',
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
        await _medicationService.deleteMedication(medication.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Медикамент удален')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при удалении: $e')));
      }
    }
  }

  // Метод для форматирования даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Метод для отображения диалога редактирования аптечки
  Future<void> _showEditKitDialog(BuildContext context, FirstAidKit kit) async {
    final nameController = TextEditingController(text: kit.name);
    final descriptionController = TextEditingController(
      text: kit.description ?? '',
    );
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Редактирование аптечки'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название аптечки',
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
                                    content: Text('Введите название аптечки'),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                isUpdating = true;
                              });

                              try {
                                final updatedKit = kit.copyWith(
                                  name: nameController.text.trim(),
                                  description:
                                      descriptionController.text
                                              .trim()
                                              .isNotEmpty
                                          ? descriptionController.text.trim()
                                          : null,
                                  updatedAt: DateTime.now(),
                                );

                                await _kitService.updateFirstAidKit(updatedKit);

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Аптечка успешно обновлена',
                                      ),
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
        await _kitService.deleteFirstAidKit(kit.id);
        Navigator.pop(context); // Возвращаемся на предыдущий экран
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
}
