import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Перечисление для форм выпуска
enum MedicationForm {
  tablets,
  capsules,
  syrup,
  ampoules,
  ointment,
  drops,
  powder,
  spray,
}

// Перечисление для категорий препаратов
enum MedicationCategory {
  cold, // Простуда
  pain, // Боль
  allergy, // Аллергия
  digestive, // ЖКТ
  heart, // Сердце
  vitamins, // Витамины
  other, // Другое
}

// Перечисление для размерностей
enum MedicationDimension {
  mg, // миллиграммы
  g, // граммы
  mcg, // микрограммы
  ml, // миллилитры
  l, // литры
  pcs, // штуки
  tab, // таблетки
  drops, // капли
  units, // единицы
}

// Расширение для получения понятных названий форм выпуска на русском
extension MedicationFormExtension on MedicationForm {
  String get name {
    switch (this) {
      case MedicationForm.tablets:
        return 'Таблетки';
      case MedicationForm.capsules:
        return 'Капсулы';
      case MedicationForm.syrup:
        return 'Сироп';
      case MedicationForm.ampoules:
        return 'Ампулы';
      case MedicationForm.ointment:
        return 'Мазь';
      case MedicationForm.drops:
        return 'Капли';
      case MedicationForm.powder:
        return 'Порошок';
      case MedicationForm.spray:
        return 'Спрей';
    }
  }

  IconData get icon {
    switch (this) {
      case MedicationForm.tablets:
        return Icons.circle;
      case MedicationForm.capsules:
        return Icons.panorama_fish_eye;
      case MedicationForm.syrup:
        return Icons.local_drink;
      case MedicationForm.ampoules:
        return Icons.medication_liquid;
      case MedicationForm.ointment:
        return Icons.healing;
      case MedicationForm.drops:
        return Icons.opacity;
      case MedicationForm.powder:
        return Icons.grain;
      case MedicationForm.spray:
        return Icons.shower;
    }
  }

  static MedicationForm fromString(String value) {
    return MedicationForm.values.firstWhere(
      (form) => form.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MedicationForm.tablets,
    );
  }
}

// Расширение для получения понятных названий категорий на русском
extension MedicationCategoryExtension on MedicationCategory {
  String get name {
    switch (this) {
      case MedicationCategory.cold:
        return 'Простуда';
      case MedicationCategory.pain:
        return 'Боль';
      case MedicationCategory.allergy:
        return 'Аллергия';
      case MedicationCategory.digestive:
        return 'ЖКТ';
      case MedicationCategory.heart:
        return 'Сердце';
      case MedicationCategory.vitamins:
        return 'Витамины';
      case MedicationCategory.other:
        return 'Другое';
    }
  }

  IconData get icon {
    switch (this) {
      case MedicationCategory.cold:
        return Icons.sick;
      case MedicationCategory.pain:
        return Icons.healing;
      case MedicationCategory.allergy:
        return Icons.air;
      case MedicationCategory.digestive:
        return Icons.restaurant;
      case MedicationCategory.heart:
        return Icons.favorite;
      case MedicationCategory.vitamins:
        return Icons.fitness_center;
      case MedicationCategory.other:
        return Icons.more_horiz;
    }
  }

  static MedicationCategory fromString(String value) {
    return MedicationCategory.values.firstWhere(
      (category) => category.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MedicationCategory.other,
    );
  }
}

// Расширение для получения понятных названий размерностей на русском
extension MedicationDimensionExtension on MedicationDimension {
  String get name {
    switch (this) {
      case MedicationDimension.mg:
        return 'мг';
      case MedicationDimension.g:
        return 'г';
      case MedicationDimension.mcg:
        return 'мкг';
      case MedicationDimension.ml:
        return 'мл';
      case MedicationDimension.l:
        return 'л';
      case MedicationDimension.pcs:
        return 'шт';
      case MedicationDimension.tab:
        return 'табл';
      case MedicationDimension.drops:
        return 'кап';
      case MedicationDimension.units:
        return 'ед';
    }
  }

  static MedicationDimension fromString(String value) {
    return MedicationDimension.values.firstWhere(
      (dimension) => dimension.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MedicationDimension.pcs,
    );
  }
}

class Medication {
  final String id;
  final String kitId; // ID аптечки, к которой относится препарат
  final String name;
  final String form;
  final double quantity;
  final String dimension;
  final DateTime expiryDate;
  final String category;
  final String? description;
  final String? barcode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    required this.id,
    required this.kitId,
    required this.name,
    required this.form,
    required this.quantity,
    required this.dimension,
    required this.expiryDate,
    required this.category,
    this.description,
    this.barcode,
    required this.createdAt,
    required this.updatedAt,
  });

  // Создание копии с возможностью изменения полей
  Medication copyWith({
    String? id,
    String? kitId,
    String? name,
    String? form,
    double? quantity,
    String? dimension,
    DateTime? expiryDate,
    String? category,
    String? description,
    String? barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      kitId: kitId ?? this.kitId,
      name: name ?? this.name,
      form: form ?? this.form,
      quantity: quantity ?? this.quantity,
      dimension: dimension ?? this.dimension,
      expiryDate: expiryDate ?? this.expiryDate,
      category: category ?? this.category,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Создание из данных Firestore
  factory Medication.fromFirestore(Map<String, dynamic> data, String docId) {
    return Medication(
      id: docId,
      kitId: data['kitId'] ?? '',
      name: data['name'] ?? '',
      form: data['form'] ?? MedicationForm.tablets.name,
      quantity: (data['quantity'] ?? 0).toDouble(),
      dimension: data['dimension'] ?? MedicationDimension.pcs.name,
      expiryDate:
          data['expiryDate'] != null
              ? (data['expiryDate'] is Timestamp
                  ? (data['expiryDate'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['expiryDate']))
              : DateTime.now().add(const Duration(days: 365)),
      category: data['category'] ?? MedicationCategory.other.name,
      description: data['description'],
      barcode: data['barcode'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['createdAt']))
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] is Timestamp
                  ? (data['updatedAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['updatedAt']))
              : DateTime.now(),
    );
  }

  // Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'kitId': kitId,
      'name': name,
      'form': form,
      'quantity': quantity,
      'dimension': dimension,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'category': category,
      'description': description,
      'barcode': barcode,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Получение формы выпуска как enum
  MedicationForm get formEnum => MedicationFormExtension.fromString(form);

  // Получение категории как enum
  MedicationCategory get categoryEnum =>
      MedicationCategoryExtension.fromString(category);

  // Получение размерности как enum
  MedicationDimension get dimensionEnum =>
      MedicationDimensionExtension.fromString(dimension);

  // Получение строки с количеством и размерностью
  String get quantityWithDimension => '$quantity ${dimensionEnum.name}';
}
