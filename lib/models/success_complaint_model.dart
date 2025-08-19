// lib/models/success_complaint_model.dart
class SuccessComplaintModel {
  final int? id;
  final int lawId;
  final int complaintId;
  final String description;
  final String? img;
  final String successAt;

  SuccessComplaintModel({
    this.id,
    required this.lawId,
    required this.complaintId,
    required this.description,
    this.img,
    required this.successAt,
  });

  factory SuccessComplaintModel.fromJson(Map<String, dynamic> json) {
    return SuccessComplaintModel(
      id: json['id'] ?? 0,
      lawId: json['law_id'] ?? 0,
      complaintId: json['complaint_id'] ?? 0,
      description: json['description'] ?? "",
      img: (json['img'] == "null" || json['img'] == null) ? null : json['img'],
      successAt: json['success_at'] ?? "", // ใช้ success_at ที่ถูกต้อง
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'law_id': lawId,
      'complaint_id': complaintId,
      'description': description,
      'img': img,
      'success_at': successAt, // ใช้ success_at ที่ถูกต้อง
    };
  }
}