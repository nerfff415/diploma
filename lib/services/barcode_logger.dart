import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BarcodeLogger {
  static Future<void> logBarcode(String barcode, String? medicationName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/barcode_log.txt');

      final timestamp = DateTime.now().toString();
      final logEntry = '''
Timestamp: $timestamp
Barcode: $barcode
Medication Name: ${medicationName ?? 'Not found'}
----------------------------------------
''';

      await file.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      print('Error logging barcode: $e');
    }
  }

  static Future<String> readLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/barcode_log.txt');

      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'No logs found';
    } catch (e) {
      return 'Error reading logs: $e';
    }
  }
}
