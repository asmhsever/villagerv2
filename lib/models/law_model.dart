import 'package:flutter/material.dart';

class LawModel {
  final int lawId;
  final int villageId;
  final int userId;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? phone;
  final String? gender;
  final String? address;
  final String? img;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  LawModel({
    required this.lawId,
    required this.villageId,
    required this.userId,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.phone,
    this.gender,
    this.address,
    this.img,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  // ========== Factory Constructors ==========

  factory LawModel.fromJson(Map<String, dynamic> json) {
    return LawModel(
      lawId: json['law_id'] ?? 0,
      villageId: json['village_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      firstName: json['first_name'],
      lastName: json['last_name'],
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'].toString())
          : null,
      phone: json['phone'],
      gender: json['gender'],
      address: json['address'],
      img: json['img'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'].toString())
          : null,
    );
  }

  factory LawModel.fromSessionJson(Map<String, dynamic> json) {
    return LawModel(
      lawId: json['law_id'] ?? 0,
      villageId: json['village_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  /// สร้าง LawModel ว่าง (สำหรับฟอร์มใหม่)
  factory LawModel.empty({
    required int villageId,
    required int userId,
  }) {
    return LawModel(
      lawId: 0,
      villageId: villageId,
      userId: userId,
    );
  }

  // ========== JSON Serialization ==========

  Map<String, dynamic> toJson() {
    return {
      'law_id': lawId,
      'village_id': villageId,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate?.toIso8601String(),
      'phone': phone,
      'gender': gender,
      'address': address,
      'img': img,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  /// JSON สำหรับ session (เฉพาะข้อมูลสำคัญ)
  Map<String, dynamic> toSessionJson() {
    return {
      'law_id': lawId,
      'village_id': villageId,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
    };
  }

  /// JSON สำหรับอัปเดต (ไม่รวม ID และ timestamp)
  Map<String, dynamic> toUpdateJson() {
    final json = <String, dynamic>{};

    if (firstName != null) json['first_name'] = firstName;
    if (lastName != null) json['last_name'] = lastName;
    if (birthDate != null) json['birth_date'] = birthDate!.toIso8601String();
    if (phone != null) json['phone'] = phone;
    if (gender != null) json['gender'] = gender;
    if (address != null) json['address'] = address;
    if (img != null) json['img'] = img;

    // เพิ่ม updated_at อัตโนมัติ
    json['updated_at'] = DateTime.now().toIso8601String();

    return json;
  }

  // ========== CopyWith Method ==========

  LawModel copyWith({
    int? lawId,
    int? villageId,
    int? userId,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? phone,
    String? gender,
    String? address,
    String? img,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return LawModel(
      lawId: lawId ?? this.lawId,
      villageId: villageId ?? this.villageId,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      img: img ?? this.img,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  /// CopyWith พิเศษสำหรับอัปเดตเฉพาะข้อมูลโปรไฟล์
  LawModel copyWithProfile({
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? phone,
    String? gender,
    String? address,
  }) {
    return copyWith(
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      phone: phone,
      gender: gender,
      address: address,
      updatedAt: DateTime.now(),
    );
  }

  /// CopyWith สำหรับอัปเดตรูปโปรไฟล์
  LawModel copyWithImage(String imageUrl) {
    return copyWith(
      img: imageUrl,
      updatedAt: DateTime.now(),
    );
  }

  // ========== Computed Properties ==========

  /// ชื่อเต็ม
  String get fullName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';

    if (first.isEmpty && last.isEmpty) return 'ไม่ระบุชื่อ';
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;

    return '$first $last';
  }

  /// ชื่อย่อ (อักษรตัวแรกของชื่อ-นามสกุล)
  String get initials {
    final first = firstName?.trim().isNotEmpty == true
        ? firstName!.trim()[0].toUpperCase()
        : '';
    final last = lastName?.trim().isNotEmpty == true
        ? lastName!.trim()[0].toUpperCase()
        : '';

    if (first.isEmpty && last.isEmpty) return '?';
    return '$first$last';
  }

  /// อายุ (จากวันเกิด)
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;

    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }

    return age;
  }

  /// เพศแบบเต็ม
  String get genderDisplay {
    switch (gender?.toLowerCase()) {
      case 'm':
      case 'male':
        return 'ชาย';
      case 'f':
      case 'female':
        return 'หญิง';
      case 'o':
      case 'other':
        return 'อื่นๆ';
      default:
        return 'ไม่ระบุ';
    }
  }

  /// URL รูปโปรไฟล์แบบเต็ม
  String? get profileImageUrl {
    if (img == null || img!.isEmpty) return null;
    // สามารถเพิ่ม base URL ได้ตรงนี้
    return img;
  }

  /// เช็คว่ามีรูปโปรไฟล์หรือไม่
  bool get hasProfileImage => img != null && img!.isNotEmpty;

  // ========== Validation Methods ==========

  /// ตรวจสอบความถูกต้องของข้อมูลพื้นฐาน
  ValidationResult validateBasicInfo() {
    final errors = <String>[];

    // ชื่อ
    if (firstName == null || firstName!.trim().isEmpty) {
      errors.add('กรุณาระบุชื่อจริง');
    } else if (firstName!.trim().length < 2) {
      errors.add('ชื่อจริงต้องมีอย่างน้อย 2 ตัวอักษร');
    }

    // นามสกุล
    if (lastName == null || lastName!.trim().isEmpty) {
      errors.add('กรุณาระบุนามสกุล');
    } else if (lastName!.trim().length < 2) {
      errors.add('นามสกุลต้องมีอย่างน้อย 2 ตัวอักษร');
    }

    // เบอร์โทร
    if (phone == null || phone!.trim().isEmpty) {
      errors.add('กรุณาระบุเบอร์โทรศัพท์');
    } else if (!isValidPhone(phone!.trim())) {
      errors.add('รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// ตรวจสอบรูปแบบเบอร์โทร
  bool isValidPhone(String phone) {
    // เบอร์โทรไทย: 10 หลัก เริ่มต้นด้วย 0
    final phoneRegex = RegExp(r'^0[0-9]{9}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''));
  }

  /// ตรวจสอบอายุ
  bool isValidAge() {
    if (age == null) return false;
    return age! >= 18 && age! <= 100;
  }

  /// เช็คความสมบูรณ์ของโปรไฟล์
  ProfileCompleteness getProfileCompleteness() {
    int completed = 0;
    int total = 7;
    final missing = <String>[];

    // ชื่อ
    if (firstName != null && firstName!.trim().isNotEmpty) {
      completed++;
    } else {
      missing.add('ชื่อจริง');
    }

    // นามสกุล
    if (lastName != null && lastName!.trim().isNotEmpty) {
      completed++;
    } else {
      missing.add('นามสกุล');
    }

    // เบอร์โทร
    if (phone != null && phone!.trim().isNotEmpty) {
      completed++;
    } else {
      missing.add('เบอร์โทรศัพท์');
    }

    // ที่อยู่
    if (address != null && address!.trim().isNotEmpty) {
      completed++;
    } else {
      missing.add('ที่อยู่');
    }

    // วันเกิด
    if (birthDate != null) {
      completed++;
    } else {
      missing.add('วันเกิด');
    }

    // เพศ
    if (gender != null && gender!.trim().isNotEmpty) {
      completed++;
    } else {
      missing.add('เพศ');
    }

    // รูปโปรไฟล์
    if (hasProfileImage) {
      completed++;
    } else {
      missing.add('รูปโปรไฟล์');
    }

    return ProfileCompleteness(
      completed: completed,
      total: total,
      percentage: ((completed / total) * 100).round(),
      missingFields: missing,
      isComplete: completed == total,
    );
  }

  // ========== Display Formatters ==========

  /// วันเกิดในรูปแบบที่อ่านง่าย
  String get birthDateDisplay {
    if (birthDate == null) return 'ไม่ระบุ';

    final months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];

    final day = birthDate!.day;
    final month = months[birthDate!.month];
    final year = birthDate!.year + 543; // แปลงเป็น พ.ศ.

    return '$day $month $year';
  }

  /// เวลาเข้าสู่ระบบล่าสุด
  String get lastLoginDisplay {
    if (lastLogin == null) return 'ไม่เคยเข้าสู่ระบบ';

    final now = DateTime.now();
    final diff = now.difference(lastLogin!);

    if (diff.inMinutes < 1) return 'เพิ่งเข้าสู่ระบบ';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';

    return 'นานแล้ว';
  }

  // ========== Equality & Hash ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LawModel && other.lawId == lawId;
  }

  @override
  int get hashCode => lawId.hashCode;

  @override
  String toString() {
    return 'LawModel(lawId: $lawId, fullName: $fullName, villageId: $villageId)';
  }
}

// ========== Helper Classes ==========

/// ผลลัพธ์การ validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });

  String get errorMessage => errors.join('\n');
}

/// ข้อมูลความสมบูรณ์ของโปรไฟล์
class ProfileCompleteness {
  final int completed;
  final int total;
  final int percentage;
  final List<String> missingFields;
  final bool isComplete;

  ProfileCompleteness({
    required this.completed,
    required this.total,
    required this.percentage,
    required this.missingFields,
    required this.isComplete,
  });

  String get statusText {
    if (isComplete) return 'ข้อมูลครบถ้วน';
    return 'ข้อมูลไม่ครบ ($completed/$total)';
  }

  Color get statusColor {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}