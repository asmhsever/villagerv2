class NotionModel {
  final int notionId;
  final int lawId;
  final int villageId;
  final String? header;
  final String? description;
  final DateTime? createDate;
  final String? img;

  NotionModel({
    required this.notionId,
    required this.lawId,
    required this.villageId,
    this.header,
    this.description,
    this.createDate,
    this.img,
  });

  factory NotionModel.fromJson(Map<String, dynamic> json) {
    return NotionModel(
      notionId: json['notion_id'] ?? 0,
      lawId: json['law_id'] ?? 0,
      villageId: json['village_id'] ?? 0,
      header: json['header'] ?? "",
      description: json['description'] ?? "",
      createDate: DateTime.parse(json['created_at']),
      img: json['img'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notion_id': notionId,
      'law_id': lawId,
      'village_id': villageId,
      'header': header,
      'description': description,
      'created_at': createDate,
      'img': img,
    };
  }
}
