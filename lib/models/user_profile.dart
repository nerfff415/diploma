import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? phoneNumber;
  final DateTime? birthDate;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.phoneNumber,
    this.birthDate,
    required this.email,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate?.millisecondsSinceEpoch,
      'email': email,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      userId: uid,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      middleName: map['middleName'],
      phoneNumber: map['phoneNumber'],
      birthDate:
          map['birthDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['birthDate'])
              : null,
      email: map['email'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : null,
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : null,
    );
  }

  // Создание копии объекта с обновленными полями
  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? middleName,
    String? phoneNumber,
    DateTime? birthDate,
    String? email,
  }) {
    return UserProfile(
      userId: this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
