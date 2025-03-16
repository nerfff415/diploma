import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import '../models/medication_schedule.dart';

class ReportService {
  /// Генерирует PDF-отчет о принятых медикаментах за указанный период
  Future<File> generateMedicationReport({
    required List<MedicationSchedule> schedules,
    required DateTime startDate,
    required DateTime endDate,
    required String userName,
  }) async {
    // Загружаем шрифты для поддержки кириллицы
    final regularFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    // Создаем PDF документ
    final pdf = pw.Document();

    // Группируем медикаменты по названию
    final medicationGroups = <String, List<MedicationSchedule>>{};
    for (var schedule in schedules) {
      if (!medicationGroups.containsKey(schedule.medicationName)) {
        medicationGroups[schedule.medicationName] = [];
      }
      medicationGroups[schedule.medicationName]!.add(schedule);
    }

    // Считаем общую статистику
    int totalScheduled = schedules.length;
    int totalTaken = schedules.where((s) => s.taken).length;
    double takenPercentage =
        totalScheduled > 0 ? (totalTaken / totalScheduled) * 100 : 0;

    // Форматируем даты для отображения
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
    final formattedStartDate = dateFormat.format(startDate);
    final formattedEndDate = dateFormat.format(endDate);

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
                'Отчет о приеме медикаментов',
                style: pw.TextStyle(font: boldFont, fontSize: 20),
              ),
            ),

            // Информация о пользователе и периоде
            pw.Paragraph(
              text: 'Пользователь: $userName',
              style: pw.TextStyle(font: regularFont, fontSize: 14),
            ),
            pw.Paragraph(
              text: 'Период: с $formattedStartDate по $formattedEndDate',
              style: pw.TextStyle(font: regularFont, fontSize: 14),
            ),

            // Общая статистика
            pw.Header(
              level: 1,
              text: 'Общая статистика',
              textStyle: pw.TextStyle(font: boldFont, fontSize: 16),
            ),
            pw.Paragraph(
              text: 'Всего запланировано приемов: $totalScheduled',
              style: pw.TextStyle(font: regularFont, fontSize: 12),
            ),
            pw.Paragraph(
              text:
                  'Принято медикаментов: $totalTaken (${takenPercentage.toStringAsFixed(1)}%)',
              style: pw.TextStyle(font: regularFont, fontSize: 12),
            ),

            // Детальная информация по каждому медикаменту
            pw.Header(
              level: 1,
              text: 'Детальная информация',
              textStyle: pw.TextStyle(font: boldFont, fontSize: 16),
            ),

            // Для каждого медикамента создаем раздел
            ...medicationGroups.entries
                .map((entry) {
                  final medicationName = entry.key;
                  final medicationSchedules = entry.value;
                  final takenCount =
                      medicationSchedules.where((s) => s.taken).length;
                  final takenPercent =
                      medicationSchedules.isNotEmpty
                          ? (takenCount / medicationSchedules.length) * 100
                          : 0;

                  return [
                    pw.Header(
                      level: 2,
                      text: medicationName,
                      textStyle: pw.TextStyle(font: boldFont, fontSize: 14),
                    ),
                    pw.Paragraph(
                      text:
                          'Запланировано приемов: ${medicationSchedules.length}',
                      style: pw.TextStyle(font: regularFont, fontSize: 12),
                    ),
                    pw.Paragraph(
                      text:
                          'Принято: $takenCount (${takenPercent.toStringAsFixed(1)}%)',
                      style: pw.TextStyle(font: regularFont, fontSize: 12),
                    ),

                    // Таблица с записями о приеме
                    pw.Table.fromTextArray(
                      headerStyle: pw.TextStyle(font: boldFont, fontSize: 12),
                      cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
                      headerDecoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      headers: [
                        'Дата',
                        'Аптечка',
                        'Дозировка',
                        'Статус',
                        'Время приема',
                        'Примечания',
                      ],
                      data:
                          medicationSchedules.map((schedule) {
                            return [
                              dateFormat.format(schedule.date),
                              schedule.kitName,
                              '${schedule.dosage} ${schedule.dimension}',
                              schedule.taken ? 'Принято' : 'Не принято',
                              schedule.takenAt != null
                                  ? dateTimeFormat.format(schedule.takenAt!)
                                  : '-',
                              schedule.notes ?? '-',
                            ];
                          }).toList(),
                    ),
                    pw.SizedBox(height: 10),
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
                font: italicFont,
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
        'medication_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
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
    ], text: 'Отчет о приеме медикаментов');
  }
}
