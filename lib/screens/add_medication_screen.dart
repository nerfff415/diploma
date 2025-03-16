import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';

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

  final MedicationService _medicationService = MedicationService();

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
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
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
    final initialDate = _expiryDate;
    final firstDate = DateTime.now(); // Не позволяем выбрать прошедшую дату
    final lastDate = DateTime.now().add(
      const Duration(days: 5 * 365),
    ); // Максимум 5 лет вперед

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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

    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
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
                        decoration: const InputDecoration(
                          labelText: 'Название препарата',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.medication),
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
                        decoration: const InputDecoration(
                          labelText: 'Штрих-код (опционально)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
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
