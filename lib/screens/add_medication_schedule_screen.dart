import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication.dart';
import '../models/first_aid_kit.dart';
import '../services/medication_schedule_service.dart';
import '../services/auth_service.dart';
import '../services/first_aid_kit_service.dart';
import '../models/medication_schedule.dart';
import '../services/notification_settings_service.dart';
import '../models/notification_settings.dart';

class AddMedicationScheduleScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddMedicationScheduleScreen({super.key, required this.selectedDate});

  @override
  State<AddMedicationScheduleScreen> createState() =>
      _AddMedicationScheduleScreenState();
}

class _AddMedicationScheduleScreenState
    extends State<AddMedicationScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicationScheduleService _scheduleService =
      MedicationScheduleService();
  final AuthService _authService = AuthService();
  final FirstAidKitService _kitService = FirstAidKitService();
  final NotificationSettingsService _notificationSettingsService =
      NotificationSettingsService();

  List<Medication> _availableMedications = [];
  Map<String, String> _kitNames = {}; // Словарь для хранения названий аптечек
  Medication? _selectedMedication;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedDimension = 'шт';

  // Настройки уведомлений
  bool _notificationEnabled = true;
  int _notificationMinutesBefore = 30;
  List<int> _availableNotificationTimes = [
    15,
    30,
    60,
    120,
    240,
  ]; // 15 мин, 30 мин, 1 час, 2 часа, 4 часа

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _loadAvailableMedications();
    _loadDefaultNotificationSettings();
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Загрузка настроек уведомлений по умолчанию
  Future<void> _loadDefaultNotificationSettings() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final settings = await _notificationSettingsService.getUserSettings(
        userId,
      );
      if (settings != null) {
        setState(() {
          _notificationEnabled = settings.medicationReminders;
          _notificationMinutesBefore = settings.reminderTime;
        });
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке настроек уведомлений: $e');
    }
  }

  // Загрузка доступных медикаментов
  Future<void> _loadAvailableMedications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Необходимо войти в систему';
        });
        return;
      }

      final medications = await _scheduleService.getAvailableMedications(
        userId,
      );

      // Загружаем названия аптечек
      final kitIds = medications.map((m) => m.kitId).toSet().toList();
      _kitNames = {};

      for (final kitId in kitIds) {
        try {
          final kit = await _kitService.getFirstAidKit(kitId);
          if (kit != null) {
            _kitNames[kitId] = kit.name;
          }
        } catch (e) {
          debugPrint('Ошибка при загрузке аптечки $kitId: $e');
        }
      }

      setState(() {
        _availableMedications = medications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка при загрузке медикаментов: $e';
      });
    }
  }

  // Выбор даты
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Выбор времени
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Отображение диалога настроек уведомлений
  Future<void> _showNotificationSettingsDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Настройки уведомления'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Включить уведомление'),
                      value: _notificationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_notificationEnabled) ...[
                      const Text('Уведомить за:'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _notificationMinutesBefore,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        items:
                            _availableNotificationTimes.map((minutes) {
                              String text;
                              if (minutes < 60) {
                                text = '$minutes минут';
                              } else {
                                text =
                                    '${minutes ~/ 60} ${minutes == 60 ? 'час' : 'часа'}';
                              }
                              return DropdownMenuItem<int>(
                                value: minutes,
                                child: Text(text),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _notificationMinutesBefore = value;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.pop(context, {
                          'enabled': _notificationEnabled,
                          'minutesBefore': _notificationMinutesBefore,
                        }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Сохранить'),
                  ),
                ],
              );
            },
          ),
    );

    if (result != null) {
      setState(() {
        _notificationEnabled = result['enabled'];
        _notificationMinutesBefore = result['minutesBefore'];
      });
    }
  }

  // Сохранение расписания
  Future<void> _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMedication == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Выберите медикамент')));
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final userId = _authService.currentUser?.uid;
        if (userId == null) {
          setState(() {
            _isSaving = false;
            _errorMessage = 'Необходимо войти в систему';
          });
          return;
        }

        // Создаем новое расписание
        final schedule = MedicationSchedule.create(
          userId: userId,
          medicationId: _selectedMedication!.id,
          medicationName: _selectedMedication!.name,
          kitId: _selectedMedication!.kitId,
          kitName: _kitNames[_selectedMedication!.kitId] ?? 'Аптечка',
          date: _selectedDate,
          time: _selectedTime,
          dosage: double.parse(_dosageController.text),
          dimension: _selectedDimension,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
          notificationEnabled: _notificationEnabled,
          notificationMinutesBefore: _notificationMinutesBefore,
        );

        // Сохраняем расписание
        final scheduleId = await _scheduleService.createSchedule(schedule);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Прием добавлен в расписание')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить прием'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _availableMedications.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.medication_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'У вас нет доступных медикаментов',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Добавьте медикаменты в аптечку или присоединитесь к группе',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Вернуться'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Выбор медикамента
                      const Text(
                        'Выберите медикамент:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Medication>(
                        value: _selectedMedication,
                        decoration: const InputDecoration(
                          labelText: 'Медикамент',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          isCollapsed: false,
                        ),
                        itemHeight: 70,
                        hint: const Text('Выберите медикамент'),
                        items:
                            _availableMedications
                                .map(
                                  (medication) => DropdownMenuItem<Medication>(
                                    value: medication,
                                    child: Container(
                                      height: 40,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${medication.name} (${medication.formEnum.name})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Аптечка: ${_kitNames[medication.kitId] ?? 'Неизвестная аптечка'} • Осталось: ${medication.quantity} ${medication.dimension}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMedication = value;
                            if (value != null) {
                              _selectedDimension = value.dimension;
                              _dosageController.text =
                                  value.quantity.toString();
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Выберите медикамент';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Выбор даты и времени
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Дата приема:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today),
                                        const SizedBox(width: 12),
                                        Text(
                                          DateFormat(
                                            'dd.MM.yyyy',
                                          ).format(_selectedDate),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Время приема:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _selectTime(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time),
                                        const SizedBox(width: 12),
                                        Text(
                                          _selectedTime.format(context),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Дозировка
                      const Text(
                        'Дозировка:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _dosageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Количество',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Введите дозировку';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Введите число';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _selectedDimension,
                              decoration: const InputDecoration(
                                labelText: 'Ед. изм.',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  [
                                    'мг',
                                    'г',
                                    'мкг',
                                    'мл',
                                    'л',
                                    'шт',
                                    'табл',
                                    'кап',
                                    'ед',
                                  ].map((dimension) {
                                    return DropdownMenuItem<String>(
                                      value: dimension,
                                      child: Text(dimension),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedDimension = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Настройки уведомлений
                      const Text(
                        'Уведомление:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _notificationEnabled
                                  ? Icons.notifications_active
                                  : Icons.notifications_off,
                              color:
                                  _notificationEnabled
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _notificationEnabled
                                    ? 'Уведомление за ${_notificationMinutesBefore < 60 ? "$_notificationMinutesBefore минут" : "${_notificationMinutesBefore ~/ 60} ${_notificationMinutesBefore == 60 ? "час" : "часа"}"}'
                                    : 'Уведомление отключено',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            TextButton(
                              onPressed: _showNotificationSettingsDialog,
                              child: const Text('Настроить'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Заметки
                      const Text(
                        'Заметки (необязательно):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Например: принимать после еды',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Кнопка сохранения
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Добавить в расписание',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
