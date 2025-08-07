// lib/pages/law/bill/bill_detail_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/pages/law/bill/bill_edit_page.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BillDetailPage extends StatelessWidget {
  final BillModel bill;

  const BillDetailPage({super.key, required this.bill});

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  String getPaidStatus(int status) {
    return status == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ';
  }

  String getServiceLabel(int? id) {
    switch (id) {
      case 1:
        return 'ค่าพื้นที่ส่วนกลาง';
      case 2:
        return 'ค่าขยะ';
      case 3:
        return 'ค่าน้ำ';
      case 4:
        return 'ค่าไฟ';
      default:
        return 'ไม่ระบุประเภท';
    }
  }

  Future<void> exportSingleBillAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('รายละเอียดค่าส่วนกลาง', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 12),
            pw.Text('รหัสบิล: ${bill.billId}'),
            pw.Text('บ้าน: บ้านเลขที่ ${bill.houseId}'),
            pw.Text('ประเภทบริการ: ${getServiceLabel(bill.service)}'),
            pw.Text('จำนวนเงิน: ${bill.amount} บาท'),
            pw.Text('สถานะ: ${getPaidStatus(bill.paidStatus)}'),
            pw.Text('วันที่ออกบิล: ${formatDate(bill.billDate)}'),
            pw.Text('วันครบกำหนด: ${formatDate(bill.dueDate)}'),
            if (bill.paidDate != null)
              pw.Text('วันที่ชำระ: ${formatDate(bill.paidDate)}'),
            if (bill.paidMethod != null)
              pw.Text('วิธีชำระเงิน: ${bill.paidMethod}'),
            if (bill.referenceNo != null)
              pw.Text('เลขอ้างอิง: ${bill.referenceNo}'),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบบิลนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BillDomain.delete(bill.billId);

      if (context.mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => confirmDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ข้อมูลบิล', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Text('รหัสบิล: ${bill.billId}'),
            Text('บ้าน: บ้านเลขที่ ${bill.houseId}'),
            Text('ประเภทบริการ: ${getServiceLabel(bill.service)}'),
            Text('จำนวนเงิน: ${bill.amount} บาท'),
            Text('สถานะ: ${getPaidStatus(bill.paidStatus)}'),
            const SizedBox(height: 12),
            Text('วันเวลา', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Text('วันที่ออกบิล: ${formatDate(bill.billDate)}'),
            Text('วันครบกำหนด: ${formatDate(bill.dueDate)}'),
            if (bill.paidDate != null)
              Text('วันที่ชำระ: ${formatDate(bill.paidDate)}'),
            const SizedBox(height: 12),
            Text('การชำระเงิน', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            if (bill.paidMethod != null)
              Text('วิธีชำระเงิน: ${bill.paidMethod}'),
            if (bill.referenceNo != null)
              Text('เลขอ้างอิง: ${bill.referenceNo}'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: exportSingleBillAsPdf,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Export PDF'),
      ),
    );
  }
}
