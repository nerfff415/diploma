import 'dart:convert';
import 'package:flutter/services.dart';
import '../services/barcode_logger.dart';

/// Сервис для работы с данными о лекарственных препаратах
class MedicationDataService {
  // Реализация шаблона Singleton
  static final MedicationDataService _singleton = MedicationDataService._privateConstructor();
  
  // Приватный конструктор для Singleton
  MedicationDataService._privateConstructor();
  
  // Фабричный метод для получения экземпляра класса
  factory MedicationDataService() => _singleton;

  // Хранилище данных о лекарствах
  List<Map<String, dynamic>> _medicationsDatabase = [];
  
  // Путь к файлу с данными о лекарствах
  static const String _databaseFilePath = 'assets/aurora_iventory_complete_v2_20250301.json';

  /// Загружает данные о лекарствах из JSON-файла
  Future<void> loadMedicationData() async {
    try {
      // Загружаем содержимое файла
      final String rawData = await _loadAssetFile(_databaseFilePath);
      
      // Преобразуем JSON в список объектов
      _medicationsDatabase = _parseJsonData(rawData);
    } catch (error) {
      _handleDataLoadError(error);
    }
  }
  
  /// Загружает содержимое файла из ресурсов приложения
  Future<String> _loadAssetFile(String filePath) async {
    return await rootBundle.loadString(filePath);
  }
  
  /// Преобразует JSON-строку в список объектов
  List<Map<String, dynamic>> _parseJsonData(String jsonString) {
    final decodedData = json.decode(jsonString);
    return List<Map<String, dynamic>>.from(decodedData);
  }
  
  /// Обрабатывает ошибку загрузки данных
  void _handleDataLoadError(dynamic error) {
    print('Ошибка при загрузке данных о лекарствах: $error');
  }

  /// Извлекает числовое значение из строки с количеством
  /// 
  /// Например, из строки "100 мг" извлекает число 100
  double? _extractNumericValue(String? amountString) {
    // Проверяем наличие данных
    if (amountString == null || amountString.isEmpty) {
      return null;
    }

    // Удаляем все нецифровые символы, кроме десятичной точки
    final cleanedString = _removeNonNumericCharacters(amountString);
    
    // Проверяем, что строка не пуста после очистки
    if (cleanedString.isEmpty) {
      return null;
    }

    // Пытаемся преобразовать в число
    return _parseStringToDouble(cleanedString);
  }
  
  /// Удаляет все нецифровые символы, кроме десятичной точки
  String _removeNonNumericCharacters(String input) {
    return input.replaceAll(RegExp(r'[^\d.]'), '');
  }
  
  /// Преобразует строку в число с плавающей точкой
  double? _parseStringToDouble(String numericString) {
    return double.tryParse(numericString);
  }

  /// Поиск лекарства по штрих-коду
  /// 
  /// Возвращает информацию о лекарстве или null, если не найдено
  Map<String, dynamic>? findMedicationByBarcode(String barcode) {
    try {
      // Регистрируем попытку поиска
      _logSearchAttempt(barcode);

      // Пытаемся найти точное совпадение
      final exactMatch = _findExactBarcodeMatch(barcode);
      if (exactMatch.isNotEmpty) {
        return _createMedicationInfo(exactMatch);
      }

      // Если точное совпадение не найдено, пробуем найти по числовому значению штрих-кода
      final numericMatch = _findNumericBarcodeMatch(barcode);
      if (numericMatch.isNotEmpty) {
        return _createMedicationInfo(numericMatch);
      }

      // Если лекарство не найдено, регистрируем это
      _logSearchFailure(barcode);
      return null;
    } catch (error) {
      _handleSearchError(barcode, error);
      return null;
    }
  }
  
  /// Регистрирует попытку поиска
  void _logSearchAttempt(String barcode) {
    BarcodeLogger.logBarcode(barcode, null);
  }
  
  /// Поиск точного совпадения штрих-кода
  Map<String, dynamic> _findExactBarcodeMatch(String barcode) {
    try {
      return _medicationsDatabase.firstWhere(
        (medication) => medication['barcode']?.toString() == barcode,
        orElse: () => {},
      );
    } catch (_) {
      return {};
    }
  }
  
  /// Поиск по числовому значению штрих-кода
  Map<String, dynamic> _findNumericBarcodeMatch(String barcode) {
    try {
      // Пытаемся преобразовать штрих-код в число
      final numericBarcode = int.tryParse(barcode);
      
      // Если преобразование успешно, ищем по числовому значению
      if (numericBarcode != null) {
        return _medicationsDatabase.firstWhere(
          (medication) => medication['barcode'] == numericBarcode,
          orElse: () => {},
        );
      }
      
      return {};
    } catch (_) {
      return {};
    }
  }
  
  /// Создает информацию о лекарстве из данных базы
  Map<String, dynamic> _createMedicationInfo(Map<String, dynamic> medicationData) {
    return {
      'name': _getMedicationName(medicationData),
      'amount': _extractNumericValue(medicationData['amount']),
      'description': medicationData['sc_text'],
    };
  }
  
  /// Получает название лекарства из данных
  String _getMedicationName(Map<String, dynamic> medicationData) {
    return medicationData['prep_full'] ?? medicationData['prep_short'] ?? 'Неизвестное лекарство';
  }
  
  /// Регистрирует неудачный поиск
  void _logSearchFailure(String barcode) {
    BarcodeLogger.logBarcode(barcode, 'Not found in database');
  }
  
  /// Обрабатывает ошибку поиска
  void _handleSearchError(String barcode, dynamic error) {
    print('Ошибка при поиске лекарства по штрих-коду: $error');
    BarcodeLogger.logBarcode(barcode, 'Error: $error');
  }
}
