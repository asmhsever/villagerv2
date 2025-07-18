// lib/models/complaint_model.dart

class ComplaintModel {
  final int id;
  final int houseId;
  final int typeComplaint;
  final DateTime date;
  final String header;
  final String description;
  final int level;
  final bool isPrivate;
  final String? img;
  final String status;

  ComplaintModel({
    required this.id,
    required this.houseId,
    required this.typeComplaint,
    required this.date,
    required this.header,
    required this.description,
    required this.level,
    required this.isPrivate,
    this.img,
    required this.status,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    return ComplaintModel(
      id: map['complaint_id'] as int,
      houseId: map['house_id'] as int,
      typeComplaint: map['type_complaint'] as int,
      date: DateTime.parse(map['date']),
      header: map['header'] ?? '',
      description: map['description'] ?? '',
      level: map['level'] as int,
      isPrivate: map['private'] ?? false,
      img: map['img'],
      status: map['status_complaint'] ?? 'รอดำเนินการ',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'complaint_id': id,
      'house_id': houseId,
      'type_complaint': typeComplaint,
      'date': date.toIso8601String(),
      'header': header,
      'description': description,
      'level': level,
      'private': isPrivate,
      'img': img,
      'status_complaint': status,
    };
  }
}
