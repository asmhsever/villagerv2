// แก้ไข ComplaintModel ให้ถูกต้องก่อน
class ComplaintModel {
  final int? complaintId;
  final int houseId;
  final int typeComplaint;
  final String createAt;
  final String header;
  final String description;
  final String level;
  final bool isPrivate;
  final String? complaintImg; // เปลี่ยนชื่อให้ตรง
  final String? status;
  final String? updateAt;
  final int? resolvedByLawId; // เพิ่ม field ที่หายไป
  final String? resolvedDescription; // เพิ่ม field ที่หายไป
  final String? resolvedImg; // เพิ่ม field ที่หายไป

  ComplaintModel({
    this.complaintId,
    required this.houseId,
    required this.typeComplaint,
    required this.createAt,
    required this.header,
    required this.description,
    required this.level,
    required this.isPrivate,
    this.complaintImg,
    this.status,
    this.updateAt,
    this.resolvedByLawId, // เพิ่มใน constructor
    this.resolvedDescription, // เพิ่มใน constructor
    this.resolvedImg, // เพิ่มใน constructor
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      complaintId: json['complaint_id'] ?? 0,
      houseId: json['house_id'] ?? 0,
      typeComplaint: json['type_complaint'] ?? 0,
      createAt: json['create_at'] ?? "",
      header: json['header'] ?? "",
      description: json['description'] ?? "",
      level: json['level'] ?? "",
      isPrivate: json['private'] ?? false,
      complaintImg:
          (json['complaint_img'] == "null" || json['complaint_img'] == null)
          ? null
          : json['complaint_img'],
      // แก้ชื่อ field
      status: (json['status'] == "null" || json['status'] == null)
          ? null
          : json['status'],
      updateAt: json['update_at'],
      resolvedByLawId: json['resolved_by_law_id'],
      // เพิ่ม field
      resolvedDescription:
          (json['resolved_description'] == "null" ||
              json['resolved_description'] == null)
          ? null
          : json['resolved_description'],
      // เพิ่ม field
      resolvedImg:
          (json['resolved_img'] == "null" || json['resolved_img'] == null)
          ? null
          : json['resolved_img'], // เพิ่ม field
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
      'complaint_img': complaintImg, // แก้ชื่อ field
      'status': status,
      'update_at': updateAt,
      'resolved_by_law_id': resolvedByLawId, // เพิ่ม field
      'resolved_description': resolvedDescription, // เพิ่ม field
      'resolved_img': resolvedImg, // เพิ่ม field
    };
  }
}
