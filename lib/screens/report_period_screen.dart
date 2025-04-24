import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../models/medication_schedule.dart';
import '../services/medication_schedule_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ReportPeriodScreen extends StatefulWidget {
  const ReportPeriodScreen({super.key});

  @override
  State<ReportPeriodScreen> createState() => _ReportPeriodScreenState();
}

class _ReportPeriodScreenState extends State<ReportPeriodScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;
  late pw.Font _robotoFont;
  late pw.Font _robotoBoldFont;

  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    final robotoData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final robotoBoldData = await rootBundle.load(
      'assets/fonts/Roboto-Bold.ttf',
    );

    _robotoFont = pw.Font.ttf(robotoData);
    _robotoBoldFont = pw.Font.ttf(robotoBoldData);
  }

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

  // Загрузка данных для отчета
  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _reportData = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Пользователь не авторизован');
        return;
      }

      print('Начало загрузки данных для отчета');
      print('Период: с ${_startDate.toString()} по ${_endDate.toString()}');

      // Получаем все записи о приемах лекарств пользователя
      final schedules =
          await _firestore
              .collection('medication_schedules')
              .where('userId', isEqualTo: user.uid)
              .get();

      print('Найдено расписаний: ${schedules.docs.length}');

      int totalScheduled = 0;
      int totalTaken = 0;
      final medicationStats = <String, Map<String, int>>{};

      // Обрабатываем каждое расписание
      for (var schedule in schedules.docs) {
        final scheduleData = schedule.data();
        final medicationName = scheduleData['medicationName'] as String;
        final date = DateTime.fromMillisecondsSinceEpoch(
          scheduleData['date'] as int,
        );
        final time = scheduleData['time'] as String;
        final taken = scheduleData['taken'] as bool? ?? false;
        final takenAt = scheduleData['takenAt'] as int?;

        print('Обработка лекарства: $medicationName');
        print('Дата: $date, Время: $time, Принято: $taken');

        // Пропускаем записи вне выбранного периода
        if (date.isBefore(_startDate) || date.isAfter(_endDate)) {
          print('Пропущена запись вне периода: ${date.toString()}');
          continue;
        }

        // Инициализируем статистику для лекарства, если еще не существует
        if (!medicationStats.containsKey(medicationName)) {
          medicationStats[medicationName] = {'scheduled': 0, 'taken': 0};
        }

        totalScheduled++;
        if (taken) totalTaken++;

        medicationStats[medicationName]!['scheduled'] =
            medicationStats[medicationName]!['scheduled']! + 1;
        if (taken) {
          medicationStats[medicationName]!['taken'] =
              medicationStats[medicationName]!['taken']! + 1;
        }
      }

      print('Итоговая статистика:');
      print('Всего запланировано: $totalScheduled');
      print('Всего принято: $totalTaken');
      print('Статистика по лекарствам: $medicationStats');

      final statistics = {
        'totalScheduled': totalScheduled,
        'totalTaken': totalTaken,
        'completionRate':
            totalScheduled > 0
                ? ((totalTaken / totalScheduled) * 100).round()
                : 0,
        'medicationStats': medicationStats,
      };

      setState(() {
        _reportData = statistics;
      });
    } catch (e, stackTrace) {
      print('Ошибка при загрузке данных: $e');
      print('Стек вызовов: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при загрузке данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Генерация PDF-отчета
  Future<File> _generatePDFReport() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy');

    // Добавляем страницу с отчетом
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Заголовок отчета
            pw.Header(
              level: 0,
              child: pw.Text(
                'Отчет о приемах лекарств',
                style: pw.TextStyle(font: _robotoBoldFont, fontSize: 20),
              ),
            ),

            // Период отчета
            pw.Paragraph(
              text:
                  'Период: с ${dateFormat.format(_startDate)} по ${dateFormat.format(_endDate)}',
              style: pw.TextStyle(font: _robotoFont),
            ),

            // Общая статистика
            pw.Header(
              level: 1,
              text: 'Общая статистика',
              textStyle: pw.TextStyle(font: _robotoBoldFont, fontSize: 16),
            ),
            pw.Paragraph(
              text:
                  'Всего запланировано приемов: ${_reportData?['totalScheduled'] ?? 0}',
              style: pw.TextStyle(font: _robotoFont),
            ),
            pw.Paragraph(
              text: 'Принято лекарств: ${_reportData?['totalTaken'] ?? 0}',
              style: pw.TextStyle(font: _robotoFont),
            ),
            pw.Paragraph(
              text:
                  'Процент выполнения: ${_reportData?['completionRate'] ?? 0}%',
              style: pw.TextStyle(font: _robotoFont),
            ),

            // Статистика по лекарствам
            pw.Header(
              level: 1,
              text: 'Статистика по лекарствам',
              textStyle: pw.TextStyle(font: _robotoBoldFont, fontSize: 16),
            ),
            ...(_reportData?['medicationStats'] as Map<String, dynamic>? ?? {})
                .entries
                .map((entry) {
                  final medicationName = entry.key;
                  final stats = entry.value as Map<String, int>;
                  final scheduled = stats['scheduled'] ?? 0;
                  final taken = stats['taken'] ?? 0;
                  final rate =
                      scheduled > 0 ? ((taken / scheduled) * 100).round() : 0;

                  return [
                    pw.Header(
                      level: 2,
                      text: medicationName,
                      textStyle: pw.TextStyle(
                        font: _robotoBoldFont,
                        fontSize: 14,
                      ),
                    ),
                    pw.Paragraph(
                      text: 'Запланировано: $scheduled',
                      style: pw.TextStyle(font: _robotoFont),
                    ),
                    pw.Paragraph(
                      text: 'Принято: $taken',
                      style: pw.TextStyle(font: _robotoFont),
                    ),
                    pw.Paragraph(
                      text: 'Процент выполнения: $rate%',
                      style: pw.TextStyle(font: _robotoFont),
                    ),
                    pw.SizedBox(height: 10),
                  ];
                })
                .expand((element) => element)
                .toList(),

            // Дата формирования отчета
            pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'Дата формирования: ${dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(
                  font: _robotoFont,
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Сохраняем PDF во временный файл
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/отчет_о_приемах.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<void> _shareReport() async {
    try {
      final file = await _generatePDFReport();
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Отчет о приемах лекарств за период с ${DateFormat('dd.MM.yyyy').format(_startDate)} по ${DateFormat('dd.MM.yyyy').format(_endDate)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при отправке отчета: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчет о приемах'),
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
              onPressed: _isLoading ? null : _loadReportData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Сформировать отчет',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
            const SizedBox(height: 20),

            // Отображение данных отчета
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_reportData == null)
              const Center(
                child: Text(
                  'Выберите период и нажмите "Сформировать отчет"',
                  style: TextStyle(fontSize: 16),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Общая статистика',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Всего запланировано: ${_reportData!['totalScheduled']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Принято: ${_reportData!['totalTaken']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Процент выполнения: ${_reportData!['completionRate']}%',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Статистика по лекарствам',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...(_reportData!['medicationStats']
                                  as Map<String, dynamic>? ??
                              {})
                          .entries
                          .map((entry) {
                            final medicationName = entry.key;
                            final stats = entry.value as Map<String, int>;
                            final scheduled = stats['scheduled'] ?? 0;
                            final taken = stats['taken'] ?? 0;
                            final rate =
                                scheduled > 0
                                    ? ((taken / scheduled) * 100).round()
                                    : 0;

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medicationName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text('Запланировано: $scheduled'),
                                    Text('Принято: $taken'),
                                    Text('Процент выполнения: $rate%'),
                                  ],
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ],
                  ),
                ),
              ),

            // Кнопки действий с отчетом
            if (_reportData != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final file = await _generatePDFReport();
                        await OpenFile.open(file.path);
                      },
                      icon: const Icon(Icons.preview),
                      label: const Text('Просмотреть'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareReport,
                      icon: const Icon(Icons.share),
                      label: const Text('Поделиться'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
