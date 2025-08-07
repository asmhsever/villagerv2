class BillModel {
  final int billId;
  final int houseId;
  final DateTime billDate;
  final double amount;
  final int paidStatus;
  final DateTime? paidDate;
  final String? paidMethod;
  final int service;
  final DateTime dueDate;
  final String? referenceNo;
  final String? paidImg; // เพิ่มฟิลด์นี้

  BillModel({
    required this.billId,
    required this.houseId,
    required this.billDate,
    required this.amount,
    required this.paidStatus,
    this.paidDate,
    this.paidMethod,
    required this.service,
    required this.dueDate,
    this.referenceNo,
    this.paidImg, // เพิ่มใน constructor
  });

  BillModel copyWith({
    int? billId,
    int? houseId,
    DateTime? billDate,
    double? amount,
    int? paidStatus,
    DateTime? paidDate,
    String? paidMethod,
    int? service,
    Map<String, dynamic>? serviceObj,
    DateTime? dueDate,
    String? referenceNo,
  }) {
    return BillModel(
      billId: billId ?? this.billId,
      houseId: houseId ?? this.houseId,
      billDate: billDate ?? this.billDate,
      amount: amount ?? this.amount,
      paidStatus: paidStatus ?? this.paidStatus,
      paidDate: paidDate ?? this.paidDate,
      paidMethod: paidMethod ?? this.paidMethod,
      service: service ?? this.service,
      dueDate: dueDate ?? this.dueDate,
      referenceNo: referenceNo ?? this.referenceNo,
    );
  }

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      billId: json['bill_id'] ?? 0,
      houseId: json['house_id'] ?? 0,
      billDate: json['bill_date'] is String
          ? DateTime.parse(json['bill_date'])
          : json['bill_date'] as DateTime,
      amount: (json['amount'] ?? 0).toDouble(),
      paidStatus: json['paid_status'] ?? 0,
      paidDate: json['paid_date'] != null
          ? (json['paid_date'] is String
                ? DateTime.parse(json['paid_date'])
                : json['paid_date'] as DateTime)
          : null,
      paidMethod: json['paid_method'],
      service: json['service'] ?? 0,
      dueDate: json['due_date'] is String
          ? DateTime.parse(json['due_date'])
          : json['due_date'] as DateTime,
      referenceNo: json['reference_no'],
      paidImg: json['paid_img'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bill_id': billId,
      'house_id': houseId,
      'bill_date': billDate.toIso8601String(),
      'amount': amount,
      'paid_status': paidStatus,
      'paid_date': paidDate?.toIso8601String(),
      'paid_method': paidMethod,
      'service': service,
      'due_date': dueDate.toIso8601String(),
      'reference_no': referenceNo,
      'paid_img': paidImg,
    };
  }
}
