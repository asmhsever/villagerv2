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
      header: json['header'] as String?,
      description: json['description'] as String?,
      createDate: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      img: json['img'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notion_id': notionId,
      'law_id': lawId,
      'village_id': villageId,
      'header': header,
      'description': description,
      'created_at': createDate?.toIso8601String(),
      'img': img,
    };
  }
}
