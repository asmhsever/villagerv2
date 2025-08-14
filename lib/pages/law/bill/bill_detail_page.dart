import 'package:flutter/material.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/pages/law/bill/bill_edit_page.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class BillDetailPage extends StatefulWidget {
  final BillModel bill;

  const BillDetailPage({super.key, required this.bill});

  @override
  State<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  late BillModel currentBill;
  String? houseNumber;
  String? serviceName;
  bool _isLoading = false;

  // แมปประเภทบริการให้เป็นภาษาไทย
  final Map<String, String> _serviceTranslations = {
    'Area Fee': 'ค่าพื้นที่ส่วนกลาง',
    'Trash Fee': 'ค่าขยะ',
    'water Fee': 'ค่าน้ำ',
    'enegy Fee': 'ค่าไฟ',
  };

  @override
  void initState() {
    super.initState();
    currentBill = widget.bill;
    _fetchAdditionalData();
  }

  Future<void> _fetchAdditionalData() async {
    try {
      // ดึงข้อมูลบ้าน
      final houseResponse = await SupabaseConfig.client
          .from('house')
          .select('house_number')
          .eq('house_id', currentBill.houseId)
          .single();

      // ดึงข้อมูลประเภทบริการ
      final serviceResponse = await SupabaseConfig.client
          .from('service')
          .select('name')
          .eq('service_id', currentBill.service)
          .single();

      setState(() {
        houseNumber = houseResponse['house_number'];
        serviceName = serviceResponse['name'];
      });
    } catch (e) {
      print('Error fetching additional data: $e');
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String getPaidStatus(int status) {
    return status == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ';
  }

  Color getPaidStatusColor(int status) {
    return status == 1 ? Colors.green : Colors.orange;
  }

  String _getServiceNameTh(String? englishName) {
    return _serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุประเภท';
  }

  bool _isOverdue() {
    if (currentBill.paidStatus == 1) return false;
    return DateTime.now().isAfter(currentBill.dueDate);
  }

  int _getDaysUntilDue() {
    if (currentBill.paidStatus == 1) return 0;
    final today = DateTime.now();
    final dueDate = currentBill.dueDate;
    return dueDate.difference(today).inDays;
  }

  Future<void> _exportSingleBillAsPdf() async {
    setState(() => _isLoading = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'ใบแจ้งค่าส่วนกลาง',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Bill #${currentBill.billId}',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ข้อมูลบิล
              pw.Text('ข้อมูลบิล', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('รหัสบิล: ${currentBill.billId}'),
              pw.Text('บ้านเลขที่: ${houseNumber ?? currentBill.houseId}'),
              pw.Text('ประเภทบริการ: ${_getServiceNameTh(serviceName)}'),
              pw.Text('จำนวนเงิน: ${NumberFormat('#,##0.00').format(currentBill.amount)} บาท'),
              pw.Text('สถานะ: ${getPaidStatus(currentBill.paidStatus)}'),

              pw.SizedBox(height: 16),

              // วันที่
              pw.Text('ข้อมูลวันที่', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('วันที่ออกบิล: ${formatDate(currentBill.billDate)}'),
              pw.Text('วันครบกำหนด: ${formatDate(currentBill.dueDate)}'),
              if (currentBill.paidDate != null)
                pw.Text('วันที่ชำระ: ${formatDate(currentBill.paidDate)}'),

              pw.SizedBox(height: 16),

              // การชำระเงิน
              if (currentBill.paidStatus == 1) ...[
                pw.Text('ข้อมูลการชำระเงิน', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                if (currentBill.paidMethod != null)
                  pw.Text('วิธีชำระเงิน: ${currentBill.paidMethod}'),
                if (currentBill.referenceNo != null)
                  pw.Text('เลขอ้างอิง: ${currentBill.referenceNo}'),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.Text(
                'สร้างเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการสร้าง PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('คุณต้องการลบบิลนี้หรือไม่?'),
            const SizedBox(height: 8),
            Text(
              'บิล #${currentBill.billId} - ${NumberFormat('#,##0.00').format(currentBill.amount)} บาท',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        final success = await BillDomain.delete(currentBill.billId);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ลบบิลสำเร็จ'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('ไม่สามารถลบบิลได้');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePaymentStatus() async {
    if (currentBill.paidStatus == 1) {
      // ถ้าจ่ายแล้ว ให้เปลี่ยนเป็นยังไม่จ่าย
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการเปลี่ยนสถานะ'),
          content: const Text('ต้องการเปลี่ยนสถานะเป็น "ยังไม่ชำระ" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยัน'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final success = await BillDomain.updatePaymentStatus(
          billId: currentBill.billId,
          paidStatus: 0,
          paidDate: null,
          paidMethod: null,
        );

        if (success) {
          setState(() {
            currentBill = currentBill.copyWith(
              paidStatus: 0,
              paidDate: null,
              paidMethod: null,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัพเดทสถานะสำเร็จ')),
          );
        }
      }
    } else {
      // ถ้ายังไม่จ่าย ให้เปลี่ยนเป็นจ่ายแล้ว
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการชำระเงิน'),
          content: const Text('ยืนยันว่าได้รับชำระเงินแล้วหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยันการชำระ'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final success = await BillDomain.updatePaymentStatus(
          billId: currentBill.billId,
          paidStatus: 1,
          paidDate: DateTime.now().toIso8601String(),
          paidMethod: 'เงินสด',
        );

        if (success) {
          setState(() {
            currentBill = currentBill.copyWith(
              paidStatus: 1,
              paidDate: DateTime.now(),
              paidMethod: 'เงินสด',
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัพเดทสถานะสำเร็จ')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('บิล #${currentBill.billId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BillEditPage(bill: currentBill),
                ),
              );
              if (result == true && mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : () => _confirmDelete(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // สถานะและการแจ้งเตือน
            Card(
              color: _isOverdue()
                  ? Colors.red.shade50
                  : currentBill.paidStatus == 1
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isOverdue()
                          ? Icons.warning
                          : currentBill.paidStatus == 1
                          ? Icons.check_circle
                          : Icons.schedule,
                      color: _isOverdue()
                          ? Colors.red
                          : currentBill.paidStatus == 1
                          ? Colors.green
                          : Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getPaidStatus(currentBill.paidStatus),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: getPaidStatusColor(currentBill.paidStatus),
                            ),
                          ),
                          if (_isOverdue())
                            Text(
                              'เกินกำหนด ${_getDaysUntilDue().abs()} วัน',
                              style: const TextStyle(color: Colors.red),
                            )
                          else if (currentBill.paidStatus == 0)
                            Text(
                              'เหลืออีก ${_getDaysUntilDue()} วัน',
                              style: const TextStyle(color: Colors.orange),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ข้อมูลบิล
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลบิล',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow('รหัสบิล', '${currentBill.billId}'),
                    _buildInfoRow('บ้านเลขที่', houseNumber ?? '${currentBill.houseId}'),
                    _buildInfoRow('ประเภทบริการ', _getServiceNameTh(serviceName)),
                    _buildInfoRow(
                      'จำนวนเงิน',
                      '${NumberFormat('#,##0.00').format(currentBill.amount)} บาท',
                      valueStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ข้อมูลวันที่
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลวันที่',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow('วันที่ออกบิล', formatDate(currentBill.billDate)),
                    _buildInfoRow('วันครบกำหนด', formatDate(currentBill.dueDate)),
                    if (currentBill.paidDate != null)
                      _buildInfoRow('วันที่ชำระ', formatDate(currentBill.paidDate)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ข้อมูลการชำระเงิน
            if (currentBill.paidStatus == 1) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลการชำระเงิน',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      if (currentBill.paidMethod != null)
                        _buildInfoRow('วิธีชำระเงิน', currentBill.paidMethod!),
                      if (currentBill.referenceNo != null)
                        _buildInfoRow('เลขอ้างอิง', currentBill.referenceNo!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ปุ่มเปลี่ยนสถานะการชำระ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updatePaymentStatus,
                icon: Icon(
                  currentBill.paidStatus == 1 ? Icons.undo : Icons.check,
                ),
                label: Text(
                  currentBill.paidStatus == 1
                      ? 'เปลี่ยนเป็น "ยังไม่ชำระ"'
                      : 'ยืนยันการชำระเงิน',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentBill.paidStatus == 1 ? Colors.orange : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _exportSingleBillAsPdf,
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.picture_as_pdf),
        label: Text(_isLoading ? 'กำลังสร้าง...' : 'Export PDF'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}