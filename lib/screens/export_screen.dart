import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ReportService _reportService = ReportService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Дата начала не может быть позже даты окончания'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final file = await _reportService.generateMedicationReport(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Отчет сгенерирован'),
                content: const Text('Что вы хотите сделать с отчетом?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reportService.openPdfFile(file);
                    },
                    child: const Text('Открыть'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reportService.sharePdfFile(file);
                    },
                    child: const Text('Поделиться'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при генерации отчета: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Экспорт отчета'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Выберите период для отчета',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Начальная дата'),
                      subtitle: Text(
                        DateFormat('dd.MM.yyyy').format(_startDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Конечная дата'),
                      subtitle: Text(DateFormat('dd.MM.yyyy').format(_endDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isGenerating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Сгенерировать отчет',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
