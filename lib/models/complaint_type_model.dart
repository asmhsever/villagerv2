class ComplaintTypeModel {
  final int typeId;
  final String? type;

  ComplaintTypeModel({required this.typeId, this.type});

  factory ComplaintTypeModel.fromJson(Map<String, dynamic> json) {
    return ComplaintTypeModel(typeId: json['type_id'], type: json['type']);
  }

  Map<String, dynamic> toJson() {
    return {'type_id': typeId, 'type': type};
  }
}
