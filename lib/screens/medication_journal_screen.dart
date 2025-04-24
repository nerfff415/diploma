import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/medication.dart';
import '../models/medication_schedule.dart';
import '../services/medication_schedule_service.dart';
import '../services/auth_service.dart';
import 'add_medication_schedule_screen.dart';
import 'report_period_screen.dart';

class MedicationJournalScreen extends StatefulWidget {
  const MedicationJournalScreen({super.key});

  @override
  State<MedicationJournalScreen> createState() =>
      _MedicationJournalScreenState();
}

class _MedicationJournalScreenState extends State<MedicationJournalScreen> {
  final MedicationScheduleService _scheduleService =
      MedicationScheduleService();
  final AuthService _authService = AuthService();

  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late CalendarFormat _calendarFormat;

  Map<DateTime, List<MedicationSchedule>> _events = {};
  List<MedicationSchedule> _selectedEvents = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;

    _loadEvents();
  }

  // Загрузка событий на текущий месяц
  Future<void> _loadEvents() async {
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

      // Получаем первый и последний день месяца
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      // Подписываемся на поток расписаний
      _scheduleService
          .getSchedulesForPeriod(userId, firstDay, lastDay)
          .listen(
            (schedules) {
              if (mounted) {
                setState(() {
                  // Группируем расписания по датам
                  _events = {};
                  for (final schedule in schedules) {
                    final day = DateTime(
                      schedule.date.year,
                      schedule.date.month,
                      schedule.date.day,
                    );

                    if (_events[day] == null) {
                      _events[day] = [];
                    }

                    _events[day]!.add(schedule);
                  }

                  // Обновляем выбранные события
                  _selectedEvents = _getEventsForDay(_selectedDay);
                  _isLoading = false;
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Ошибка при загрузке данных: $error';
                });
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка: $e';
        });
      }
    }
  }

  // Получение событий для выбранного дня
  List<MedicationSchedule> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // Обработка выбора дня в календаре
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  // Обработка изменения месяца
  void _onPageChanged(DateTime focusedDay) {
    // Если месяц изменился, загружаем новые данные
    if (_focusedDay.month != focusedDay.month ||
        _focusedDay.year != focusedDay.year) {
      setState(() {
        _focusedDay = focusedDay;
      });
      _loadEvents();
    }
  }

  // Отметка о приеме лекарства
  Future<void> _markAsTaken(MedicationSchedule schedule) async {
    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.medication,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Text('Подтверждение приема'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Вы собираетесь отметить прием медикамента ',
                      ),
                      TextSpan(
                        text: '"${schedule.medicationName}"',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Из аптечки "${schedule.kitName}" будет списано ${schedule.dosage} ${schedule.dimension}.',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Подтвердите действие.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Подтвердить'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _scheduleService.markAsTaken(schedule.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Отмечено как принято')));
      }
    } catch (e) {
      if (mounted) {
        // Проверяем, связана ли ошибка с недостаточным количеством медикамента
        if (e.toString().contains('Недостаточное количество медикамента')) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      const Text('Недостаточно медикамента'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'В аптечке '),
                            TextSpan(
                              text: '"${schedule.kitName}"',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' недостаточно медикамента '),
                            TextSpan(
                              text: '"${schedule.medicationName}"',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' для списания.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Пожалуйста, обновите количество медикамента в аптечке или измените дозировку в расписании.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Понятно'),
                    ),
                  ],
                ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      }
    }
  }

  // Отмена отметки о приеме лекарства
  Future<void> _markAsNotTaken(MedicationSchedule schedule) async {
    try {
      await _scheduleService.markAsNotTaken(schedule.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Отметка отменена')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  // Удаление расписания
  Future<void> _deleteSchedule(MedicationSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удаление записи'),
            content: Text(
              'Вы уверены, что хотите удалить запись о приеме "${schedule.medicationName}"?',
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

    if (confirmed == true) {
      try {
        await _scheduleService.deleteSchedule(schedule.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Запись удалена')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при удалении: $e')));
      }
    }
  }

  // Переход на экран добавления расписания
  void _navigateToAddSchedule() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AddMedicationScheduleScreen(selectedDate: _selectedDay),
      ),
    );

    if (result == true) {
      // Обновление произойдет автоматически через Stream
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал приема'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка добавления нового приема в AppBar
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddSchedule,
            tooltip: 'Добавить прием',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportPeriodScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Выгрузить отчет'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                children: [
                  // Календарь
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    onPageChanged: _onPageChanged,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 3,
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonDecoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      formatButtonTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const Divider(),

                  // Заголовок для выбранного дня
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Прием лекарств на ${DateFormat('dd.MM.yyyy').format(_selectedDay)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _navigateToAddSchedule,
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить'),
                        ),
                      ],
                    ),
                  ),

                  // Список расписаний на выбранный день
                  Expanded(
                    child:
                        _selectedEvents.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'На этот день нет запланированных приемов',
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _navigateToAddSchedule,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Добавить прием'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _selectedEvents.length,
                              itemBuilder: (context, index) {
                                final schedule = _selectedEvents[index];
                                final isPast = schedule.date.isBefore(
                                  DateTime.now(),
                                );

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          schedule.taken
                                              ? Colors.green.shade100
                                              : isPast
                                              ? Colors.red.shade100
                                              : Colors.blue.shade100,
                                      child: Icon(
                                        schedule.taken
                                            ? Icons.check
                                            : isPast
                                            ? Icons.warning
                                            : Icons.access_time,
                                        color:
                                            schedule.taken
                                                ? Colors.green
                                                : isPast
                                                ? Colors.red
                                                : Colors.blue,
                                      ),
                                    ),
                                    title: Text(
                                      schedule.medicationName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration:
                                            schedule.taken
                                                ? TextDecoration.lineThrough
                                                : null,
                                        color:
                                            schedule.taken ? Colors.grey : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Доза: ${schedule.dosage} ${schedule.dimension}',
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Аптечка: ${schedule.kitName}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (schedule.taken &&
                                            schedule.takenAt != null)
                                          Text(
                                            'Принято: ${DateFormat('dd.MM.yyyy HH:mm').format(schedule.takenAt!)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      itemBuilder:
                                          (context) => [
                                            if (!schedule.taken)
                                              PopupMenuItem(
                                                value: 'take',
                                                child: const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.check,
                                                      color: Colors.green,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Отметить как принятое',
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              PopupMenuItem(
                                                value: 'untake',
                                                child: const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.close,
                                                      color: Colors.orange,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Отменить отметку'),
                                                  ],
                                                ),
                                              ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Удалить'),
                                                ],
                                              ),
                                            ),
                                          ],
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'take':
                                            _markAsTaken(schedule);
                                            break;
                                          case 'untake':
                                            _markAsNotTaken(schedule);
                                            break;
                                          case 'delete':
                                            _deleteSchedule(schedule);
                                            break;
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
