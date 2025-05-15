import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/medication_data_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import '../services/barcode_logger.dart';

class AddMedicationScreen extends StatefulWidget {
  final String kitId;

  const AddMedicationScreen({super.key, required this.kitId});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _amountController = TextEditingController();

  final MedicationService _medicationService = MedicationService();
  final MedicationDataService _medicationDataService = MedicationDataService();

  DateTime _expiryDate = DateTime.now().add(
    const Duration(days: 365),
  ); // По умолчанию 1 год

  String _selectedForm = MedicationForm.tablets.name; // По умолчанию таблетки
  String _selectedCategory =
      MedicationCategory.other.name; // По умолчанию другое
  String _selectedDimension =
      MedicationDimension.pcs.name; // По умолчанию штуки

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _medicationDataService.loadMedicationData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Сохранение препарата
  void _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Создаем объект медикамента
        final medication = Medication(
          id: '', // ID будет присвоен Firestore
          kitId: widget.kitId,
          name: _nameController.text.trim(),
          form: _selectedForm,
          quantity: double.parse(_quantityController.text.trim()),
          dimension: _selectedDimension,
          expiryDate: _expiryDate,
          category: _selectedCategory,
          description:
              _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
          barcode:
              _barcodeController.text.trim().isNotEmpty
                  ? _barcodeController.text.trim()
                  : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Добавляем медикамент в Firestore
        await _medicationService.createMedication(medication);

        // Возвращаемся на предыдущий экран с результатом успешного создания
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Медикамент успешно добавлен')),
          );
        }
      } catch (e) {
        // Обработка ошибок
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  /// Инициирует процесс сканирования штрих-кода и обработки результатов
  Future<void> _scanBarcode() async {
    try {
      // Запускаем экран сканирования и ожидаем результат
      await _navigateToScannerScreen();
    } catch (error) {
      // Обрабатываем возможные ошибки
      _handleScanningError(error);
    }
  }
  
  /// Открывает экран сканирования штрих-кода
  Future<void> _navigateToScannerScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _buildScannerScreen(),
      ),
    );
  }
  
  /// Создает экран сканирования штрих-кода
  Widget _buildScannerScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование штрих-кода'),
        backgroundColor: Colors.red,
      ),
      body: MobileScanner(
        onDetect: _processScanResults,
      ),
    );
  }
  
  /// Обрабатывает результаты сканирования
  void _processScanResults(BarcodeCapture capture) async {
    // Извлекаем данные штрих-кода
    final List<Barcode> detectedCodes = capture.barcodes;
    
    // Проверяем, что штрих-коды были обнаружены
    if (detectedCodes.isEmpty) return;
    
    // Берем первый обнаруженный штрих-код
    final String barcodeValue = detectedCodes.first.rawValue ?? '';
    
    // Ищем информацию о лекарстве по штрих-коду
    final medicationInfo = await _findMedicationByBarcode(barcodeValue);
    
    // Закрываем экран сканирования
    if (mounted) Navigator.pop(context);
  }
  
  /// Поиск информации о лекарстве по штрих-коду
  Future<Map<String, dynamic>?> _findMedicationByBarcode(String barcode) async {
    // Получаем информацию о лекарстве
    final medicationDetails = _medicationDataService.findMedicationByBarcode(barcode);
    
    // Логируем результат сканирования
    await BarcodeLogger.logBarcode(barcode, medicationDetails?['name']);
    
    // Если информация найдена, заполняем поля формы
    if (medicationDetails != null) {
      _updateFormWithMedicationDetails(medicationDetails, barcode);
    } else {
      _showMedicationNotFoundMessage(barcode);
    }
    
    return medicationDetails;
  }
  
  /// Обновляет поля формы данными о лекарстве
  void _updateFormWithMedicationDetails(Map<String, dynamic> details, String barcode) {
    if (!mounted) return;
    
    setState(() {
      // Заполняем название препарата
      _nameController.text = details['name'];
      
      // Заполняем штрих-код
      _barcodeController.text = barcode;
      
      // Заполняем количество, если доступно
      if (details['amount'] != null) {
        _quantityController.text = details['amount'].toString();
      }
      
      // Заполняем описание, если доступно
      _descriptionController.text = details['description'] ?? '';
    });
  }
  
  /// Показывает сообщение о том, что лекарство не найдено
  void _showMedicationNotFoundMessage(String barcode) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Лекарство не найдено в базе данных. Штрих-код: $barcode'),
        duration: const Duration(seconds: 5),
      ),
    );
  }
  
  /// Обрабатывает ошибки сканирования
  void _handleScanningError(dynamic error) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка при сканировании штрих-кода: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавление препарата'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      // Добавляем плавающую кнопку для быстрого доступа к функции сохранения
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveMedication,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save),
        label: const Text('Сохранить'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Название препарата
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Название препарата',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.medication),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _scanBarcode,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите название';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Форма выпуска
                      const Text(
                        'Форма выпуска:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            MedicationForm.values.map((form) {
                              final isSelected = form.name == _selectedForm;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedForm = form.name;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Theme.of(
                                              context,
                                            ).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        form.icon,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black54,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        form.name,
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Количество и размерность
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Поле для количества
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Количество',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.format_list_numbered),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Укажите количество';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Введите число';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Выбор размерности
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _selectedDimension,
                              decoration: const InputDecoration(
                                labelText: 'Ед. изм.',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  MedicationDimension.values.map((dimension) {
                                    return DropdownMenuItem<String>(
                                      value: dimension.name,
                                      child: Text(dimension.name),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedDimension = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Срок годности
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Срок годности',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'dd.MM.yyyy',
                                    ).format(_expiryDate),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
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
                      const SizedBox(height: 24),

                      // Категория
                      const Text(
                        'Категория:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            MedicationCategory.values.map((category) {
                              final isSelected =
                                  category.name == _selectedCategory;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category.name;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Theme.of(
                                              context,
                                            ).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        category.icon,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black54,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        category.name,
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Описание (опционально)
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание (опционально)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Штрих-код (опционально)
                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'Штрих-код (опционально)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.qr_code),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _scanBarcode,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Кнопка сохранения
                      ElevatedButton(
                        onPressed: _saveMedication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Добавить препарат',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      // Добавляем отступ внизу для плавающей кнопки
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
    );
  }
}
