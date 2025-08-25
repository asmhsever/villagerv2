class FundModel {
  final int fundId;
  final int villageId;
  final String type;
  final double amount;
  final String description;
  final DateTime? createdAt;
  final String? receiptImg;

  FundModel({
    required this.fundId,
    required this.villageId,
    required this.type,
    required this.amount,
    required this.description,
    this.createdAt,
    this.receiptImg,
  });

  factory FundModel.fromJson(Map<String, dynamic> json) {
    return FundModel(
      fundId: json['fund_id'] ?? 0,
      villageId: json['village_id'] ?? 0,
      type: json['type'] ?? "",
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? "",
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      receiptImg: json['receipt_img'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fund_id': fundId,
      'village_id': villageId,
      'type': type,
      'amount': amount,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'receipt_img': receiptImg,
    };
  }
}
