class CommitteeModel {
  final int? villageId;
  final int? houseId;
  final int? committeeId;

  CommitteeModel({this.villageId, this.houseId, this.committeeId});

  // Factory constructor for creating from JSON
  factory CommitteeModel.fromJson(Map<String, dynamic> json) {
    return CommitteeModel(
      villageId: json['village_id'] as int?,
      houseId: json['house_id'] as int?,
      committeeId: json['committee_id'] as int?,
    );
  }

  // Method for converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'village_id': villageId,
      'house_id': houseId,
      'committee_id': committeeId,
    };
  }
}
