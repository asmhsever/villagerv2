// 📁 lib/views/juristic/fees/fees_bill_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fees_bill_edit_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FeesBillDetailScreen extends StatefulWidget {
  final int billId;
  const FeesBillDetailScreen({super.key, required this.billId});

  @override
  State<FeesBillDetailScreen> createState() => _FeesBillDetailScreenState();
}

class _FeesBillDetailScreenState extends State<FeesBillDetailScreen> {
  Map<String, dynamic>? _bill;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    try {
      final data = await Supabase.instance.client
          .from('bill_area')
          .select('*, house(house_number), service(name)')
          .eq('bill_id', widget.billId)
          .maybeSingle();
      setState(() {
        _bill = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ loadBill error: \$e');
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteBill() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบบิลนี้?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client
          .from('bill_area')
          .delete()
          .eq('bill_id', widget.billId);
      if (context.mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _exportPdf() async {
    final fmt = DateFormat('dd/MM/yyyy');
    final moneyFmt = NumberFormat('#,##0', 'th_TH');
    final pdf = pw.Document();
    final b = _bill!;
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ใบแจ้งค่าส่วนกลาง', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Text('รหัสบิล: ${b['bill_id']}'),
              pw.Text('บ้านเลขที่: ${b['house']?['house_number'] ?? '-'}'),
              pw.Text('วันที่บิล: ${fmt.format(DateTime.parse(b['bill_date']))}'),
              pw.Text('จำนวนเงิน: ${moneyFmt.format(b['amount'])} บาท'),
              pw.Text('บริการ: ${b['service']?['name'] ?? '-'}'),
              pw.Text('ครบกำหนด: ${fmt.format(DateTime.parse(b['due_date']))}'),
              pw.Text('สถานะ: ${b['paid_status'] == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ'}'),
              pw.Text('เลขอ้างอิง: ${b['reference_no'] ?? '-'}'),
            ],

          ),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> _toggleStatus() async {
    if (_bill == null) return;
    final newStatus = _bill!['paid_status'] == 1 ? 0 : 1;
    await Supabase.instance.client
        .from('bill_area')
        .update({'paid_status': newStatus})
        .eq('bill_id', widget.billId);
    _loadBill();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final moneyFmt = NumberFormat('#,##0', 'th_TH');

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดบิล'),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportPdf),
          IconButton(icon: const Icon(Icons.edit), onPressed: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FeesBillEditScreen(billId: widget.billId),
              ),
            );
            if (updated == true) _loadBill();
          }),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteBill),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bill == null
          ? const Center(child: Text('ไม่พบข้อมูล'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รหัสบิล: ${_bill!['bill_id']}'),
            Text('บ้านเลขที่: ${_bill!['house']?['house_number'] ?? '-'}'),
            Text('วันที่บิล: ${fmt.format(DateTime.parse(_bill!['bill_date']))}'),
            Text('จำนวนเงิน: ${moneyFmt.format(_bill!['amount'])} บาท'),
            Text('บริการ: ${_bill!['service']?['name'] ?? '-'}'),
            Text('ครบกำหนด: ${fmt.format(DateTime.parse(_bill!['due_date']))}'),
            Text('สถานะ: ${_bill!['paid_status'] == 1 ? 'ชำระแล้ว' : 'ยังไม่จ่าย'}'),
            Text('เลขอ้างอิง: ${_bill!['reference_no'] ?? '-'}'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _toggleStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('เปลี่ยนสถานะการชำระ'),
            ),
          ],
        ),
      ),
    );
  }
}
