import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication_reminder.dart';
import '../models/expiry_reminder.dart';
import '../models/stock_notification.dart';
import '../services/reminder_service.dart';
import '../services/auth_service.dart';
import '../services/medication_service.dart';
import '../services/stock_notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  final ReminderService _reminderService = ReminderService();
  final AuthService _authService = AuthService();
  final MedicationService _medicationService = MedicationService();
  final StockNotificationService _stockNotificationService =
      StockNotificationService();

  late TabController _tabController;
  Stream<List<MedicationReminder>>? _medicationRemindersStream;
  Stream<List<ExpiryReminder>>? _expiryRemindersStream;
  Stream<List<StockNotification>>? _stockNotificationsStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReminders() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // Проверяем и создаем уведомления
    await _reminderService.checkAndCreateMedicationReminders(userId);
    await _reminderService.checkAndCreateExpiryReminders(userId);

    if (mounted) {
      setState(() {
        _medicationRemindersStream = _reminderService
            .getUserMedicationReminders(userId);
        _expiryRemindersStream = _reminderService.getUserExpiryReminders(
          userId,
        );
        _stockNotificationsStream = _stockNotificationService
            .getUserStockNotifications(userId);
        _isLoading = false;
      });
    }
  }

  Future<void> _markMedicationReminderAsRead(
    MedicationReminder reminder,
  ) async {
    try {
      await _reminderService.markMedicationReminderAsRead(reminder.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Уведомление отмечено как прочитанное')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _markExpiryReminderAsRead(ExpiryReminder reminder) async {
    try {
      await _reminderService.markExpiryReminderAsRead(reminder.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Уведомление отмечено как прочитанное')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _navigateToMedicationDetails(
    String medicationId,
    String kitId,
  ) async {
    try {
      final medication = await _medicationService.getMedicationById(
        medicationId,
      );
      if (medication == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Медикамент не найден')));
        return;
      }

      // Здесь можно добавить навигацию к деталям медикамента, когда будет создан соответствующий экран
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Просмотр деталей медикамента')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Прием лекарств'),
            Tab(text: 'Срок годности'),
            Tab(text: 'Запасы'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // Вкладка с уведомлениями о приеме лекарств
                  _buildMedicationRemindersTab(),

                  // Вкладка с уведомлениями о сроке годности
                  _buildExpiryRemindersTab(),

                  // Вкладка с уведомлениями о запасах
                  _buildStockNotificationsTab(),
                ],
              ),
    );
  }

  Widget _buildMedicationRemindersTab() {
    if (_medicationRemindersStream == null) {
      return const Center(child: Text('Необходимо войти в систему'));
    }

    return StreamBuilder<List<MedicationReminder>>(
      stream: _medicationRemindersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final reminders = snapshot.data ?? [];

        if (reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Нет уведомлений о приеме лекарств',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return _buildMedicationReminderCard(reminder);
          },
        );
      },
    );
  }

  Widget _buildExpiryRemindersTab() {
    if (_expiryRemindersStream == null) {
      return const Center(child: Text('Необходимо войти в систему'));
    }

    return StreamBuilder<List<ExpiryReminder>>(
      stream: _expiryRemindersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final reminders = snapshot.data ?? [];

        if (reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Нет уведомлений о сроке годности',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return _buildExpiryReminderCard(reminder);
          },
        );
      },
    );
  }

  Widget _buildStockNotificationsTab() {
    return StreamBuilder<List<StockNotification>>(
      stream: _stockNotificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Ошибка загрузки уведомлений: ${snapshot.error}'),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Нет уведомлений о запасах',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.warning, color: Colors.orange),
                ),
                title: Text(
                  notification.medicationName,
                  style: TextStyle(
                    fontWeight:
                        notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Осталось: ${notification.currentQuantity} ${notification.dimension}',
                    ),
                    Text(
                      'Аптечка: ${notification.kitName}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      DateFormat(
                        'dd.MM.yyyy HH:mm',
                      ).format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                trailing:
                    notification.isRead
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed:
                              () => _markStockNotificationAsRead(notification),
                        ),
                onTap:
                    () => _navigateToMedicationDetails(
                      notification.medicationId,
                      notification.kitId,
                    ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMedicationReminderCard(MedicationReminder reminder) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          reminder.medicationName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Аптечка: ${reminder.kitName}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Время приема: ${timeFormat.format(reminder.scheduledTime)} ${dateFormat.format(reminder.scheduledTime)}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Дозировка: ${reminder.dosage} ${reminder.dimension}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.medication, color: Colors.white),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: () => _markMedicationReminderAsRead(reminder),
          tooltip: 'Отметить как прочитанное',
        ),
        onTap:
            () => _navigateToMedicationDetails(
              reminder.medicationId,
              reminder.kitId,
            ),
      ),
    );
  }

  Widget _buildExpiryReminderCard(ExpiryReminder reminder) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final expiryColor =
        reminder.daysRemaining <= 0
            ? Colors.red
            : reminder.daysRemaining <= 7
            ? Colors.orange
            : Colors.amber;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          reminder.medicationName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Аптечка: ${reminder.kitName}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Срок годности: ${dateFormat.format(reminder.expiryDate)}',
              style: TextStyle(fontSize: 14, color: expiryColor),
            ),
            Text(
              reminder.daysRemaining <= 0
                  ? 'Срок годности истек!'
                  : 'Осталось дней: ${reminder.daysRemaining}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: expiryColor,
              ),
            ),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: expiryColor,
          child: const Icon(Icons.warning, color: Colors.white),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: () => _markExpiryReminderAsRead(reminder),
          tooltip: 'Отметить как прочитанное',
        ),
        onTap:
            () => _navigateToMedicationDetails(
              reminder.medicationId,
              reminder.kitId,
            ),
      ),
    );
  }

  Future<void> _markStockNotificationAsRead(
    StockNotification notification,
  ) async {
    try {
      await _stockNotificationService.markAsRead(notification.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Уведомление отмечено как прочитанное')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }
}
