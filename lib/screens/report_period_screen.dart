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

class ReportPeriodScreen extends StatefulWidget {
  const ReportPeriodScreen({super.key});

  @override
  State<ReportPeriodScreen> createState() => _ReportPeriodScreenState();
}

class _ReportPeriodScreenState extends State<ReportPeriodScreen> {
  final MedicationScheduleService _scheduleService =
      MedicationScheduleService();
  final AuthService _authService = AuthService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
  }

  // Выбор начальной даты
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
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

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  // Выбор конечной даты
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
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

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // Загрузка данных для отчета
  Future<void> _loadReportData() async {
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

      // Получаем статистику по приему лекарств за выбранный период
      final statistics = await _scheduleService.getStatistics(
        userId,
        _startDate,
        _endDate,
      );

      setState(() {
        _reportData = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка при загрузке данных: $e';
      });
    }
  }

  // Генерация PDF-отчета
  Future<File> _generatePDF() async {
    final pdf = pw.Document();

    // Загружаем шрифт для поддержки кириллицы
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    // Форматирование дат
    final dateFormat = DateFormat('dd.MM.yyyy');

    // Добавляем страницу с отчетом
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Заголовок отчета
              pw.Center(
                child: pw.Text(
                  'Отчет о приеме лекарств',
                  style: pw.TextStyle(font: fontBold, fontSize: 20),
                ),
              ),
              pw.SizedBox(height: 10),

              // Период отчета
              pw.Center(
                child: pw.Text(
                  'Период: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
              ),
              pw.SizedBox(height: 20),

              // Общая статистика
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Общая статистика:',
                      style: pw.TextStyle(font: fontBold, fontSize: 16),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Всего запланировано приемов:',
                          style: pw.TextStyle(font: font),
                        ),
                        pw.Text(
                          '${_reportData?['totalScheduled'] ?? 0}',
                          style: pw.TextStyle(font: fontBold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Принято лекарств:',
                          style: pw.TextStyle(font: font),
                        ),
                        pw.Text(
                          '${_reportData?['totalTaken'] ?? 0}',
                          style: pw.TextStyle(font: fontBold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Процент выполнения:',
                          style: pw.TextStyle(font: font),
                        ),
                        pw.Text(
                          '${_reportData?['completionRate'] ?? 0}%',
                          style: pw.TextStyle(font: fontBold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Статистика по медикаментам
              pw.Text(
                'Статистика по медикаментам:',
                style: pw.TextStyle(font: fontBold, fontSize: 16),
              ),
              pw.SizedBox(height: 10),

              // Таблица с медикаментами
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Заголовок таблицы
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Название',
                          style: pw.TextStyle(font: fontBold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'План',
                          style: pw.TextStyle(font: fontBold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Факт',
                          style: pw.TextStyle(font: fontBold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '%',
                          style: pw.TextStyle(font: fontBold),
                        ),
                      ),
                    ],
                  ),

                  // Данные по медикаментам
                  ..._getMedicationRows(font),
                ],
              ),

              // Дата формирования отчета
              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'Отчет сформирован: ${dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Сохраняем PDF в файл
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/medication_report.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Получение строк таблицы с медикаментами
  List<pw.TableRow> _getMedicationRows(pw.Font font) {
    final rows = <pw.TableRow>[];

    final medicationStats =
        _reportData?['medicationStats'] as Map<String, dynamic>? ?? {};

    medicationStats.forEach((medicationId, stats) {
      final name = stats['name'] as String? ?? 'Неизвестный медикамент';
      final scheduled = stats['scheduled'] as int? ?? 0;
      final taken = stats['taken'] as int? ?? 0;
      final percent =
          scheduled > 0 ? ((taken / scheduled) * 100).toStringAsFixed(1) : '0';

      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(name, style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('$scheduled', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('$taken', style: pw.TextStyle(font: font)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('$percent%', style: pw.TextStyle(font: font)),
            ),
          ],
        ),
      );
    });

    return rows;
  }

  // Открытие PDF-файла
  Future<void> _openPDF(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при открытии файла: ${result.message}'),
          ),
        );
      }
    }
  }

  // Поделиться PDF-файлом
  Future<void> _sharePDF(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'Отчет о приеме лекарств за период ${DateFormat('dd.MM.yyyy').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчет о приеме лекарств'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Выбор периода
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Выберите период:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Начальная дата
                    Row(
                      children: [
                        const Text(
                          'С:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectStartDate(context),
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
                                    DateFormat('dd.MM.yyyy').format(_startDate),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Конечная дата
                    Row(
                      children: [
                        const Text(
                          'По:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectEndDate(context),
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
                                    DateFormat('dd.MM.yyyy').format(_endDate),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Кнопка загрузки данных
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _loadReportData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Загрузить данные'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Отображение данных отчета
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _reportData == null
                      ? const Center(
                        child: Text(
                          'Выберите период и нажмите "Загрузить данные"',
                          textAlign: TextAlign.center,
                        ),
                      )
                      : SingleChildScrollView(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Общая статистика
                                const Text(
                                  'Общая статистика:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStatRow(
                                  'Всего запланировано приемов:',
                                  '${_reportData!['totalScheduled']}',
                                ),
                                _buildStatRow(
                                  'Принято лекарств:',
                                  '${_reportData!['totalTaken']}',
                                ),
                                _buildStatRow(
                                  'Процент выполнения:',
                                  '${_reportData!['completionRate']}%',
                                ),
                                const SizedBox(height: 16),

                                // Статистика по медикаментам
                                const Text(
                                  'Статистика по медикаментам:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Таблица с медикаментами
                                Table(
                                  border: TableBorder.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  columnWidths: const {
                                    0: FlexColumnWidth(3),
                                    1: FlexColumnWidth(1),
                                    2: FlexColumnWidth(1),
                                    3: FlexColumnWidth(1),
                                  },
                                  children: [
                                    // Заголовок таблицы
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                      ),
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'Название',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'План',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'Факт',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            '%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Данные по медикаментам
                                    ..._buildMedicationRows(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
            ),

            // Кнопки действий с отчетом
            if (_reportData != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final file = await _generatePDF();
                        if (mounted) {
                          _openPDF(file);
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Открыть PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final file = await _generatePDF();
                        if (mounted) {
                          _sharePDF(file);
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Поделиться'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Построение строки статистики
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Построение строк таблицы с медикаментами
  List<TableRow> _buildMedicationRows() {
    final rows = <TableRow>[];

    final medicationStats =
        _reportData!['medicationStats'] as Map<String, dynamic>? ?? {};

    medicationStats.forEach((medicationId, stats) {
      final name = stats['name'] as String? ?? 'Неизвестный медикамент';
      final scheduled = stats['scheduled'] as int? ?? 0;
      final taken = stats['taken'] as int? ?? 0;
      final percent =
          scheduled > 0 ? ((taken / scheduled) * 100).toStringAsFixed(1) : '0';

      rows.add(
        TableRow(
          children: [
            Padding(padding: const EdgeInsets.all(8.0), child: Text(name)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('$scheduled'),
            ),
            Padding(padding: const EdgeInsets.all(8.0), child: Text('$taken')),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('$percent%'),
            ),
          ],
        ),
      );
    });

    return rows;
  }
}
