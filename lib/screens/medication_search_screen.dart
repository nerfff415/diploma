import 'package:flutter/material.dart';
import '../services/medication_search_service.dart';
import '../models/medication.dart';

// Параметры сортировки
enum SortOption {
  nameAsc,
  nameDesc,
  expiryDateAsc,
  expiryDateDesc,
  quantityAsc,
  quantityDesc,
}

class MedicationSearchScreen extends StatefulWidget {
  const MedicationSearchScreen({Key? key}) : super(key: key);

  @override
  State<MedicationSearchScreen> createState() => _MedicationSearchScreenState();
}

class _MedicationSearchScreenState extends State<MedicationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MedicationSearchService _searchService = MedicationSearchService();

  List<MedicationSearchResult> _searchResults = [];
  List<MedicationSearchResult> _filteredResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Выбранная категория для фильтрации
  MedicationCategory? _selectedCategory;

  // Выбранная форма выпуска для фильтрации
  MedicationForm? _selectedForm;

  // Список всех категорий для фильтрации
  final List<MedicationCategory> _allCategories = MedicationCategory.values;

  // Список всех форм выпуска для фильтрации
  final List<MedicationForm> _allForms = MedicationForm.values;

  SortOption _currentSortOption = SortOption.nameAsc;

  // Получение названия параметра сортировки
  String get _sortOptionName {
    switch (_currentSortOption) {
      case SortOption.nameAsc:
        return 'По названию (А-Я)';
      case SortOption.nameDesc:
        return 'По названию (Я-А)';
      case SortOption.expiryDateAsc:
        return 'По сроку годности (сначала ближайшие)';
      case SortOption.expiryDateDesc:
        return 'По сроку годности (сначала дальние)';
      case SortOption.quantityAsc:
        return 'По количеству (по возрастанию)';
      case SortOption.quantityDesc:
        return 'По количеству (по убыванию)';
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Обработчик изменения текста в поле поиска
  void _onSearchChanged() {
    if (_searchController.text.length >= 2) {
      _performSearch(_searchController.text);
    } else if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredResults = [];
      });
    }
  }

  // Выполнение поиска
  Future<void> _performSearch(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _searchService.searchMedications(query);
      setState(() {
        _searchResults = results;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при поиске: $e';
        _isLoading = false;
      });
    }
  }

  // Применение фильтров к результатам поиска
  void _applyFilters() {
    _filteredResults = List.from(_searchResults);

    // Фильтрация по категории
    if (_selectedCategory != null) {
      _filteredResults =
          _filteredResults.where((result) {
            final category = MedicationCategoryExtension.fromString(
              result.medication.category,
            );
            return category == _selectedCategory;
          }).toList();
    }

    // Фильтрация по форме выпуска
    if (_selectedForm != null) {
      _filteredResults =
          _filteredResults.where((result) {
            final form = MedicationFormExtension.fromString(
              result.medication.form,
            );
            return form == _selectedForm;
          }).toList();
    }

    // Сортировка результатов
    _sortResults();
  }

  // Сортировка результатов
  void _sortResults() {
    switch (_currentSortOption) {
      case SortOption.nameAsc:
        _filteredResults.sort(
          (a, b) => a.medication.name.compareTo(b.medication.name),
        );
        break;
      case SortOption.nameDesc:
        _filteredResults.sort(
          (a, b) => b.medication.name.compareTo(a.medication.name),
        );
        break;
      case SortOption.expiryDateAsc:
        _filteredResults.sort(
          (a, b) => a.medication.expiryDate.compareTo(b.medication.expiryDate),
        );
        break;
      case SortOption.expiryDateDesc:
        _filteredResults.sort(
          (a, b) => b.medication.expiryDate.compareTo(a.medication.expiryDate),
        );
        break;
      case SortOption.quantityAsc:
        _filteredResults.sort(
          (a, b) => a.medication.quantity.compareTo(b.medication.quantity),
        );
        break;
      case SortOption.quantityDesc:
        _filteredResults.sort(
          (a, b) => b.medication.quantity.compareTo(a.medication.quantity),
        );
        break;
    }
  }

  // Изменение параметра сортировки
  void _changeSortOption(SortOption option) {
    setState(() {
      _currentSortOption = option;
      _applyFilters();
    });
  }

  // Сброс фильтров
  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedForm = null;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск медикаментов'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка сортировки
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortDialog();
            },
          ),
          // Кнопка фильтров
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Введите название медикамента',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _filteredResults = [];
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),

          // Отображение активных фильтров и сортировки
          if (_selectedCategory != null ||
              _selectedForm != null ||
              _currentSortOption != SortOption.nameAsc)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text(
                    'Сортировка: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      _sortOptionName,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Отображение активных фильтров
          _buildActiveFilters(),

          // Индикатор загрузки или сообщение об ошибке
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Результаты поиска
          Expanded(
            child:
                _filteredResults.isEmpty
                    ? Center(
                      child:
                          _searchController.text.length < 2
                              ? const Text(
                                'Введите не менее 2 символов для поиска',
                              )
                              : _searchResults.isEmpty
                              ? const Text('Ничего не найдено')
                              : const Text(
                                'Нет результатов, соответствующих фильтрам',
                              ),
                    )
                    : ListView.builder(
                      itemCount: _filteredResults.length,
                      itemBuilder: (context, index) {
                        final result = _filteredResults[index];
                        return _buildMedicationCard(result);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Отображение активных фильтров
  Widget _buildActiveFilters() {
    if (_selectedCategory == null && _selectedForm == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Активные фильтры:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8.0,
            children: [
              if (_selectedCategory != null)
                Chip(
                  label: Text('Категория: ${_selectedCategory!.name}'),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() {
                      _selectedCategory = null;
                      _applyFilters();
                    });
                  },
                ),
              if (_selectedForm != null)
                Chip(
                  label: Text('Форма: ${_selectedForm!.name}'),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() {
                      _selectedForm = null;
                      _applyFilters();
                    });
                  },
                ),
              Chip(
                label: const Text('Сбросить все'),
                deleteIcon: const Icon(Icons.refresh, size: 18),
                onDeleted: _resetFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Диалог выбора фильтров
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Фильтры'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Категория:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children:
                          _allCategories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return FilterChip(
                              label: Text(category.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    _selectedCategory = category;
                                  } else {
                                    _selectedCategory = null;
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Форма выпуска:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children:
                          _allForms.map((form) {
                            final isSelected = _selectedForm == form;
                            return FilterChip(
                              label: Text(form.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    _selectedForm = form;
                                  } else {
                                    _selectedForm = null;
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _applyFilters();
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Применить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Диалог выбора сортировки
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Сортировка'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<SortOption>(
                  title: const Text('По названию (А-Я)'),
                  value: SortOption.nameAsc,
                  groupValue: _currentSortOption,
                  onChanged: (value) {
                    Navigator.of(context).pop();
                    if (value != null) _changeSortOption(value);
                  },
                ),
                RadioListTile<SortOption>(
                  title: const Text('По названию (Я-А)'),
                  value: SortOption.nameDesc,
                  groupValue: _currentSortOption,
                  onChanged: (value) {
                    Navigator.of(context).pop();
                    if (value != null) _changeSortOption(value);
                  },
                ),
                RadioListTile<SortOption>(
                  title: const Text('По сроку годности (сначала ближайшие)'),
                  value: SortOption.expiryDateAsc,
                  groupValue: _currentSortOption,
                  onChanged: (value) {
                    Navigator.of(context).pop();
                    if (value != null) _changeSortOption(value);
                  },
                ),
                RadioListTile<SortOption>(
                  title: const Text('По сроку годности (сначала дальние)'),
                  value: SortOption.expiryDateDesc,
                  groupValue: _currentSortOption,
                  onChanged: (value) {
                    Navigator.of(context).pop();
                    if (value != null) _changeSortOption(value);
                  },
                ),
                RadioListTile<SortOption>(
                  title: const Text('По количеству (по возрастанию)'),
                  value: SortOption.quantityAsc,
                  groupValue: _currentSortOption,
                  onChanged: (value) {
                    Navigator.of(context).pop();
                    if (value != null) _changeSortOption(value);
                  },
                ),
                RadioListTile<SortOption>(
                  title: const Text('По количеству (по убыванию)'),
                  value: SortOption.quantityDesc,
                  groupValue: _currentSortOption,
                  onChanged: (value) {
                    Navigator.of(context).pop();
                    if (value != null) _changeSortOption(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Карточка медикамента
  Widget _buildMedicationCard(MedicationSearchResult result) {
    final medication = result.medication;
    final form = MedicationFormExtension.fromString(medication.form);
    final category = MedicationCategoryExtension.fromString(
      medication.category,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(form.icon, color: Colors.white),
        ),
        title: Text(
          medication.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Форма: ${form.name}'),
            Text('Категория: ${category.name}'),
            Text(
              'Аптечка: ${result.kitName}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (result.groupName != null)
              Text(
                'Группа: ${result.groupName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            Text(
              'Срок годности: ${_formatDate(medication.expiryDate)}',
              style: TextStyle(
                color:
                    _isExpiringSoon(medication.expiryDate) ? Colors.red : null,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${medication.quantity} ${medication.dimension}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        onTap: () => _navigateToMedicationDetails(medication),
      ),
    );
  }

  // Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Проверка, истекает ли срок годности в ближайшее время
  bool _isExpiringSoon(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference <= 30; // Срок годности истекает в течение 30 дней
  }

  // Навигация к деталям медикамента
  void _navigateToMedicationDetails(Medication medication) {
    // Здесь будет навигация к экрану деталей медикамента
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Просмотр деталей медикамента: ${medication.name}'),
      ),
    );
  }
}
