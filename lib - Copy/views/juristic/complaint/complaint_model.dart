/// lib/views/juristic/complaint/complaint_model.dart

class Complaint {
  final int complaintId;
  final int houseId;
  final int typeComplaintId;
  final String? typeName;
  final DateTime date;
  final String header;
  final String description;
  final bool status;
  final int levelId;
  final bool isPrivate;

  Complaint({
    required this.complaintId,
    required this.houseId,
    required this.typeComplaintId,
    required this.date,
    required this.header,
    required this.description,
    required this.status,
    required this.levelId,
    required this.isPrivate,
    this.typeName,
  });

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      complaintId: map['complaint_id'] as int,
      houseId: map['house_id'] as int,
      typeComplaintId: map['type_complaint'] is int
          ? map['type_complaint']
          : map['type_complaint']['type_id'] as int,
      typeName: map['type_complaint'] is Map ? map['type_complaint']['type'] : null,
      date: DateTime.parse(map['date']),
      header: map['header'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? false,
      levelId: map['level'] as int,
      isPrivate: map['private'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'complaint_id': complaintId,
      'house_id': houseId,
      'type_complaint': typeComplaintId,
      'date': date.toIso8601String(),
      'header': header,
      'description': description,
      'status': status,
      'level': levelId,
      'private': isPrivate,
    };
  }
}