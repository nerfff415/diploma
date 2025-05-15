import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Сервис для регистрации и хранения информации о сканированных штрих-кодах
class BarcodeLogger {
  // Константы для форматирования логов
  static const String _logFileName = 'barcode_log.txt';
  static const String _logSeparator = '----------------------------------------';
  
  /// Записывает информацию о сканировании штрих-кода в лог-файл
  /// 
  /// [barcodeData] - данные штрих-кода
  /// [productName] - название продукта, если найдено
  static Future<void> logBarcode(String barcodeData, String? productName) async {
    // Получаем директорию для хранения файлов приложения
    final storageDir = await _getStorageDirectory();
    
    // Формируем путь к файлу логов
    final logFilePath = await _buildLogFilePath(storageDir);
    
    // Создаем запись для лога
    final logRecord = _createLogRecord(barcodeData, productName);
    
    // Записываем данные в файл
    await _writeToLogFile(logFilePath, logRecord);
  }
  
  /// Получает директорию для хранения файлов приложения
  static Future<Directory> _getStorageDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// Формирует путь к файлу логов
  static Future<File> _buildLogFilePath(Directory directory) async {
    return File('${directory.path}/$_logFileName');
  }
  
  /// Создает запись для лога
  static String _createLogRecord(String barcodeData, String? productName) {
    final currentTime = DateTime.now().toString();
    final productInfo = productName ?? 'Not found';
    
    return '''
Timestamp: $currentTime
Barcode: $barcodeData
Medication Name: $productInfo
$_logSeparator
''';
  }
  
  /// Записывает данные в файл логов
  static Future<void> _writeToLogFile(File file, String content) async {
    try {
      await file.writeAsString(content, mode: FileMode.append);
    } catch (e) {
      print('Ошибка при записи лога штрих-кода: $e');
    }
  }

  /// Считывает все записи из файла логов
  static Future<String> readLogs() async {
    try {
      // Получаем директорию для хранения файлов приложения
      final storageDir = await _getStorageDirectory();
      
      // Формируем путь к файлу логов
      final logFile = await _buildLogFilePath(storageDir);
      
      // Проверяем существование файла и считываем данные
      if (await _fileExists(logFile)) {
        return await _readFileContents(logFile);
      }
      
      return 'Логи не найдены';
    } catch (e) {
      return 'Ошибка при чтении логов: $e';
    }
  }
  
  /// Проверяет существование файла
  static Future<bool> _fileExists(File file) async {
    return await file.exists();
  }
  
  /// Считывает содержимое файла
  static Future<String> _readFileContents(File file) async {
    return await file.readAsString();
  }
}

