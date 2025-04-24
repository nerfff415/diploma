import 'dart:convert';
import 'package:flutter/services.dart';
import '../services/barcode_logger.dart';

class MedicationDataService {
  static final MedicationDataService _instance =
      MedicationDataService._internal();
  factory MedicationDataService() => _instance;
  MedicationDataService._internal();

  List<Map<String, dynamic>> _medicationData = [];

  Future<void> loadMedicationData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/aurora_iventory_complete_v2_20250301.json',
      );
      _medicationData = List<Map<String, dynamic>>.from(
        json.decode(jsonString),
      );
    } catch (e) {
      print('Error loading medication data: $e');
    }
  }

  // Helper method to extract numeric value from amount string
  double? _extractNumericValue(String? amountString) {
    if (amountString == null) return null;

    // Remove all non-numeric characters except decimal point
    final numericString = amountString.replaceAll(RegExp(r'[^\d.]'), '');
    if (numericString.isEmpty) return null;

    return double.tryParse(numericString);
  }

  Map<String, dynamic>? findMedicationByBarcode(String barcode) {
    try {
      // Log the search attempt
      BarcodeLogger.logBarcode(barcode, null);

      // Try to find exact match
      var medication = _medicationData.firstWhere(
        (item) => item['barcode']?.toString() == barcode,
        orElse: () => {},
      );

      if (medication.isNotEmpty) {
        return {
          'name': medication['prep_full'] ?? medication['prep_short'],
          'amount': _extractNumericValue(medication['amount']),
          'description': medication['sc_text'],
        };
      }

      // If not found, try to find by converting to number
      try {
        final barcodeNumber = int.tryParse(barcode);
        if (barcodeNumber != null) {
          medication = _medicationData.firstWhere(
            (item) => item['barcode'] == barcodeNumber,
            orElse: () => {},
          );

          if (medication.isNotEmpty) {
            return {
              'name': medication['prep_full'] ?? medication['prep_short'],
              'amount': _extractNumericValue(medication['amount']),
              'description': medication['sc_text'],
            };
          }
        }
      } catch (e) {
        print('Error converting barcode to number: $e');
      }

      // Log the failure to find
      BarcodeLogger.logBarcode(barcode, 'Not found in database');
      return null;
    } catch (e) {
      print('Error finding medication by barcode: $e');
      BarcodeLogger.logBarcode(barcode, 'Error: $e');
      return null;
    }
  }
}
