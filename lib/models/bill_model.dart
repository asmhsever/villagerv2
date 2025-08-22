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
  final String? slipImg;
  final String? billImg;
  final String? receiptImg;
  final String status;
  final DateTime? slipDate;

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
    this.slipImg, // เพิ่มใน constructor
    this.billImg,
    this.receiptImg,
    required this.status,
    this.slipDate,
  });

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
      slipImg: json['slip_img'],
      billImg: json['bill_img'],
      receiptImg: json['receipt_img'],
      status: json['status'],
      slipDate: json['slip_date'] != null
          ? (json['slip_date'] is String
          ? DateTime.parse(json['slip_date'])
          : json['slip_date'] as DateTime)
          : null,
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
      'slip_img': slipImg,
      'bill_img': billImg,
      'receipt_img': receiptImg,
      'status': status,
      'slip_date': slipDate,
    };
  }
}
