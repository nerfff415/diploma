import 'package:flutter/material.dart';
import '../models/stock_notification.dart';
import '../services/stock_notification_service.dart';
import '../services/auth_service.dart';
import '../services/medication_service.dart';

class StockNotificationsScreen extends StatefulWidget {
  const StockNotificationsScreen({super.key});

  @override
  State<StockNotificationsScreen> createState() =>
      _StockNotificationsScreenState();
}

class _StockNotificationsScreenState extends State<StockNotificationsScreen> {
  final StockNotificationService _notificationService =
      StockNotificationService();
  final AuthService _authService = AuthService();
  final MedicationService _medicationService = MedicationService();

  Stream<List<StockNotification>>? _notificationsStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _notificationsStream = _notificationService.getUserStockNotifications(
        userId,
      );
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(StockNotification notification) async {
    try {
      await _notificationService.markAsRead(notification.id);
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
    StockNotification notification,
  ) async {
    try {
      final medication = await _medicationService.getMedicationById(
        notification.medicationId,
      );
      if (medication == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Медикамент не найден')));
        return;
      }

      // Здесь можно добавить навигацию к деталям медикамента
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => MedicationDetailsScreen(medication: medication),
      //   ),
      // );
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
        title: const Text('Уведомления о запасах'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notificationsStream == null
              ? const Center(child: Text('Необходимо войти в систему'))
              : StreamBuilder<List<StockNotification>>(
                stream: _notificationsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Ошибка: ${snapshot.error}'));
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
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
                            'Нет уведомлений о низком уровне запасов',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
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
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            notification.medicationName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Аптечка: ${notification.kitName}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Осталось: ${notification.currentQuantity} ${notification.dimension}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.warning, color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => _markAsRead(notification),
                            tooltip: 'Отметить как прочитанное',
                          ),
                          onTap:
                              () => _navigateToMedicationDetails(notification),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
