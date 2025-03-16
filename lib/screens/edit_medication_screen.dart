import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';

class EditMedicationScreen extends StatefulWidget {
  final Medication medication;

  const EditMedicationScreen({super.key, required this.medication});

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _barcodeController;

  final MedicationService _medicationService = MedicationService();

  late DateTime _expiryDate;
  late String _selectedForm;
  late String _selectedCategory;
  late String _selectedDimension;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Инициализация контроллеров с данными из медикамента
    _nameController = TextEditingController(text: widget.medication.name);
    _quantityController = TextEditingController(
      text: widget.medication.quantity.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.medication.description ?? '',
    );
    _barcodeController = TextEditingController(
      text: widget.medication.barcode ?? '',
    );

    // Инициализация других полей
    _expiryDate = widget.medication.expiryDate;
    _selectedForm = widget.medication.form;
    _selectedCategory = widget.medication.category;
    _selectedDimension = widget.medication.dimension;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  // Обновление препарата
  void _updateMedication() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Создаем обновленный объект медикамента
        final updatedMedication = widget.medication.copyWith(
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
          updatedAt: DateTime.now(),
        );

        // Обновляем медикамент в Firestore
        await _medicationService.updateMedication(updatedMedication);

        // Возвращаемся на предыдущий экран с результатом успешного обновления
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Медикамент успешно обновлен')),
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
    final firstDate = DateTime.now().subtract(
      const Duration(days: 365 * 5),
    ); // Позволяем выбрать дату в прошлом для редактирования
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
        title: const Text('Редактирование препарата'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      // Добавляем плавающую кнопку для быстрого доступа к функции сохранения
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _updateMedication,
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
                        onPressed: _updateMedication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Сохранить изменения',
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
