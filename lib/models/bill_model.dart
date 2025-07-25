
class BillModel {
  final int billId;
  final int houseId;
  final DateTime billDate;
  final int amount;
  final int paidStatus;
  final DateTime? paidDate;
  final String? paidMethod;
  final int? service;
  final DateTime? dueDate;
  final String? referenceNo;

  BillModel({
    required this.billId,
    required this.houseId,
    required this.billDate,
    required this.amount,
    required this.paidStatus,
    this.paidDate,
    this.paidMethod,
    this.service,
    this.dueDate,
    this.referenceNo,
  });

  BillModel copyWith({
    int? billId,
    int? houseId,
    DateTime? billDate,
    int? amount,
    int? paidStatus,
    DateTime? paidDate,
    String? paidMethod,
    int? service,
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
      billId: json['bill_id'] as int,
      houseId: json['house_id'] as int,
      billDate: DateTime.parse(json['bill_date']),
      amount: json['amount'] as int,
      paidStatus: json['paid_status'] as int,
      paidDate: json['paid_date'] != null ? DateTime.tryParse(json['paid_date']) : null,
      paidMethod: json['paid_method'],
      service: json['service'],
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      referenceNo: json['reference_no'],
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
      'due_date': dueDate?.toIso8601String(),
      'reference_no': referenceNo,
    };
  }
}
