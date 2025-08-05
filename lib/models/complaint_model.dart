class ComplaintModel {
  final int? complaintId;
  final int houseId;
  final int typeComplaint;
  final String createAt;
  final String header;
  final String description;
  final int level;
  final bool isPrivate;
  late final String? img;
  final String? status;
  final String? updateAt;

  ComplaintModel({
    this.complaintId,
    required this.houseId,
    required this.typeComplaint,
    required this.createAt,
    required this.header,
    required this.description,
    required this.level,
    required this.isPrivate,
    this.img,
    this.status,
    this.updateAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      complaintId: json['complaint_id'] ?? 0,
      houseId: json['house_id'] ?? 0,
      typeComplaint: json['type_complaint'] ?? 0,
      createAt: json['create_at'] ?? "",
      header: json['header'] ?? "",
      description: json['description'] ?? "",
      level: json['level'] ?? 0,
      isPrivate: json['private'] ?? false,
      img: (json['img'] == "null" || json['img'] == null) ? null : json['img'],
      status: (json['status'] == "null" || json['status'] == null)
          ? null
          : json['status'],
      updateAt: json['update_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaint_id': complaintId,
      'house_id': houseId,
      'type_complaint': typeComplaint,
      'create_at': createAt,
      'header': header,
      'description': description,
      'level': level,
      'private': isPrivate,
      'img': img,
      'status': status,
      'update_at': updateAt,
    };
  }
}
