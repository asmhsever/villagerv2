class SuccessComplaintModel {
  final int? id;
  final int? lawId;
  final int? complaintId;
  final String? description;
  final String? img;
  final DateTime? successAt;

  SuccessComplaintModel({
    this.id,
    this.lawId,
    this.complaintId,
    this.description,
    this.img,
    this.successAt,
  });

  // Factory constructor for creating from JSON
  factory SuccessComplaintModel.fromJson(Map<String, dynamic> json) {
    return SuccessComplaintModel(
      id: json['id'] as int?,
      lawId: json['law_id'] as int?,
      complaintId: json['complaint_id'] as int?,
      description: json['description'] as String?,
      img: json['img'] as String?,
      successAt: json['success_at'] != null
          ? DateTime.parse(json['success_at'])
          : null,
    );
  }

  // Method for converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'law_id': lawId,
      'complaint_id': complaintId,
      'description': description,
      'img': img,
      'success_at': successAt?.toIso8601String(),
    };
  }
}
