import 'package:flutter/material.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/pages/law/bill/bill_edit_page.dart';

class BillDetailPage extends StatelessWidget {
  final BillModel bill;
  final Map<int, String> houseMap;

  const BillDetailPage({
    super.key,
    required this.bill,
    required this.houseMap,
  });

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  String getPaidStatus(int status) {
    return status == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ';
  }

  @override
  Widget build(BuildContext context) {
    final houseLabel = houseMap[bill.houseId] ?? 'บ้านเลขที่ ${bill.houseId}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดค่าส่วนกลาง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BillEditPage(bill: bill),
                ),
              );
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รหัสบิล: ${bill.billId}'),
            Text('บ้าน: $houseLabel'),
            Text('จำนวนเงิน: ${bill.amount} บาท'),
            Text('สถานะ: ${getPaidStatus(bill.paidStatus)}'),
            Text('วันที่ออกบิล: ${formatDate(bill.billDate)}'),
            Text('วันครบกำหนด: ${formatDate(bill.dueDate)}'),
            if (bill.paidDate != null)
              Text('วันที่ชำระ: ${formatDate(bill.paidDate)}'),
            if (bill.paidMethod != null)
              Text('วิธีชำระเงิน: ${bill.paidMethod}'),
            if (bill.referenceNo != null)
              Text('เลขอ้างอิง: ${bill.referenceNo}'),
          ],
        ),
      ),
    );
  }
}
