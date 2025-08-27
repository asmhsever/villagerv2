// lib/models/committee_model.dart

/// Data model for a committee member.
/// - `committeeId` may be null when creating; domain will assign it.
class CommitteeModel {
  final int? villageId;
  final int? houseId;
  final int? committeeId;

  const CommitteeModel({this.villageId, this.houseId, this.committeeId});

  factory CommitteeModel.fromJson(Map<String, dynamic> json) {
    return CommitteeModel(
      villageId: json['village_id'] as int?,
      houseId: json['house_id'] as int?,
      committeeId: json['committee_id'] as int?,
    );
  }

  /// Exclude `committee_id` when null to avoid NOT NULL constraint errors
  /// and let the domain/database generate it.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'village_id': villageId,
      'house_id': houseId,
    };
    if (committeeId != null) {
      map['committee_id'] = committeeId;
    }
    return map;
  }

  CommitteeModel copyWith({int? villageId, int? houseId, int? committeeId}) {
    return CommitteeModel(
      villageId: villageId ?? this.villageId,
      houseId: houseId ?? this.houseId,
      committeeId: committeeId ?? this.committeeId,
    );
  }

  @override
  String toString() =>
      'CommitteeModel(villageId: ' + (villageId?.toString() ?? 'null') +
          ', houseId: ' + (houseId?.toString() ?? 'null') +
          ', committeeId: ' + (committeeId?.toString() ?? 'null') + ')';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommitteeModel &&
        other.villageId == villageId &&
        other.houseId == houseId &&
        other.committeeId == committeeId;
  }

  @override
  int get hashCode => Object.hash(villageId, houseId, committeeId);
}
