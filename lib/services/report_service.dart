import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import '../models/medication_schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Генерирует PDF-отчет о принятых медикаментах за указанный период
  Future<File> generateMedicationReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return File('');

    // Получаем записи о приемах лекарств за указанный период
    final records =
        await _firestore
            .collection('medication_records')
            .where('userId', isEqualTo: user.uid)
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .where('timestamp', isLessThanOrEqualTo: endDate)
            .get();

    // Группируем лекарства по названию
    final Map<String, List<Map<String, dynamic>>> groupedMedications = {};
    for (var record in records.docs) {
      final data = record.data();
      final medicationName = data['medicationName'] as String;
      if (!groupedMedications.containsKey(medicationName)) {
        groupedMedications[medicationName] = [];
      }
      groupedMedications[medicationName]!.add(data);
    }

    // Загружаем встроенные шрифты с поддержкой кириллицы
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final italicFontData = await rootBundle.load(
      "assets/fonts/Roboto-Italic.ttf",
    );

    // Создаем PDF документ с заданными шрифтами
    final pdf = pw.Document();

    // Регистрируем шрифты
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final ttfBold = pw.Font.ttf(boldFontData.buffer.asByteData());
    final ttfItalic = pw.Font.ttf(italicFontData.buffer.asByteData());

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
                style: pw.TextStyle(font: ttfBold, fontSize: 20),
              ),
            ),

            // Информация о периоде
            pw.Paragraph(
              text:
                  'Период: с ${DateFormat('dd.MM.yyyy').format(startDate)} по ${DateFormat('dd.MM.yyyy').format(endDate)}',
              style: pw.TextStyle(font: ttf, fontSize: 14),
            ),
            pw.Paragraph(
              text:
                  'Дата формирования: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
              style: pw.TextStyle(font: ttf, fontSize: 14),
            ),

            // Общая статистика
            pw.Header(
              level: 1,
              text: 'Общая статистика',
              textStyle: pw.TextStyle(font: ttfBold, fontSize: 16),
            ),
            pw.Paragraph(
              text: 'Всего лекарств: ${groupedMedications.length}',
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
            pw.Paragraph(
              text: 'Всего записей: ${records.docs.length}',
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),

            // Детальная информация по каждому медикаменту
            pw.Header(
              level: 1,
              text: 'Подробная информация',
              textStyle: pw.TextStyle(font: ttfBold, fontSize: 16),
            ),

            // Для каждого медикамента создаем раздел
            ...groupedMedications.entries
                .map((entry) {
                  final medicationName = entry.key;
                  final medicationSchedules = entry.value;
                  final totalTaken =
                      medicationSchedules
                          .where((r) => r['taken'] == true)
                          .length;
                  final totalMissed =
                      medicationSchedules
                          .where((r) => r['taken'] == false)
                          .length;

                  return [
                    pw.Header(
                      level: 2,
                      text: medicationName,
                      textStyle: pw.TextStyle(font: ttfBold, fontSize: 14),
                    ),
                    pw.Paragraph(
                      text:
                          'Всего запланировано: ${medicationSchedules.length}',
                      style: pw.TextStyle(font: ttf, fontSize: 12),
                    ),
                    pw.Paragraph(
                      text: 'Принято: $totalTaken',
                      style: pw.TextStyle(font: ttf, fontSize: 12),
                    ),
                    pw.Paragraph(
                      text: 'Пропущено: $totalMissed',
                      style: pw.TextStyle(font: ttf, fontSize: 12),
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text(
                                'Дата',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text(
                                'Время',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text(
                                'Статус',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...medicationSchedules.map((record) {
                          final date =
                              (record['timestamp'] as Timestamp).toDate();
                          final status =
                              record['taken'] == true ? 'Принято' : 'Пропущено';
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8.0),
                                child: pw.Text(
                                  DateFormat('dd.MM.yyyy').format(date),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8.0),
                                child: pw.Text(
                                  DateFormat('HH:mm').format(date),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8.0),
                                child: pw.Text(status),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                  ];
                })
                .expand((element) => element)
                .toList(),
          ];
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Страница ${context.pageNumber} из ${context.pagesCount}',
              style: pw.TextStyle(
                font: ttfItalic,
                fontSize: 10,
                color: PdfColors.grey,
              ),
            ),
          );
        },
      ),
    );

    // Сохраняем PDF во временный файл
    final output = await getTemporaryDirectory();
    final reportName =
        'отчет_о_приемах_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${output.path}/$reportName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Открывает PDF файл
  Future<void> openPdfFile(File file) async {
    await OpenFile.open(file.path);
  }

  /// Делится PDF файлом
  Future<void> sharePdfFile(File file) async {
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Отчет о приемах лекарств');
  }
}
