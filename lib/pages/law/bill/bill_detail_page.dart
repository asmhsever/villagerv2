// lib/pages/law/bill/bill_detail_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/pages/law/bill/bill_edit_page.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
// import 'package:cached_network_image/cached_network_image.dart'; // ไม่ใช้แล้ว

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

  // ===== Palette (match LawDashboardPage) =====
  static const Color _softBrown = Color(0xFFA47551);
  static const Color _ivoryWhite = Color(0xFFFFFDF6);
  static const Color _sandyTan = Color(0xFFD8CAB8);
  static const Color _earthClay = Color(0xFFBFA18F);
  static const Color _warmStone = Color(0xFFC7B9A5);
  static const Color _oliveGreen = Color(0xFFA3B18A);
  static const Color _burntOrange = Color(0xFFE08E45);
  static const Color _softTerracotta = Color(0xFFD48B5C);

  // แมปประเภทบริการให้เป็นภาษาไทย
  final Map<String, String> _serviceTranslations = const {
    'Area Fee': 'ค่าพื้นที่ส่วนกลาง',
    'Trash Fee': 'ค่าขยะ',
    'water Fee': 'ค่าน้ำ',
    'Water Fee': 'ค่าน้ำ',
    'enegy Fee': 'ค่าไฟ',
    'Energy Fee': 'ค่าไฟ',
    'Electricity Fee': 'ค่าไฟ',
  };

  @override
  void initState() {
    super.initState();
    currentBill = widget.bill;
    _fetchAdditionalData();
  }

  Future<void> _fetchAdditionalData() async {
    try {
      final results = await Future.wait([
        SupabaseConfig.client
            .from('house')
            .select('house_number')
            .eq('house_id', currentBill.houseId)
            .single(),
        SupabaseConfig.client
            .from('service')
            .select('name')
            .eq('service_id', currentBill.service)
            .single(),
      ]);

      if (!mounted) return;
      setState(() {
        houseNumber = results[0]['house_number'];
        serviceName = results[1]['name'];
      });
    } catch (e) {
      debugPrint('Error fetching additional data: $e');
    }
  }

  String formatDate(DateTime? date) => date == null ? '-' : DateFormat('dd/MM/yyyy').format(date);
  String formatDateTime(DateTime? date) => date == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(date);

  String getPaidStatus(int status) => status == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ';

  Color getPaidStatusColor(int status) => status == 1 ? _oliveGreen : _softTerracotta;

  String _getServiceNameTh(String? englishName) => _serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุประเภท';

  String _getStatusText() {
    switch (currentBill.status.toUpperCase()) {
      case 'DRAFT':
        return 'แบบร่าง';
      case 'PENDING':
        return 'รอชำระ';
      case 'UNDER_REVIEW':
        return 'กำลังตรวจสอบ';
      case 'RECEIPT_SENT':
        return 'ส่งใบเสร็จแล้ว';
      case 'REJECTED':
        return 'ถูกปฏิเสธ';
      case 'OVERDUE':
        return 'เกินกำหนด';
      default:
        if (currentBill.paidStatus == 1) return 'ชำระแล้ว';
        if (_isOverdue()) return 'เกินกำหนด';
        return 'ยังไม่ชำระ';
    }
  }

  Color _getStatusColor() {
    switch (currentBill.status.toUpperCase()) {
      case 'RECEIPT_SENT':
        return _oliveGreen;
      case 'PENDING':
        return _softTerracotta;
      case 'UNDER_REVIEW':
        return _softBrown;
      case 'REJECTED':
        return Colors.red.shade400;
      case 'OVERDUE':
        return Colors.red.shade400;
      default:
        if (currentBill.paidStatus == 1) return _oliveGreen;
        if (_isOverdue()) return Colors.red.shade400;
        return _softTerracotta;
    }
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

  Future<void> _showImageDialog(String imageUrl, String title) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: _softBrown,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Image area
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(_softBrown),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: _sandyTan,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: _earthClay),
                              SizedBox(height: 8),
                              Text('ไม่สามารถโหลดรูปภาพได้', style: TextStyle(color: _earthClay)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildImageCard(String? imageUrl, String title, IconData icon) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: _sandyTan.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _warmStone.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: _earthClay),
            const SizedBox(height: 8),
            Text(
              'ไม่มี$title',
              style: const TextStyle(color: _earthClay, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showImageDialog(imageUrl, title),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _warmStone),
          boxShadow: [
            BoxShadow(
              color: _warmStone.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: _sandyTan,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(_softBrown),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _sandyTan,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 32, color: _earthClay),
                      SizedBox(height: 4),
                      Text(
                        'ไม่สามารถโหลดรูปได้',
                        style: TextStyle(color: _earthClay, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.zoom_in, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ใบแจ้งค่าส่วนกลาง', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Bill #${currentBill.billId}', style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('ข้อมูลบิล', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('รหัสบิล: ${currentBill.billId}'),
              pw.Text('บ้านเลขที่: ${houseNumber ?? currentBill.houseId}'),
              pw.Text('ประเภทบริการ: ${_getServiceNameTh(serviceName)}'),
              pw.Text('จำนวนเงิน: ${NumberFormat('#,##0.00').format(currentBill.amount)} บาท'),
              pw.Text('สถานะ: ${_getStatusText()}'),
              pw.SizedBox(height: 16),
              pw.Text('ข้อมูลวันที่', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('วันที่ออกบิล: ${formatDate(currentBill.billDate)}'),
              pw.Text('วันครบกำหนด: ${formatDate(currentBill.dueDate)}'),
              if (currentBill.paidDate != null) pw.Text('วันที่ชำระ: ${formatDate(currentBill.paidDate)}'),
              if (currentBill.slipDate != null) pw.Text('วันที่อัพโหลดสลิป: ${formatDate(currentBill.slipDate)}'),
              pw.Spacer(),
              pw.Divider(),
              pw.Text('สร้างเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้าง PDF: $e'), backgroundColor: Colors.red.shade400),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ยืนยันการลบ', style: TextStyle(color: _softBrown, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการลบบิลนี้หรือไม่?', style: TextStyle(color: _earthClay)),
            const SizedBox(height: 8),
            Text('บิล #${currentBill.billId} - ${NumberFormat('#,##0.00').format(currentBill.amount)} บาท',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('การดำเนินการนี้ไม่สามารถย้อนกลับได้', style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _warmStone),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('ลบบิลสำเร็จ'), backgroundColor: _oliveGreen),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('ไม่สามารถลบบิลได้');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red.shade400),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePaymentStatus() async {
    if (currentBill.paidStatus == 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _ivoryWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('ยืนยันการเปลี่ยนสถานะ', style: TextStyle(color: _softBrown, fontWeight: FontWeight.bold)),
          content: Text('ต้องการเปลี่ยนสถานะเป็น "ยังไม่ชำระ" หรือไม่?', style: TextStyle(color: _earthClay)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: _softTerracotta, foregroundColor: Colors.white),
              child: const Text('ยืนยัน'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        try {
          final success = await BillDomain.update(
            billId: currentBill.billId,
            paidStatus: 0,
            paidDate: null,
            paidMethod: null,
            status: 'PENDING',
          );
          if (success && mounted) {
            setState(() {
              currentBill = BillModel(
                billId: currentBill.billId,
                houseId: currentBill.houseId,
                billDate: currentBill.billDate,
                amount: currentBill.amount,
                paidStatus: 0,
                paidDate: null,
                paidMethod: null,
                service: currentBill.service,
                dueDate: currentBill.dueDate,
                referenceNo: currentBill.referenceNo,
                status: 'PENDING',
                slipImg: currentBill.slipImg,
                billImg: currentBill.billImg,
                receiptImg: currentBill.receiptImg,
                slipDate: currentBill.slipDate,
              );
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('อัพเดทสถานะสำเร็จ'), backgroundColor: _softTerracotta),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red.shade400),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _ivoryWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('ยืนยันการชำระเงิน', style: TextStyle(color: _softBrown, fontWeight: FontWeight.bold)),
          content: Text('ยืนยันว่าได้รับชำระเงินแล้วหรือไม่?', style: TextStyle(color: _earthClay)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: _oliveGreen, foregroundColor: Colors.white),
              child: const Text('ยืนยันการชำระ'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        try {
          final success = await BillDomain.update(
            billId: currentBill.billId,
            paidStatus: 1,
            paidDate: DateTime.now().toIso8601String(),
            paidMethod: 'เงินสด',
            status: 'RECEIPT_SENT',
          );
          if (success && mounted) {
            setState(() {
              currentBill = BillModel(
                billId: currentBill.billId,
                houseId: currentBill.houseId,
                billDate: currentBill.billDate,
                amount: currentBill.amount,
                paidStatus: 1,
                paidDate: DateTime.now(),
                paidMethod: 'เงินสด',
                service: currentBill.service,
                dueDate: currentBill.dueDate,
                referenceNo: currentBill.referenceNo,
                status: 'RECEIPT_SENT',
                slipImg: currentBill.slipImg,
                billImg: currentBill.billImg,
                receiptImg: currentBill.receiptImg,
                slipDate: currentBill.slipDate,
              );
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('อัพเดทสถานะสำเร็จ'), backgroundColor: _oliveGreen),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red.shade400),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool overdue = _isOverdue();
    final Color stateColor = _getStatusColor();

    return Scaffold(
      backgroundColor: _ivoryWhite,
      appBar: AppBar(
        title: Text('บิล #${currentBill.billId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _softBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading
                ? null
                : () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BillEditPage(bill: currentBill)),
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
          ? Center(
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(_softBrown),
          backgroundColor: _sandyTan.withValues(alpha: 0.5),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Banner Status =====
            Container(
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stateColor.withValues(alpha: 0.25)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    overdue
                        ? Icons.warning
                        : currentBill.paidStatus == 1
                        ? Icons.check_circle
                        : Icons.schedule,
                    color: stateColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stateColor),
                        ),
                        if (overdue)
                          Text('เกินกำหนด ${_getDaysUntilDue().abs()} วัน', style: TextStyle(color: Colors.red.shade400))
                        else if (currentBill.paidStatus == 0)
                          Text('เหลืออีก ${_getDaysUntilDue()} วัน', style: TextStyle(color: _softTerracotta)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== บัตรข้อมูลบิล =====
            _themedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('ข้อมูลบิล'),
                  const Divider(),
                  _buildInfoRow('รหัสบิล', '${currentBill.billId}'),
                  _buildInfoRow('บ้านเลขที่', houseNumber ?? '${currentBill.houseId}'),
                  _buildInfoRow('ประเภทบริการ', _getServiceNameTh(serviceName)),
                  _buildInfoRow(
                    'จำนวนเงิน',
                    '${NumberFormat('#,##0.00').format(currentBill.amount)} บาท',
                    valueStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _softBrown),
                  ),
                  _buildInfoRow('สถานะ', _getStatusText()),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== บัตรข้อมูลวันที่ =====
            _themedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('ข้อมูลวันที่'),
                  const Divider(),
                  _buildInfoRow('วันที่ออกบิล', formatDate(currentBill.billDate)),
                  _buildInfoRow('วันครบกำหนด', formatDate(currentBill.dueDate)),
                  if (currentBill.paidDate != null) _buildInfoRow('วันที่ชำระ', formatDate(currentBill.paidDate)),
                  if (currentBill.slipDate != null) _buildInfoRow('วันที่อัพโหลดสลิป', formatDate(currentBill.slipDate)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== บัตรข้อมูลการชำระ =====
            if (currentBill.paidStatus == 1) ...[
              _themedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle('ข้อมูลการชำระเงิน'),
                    const Divider(),
                    if (currentBill.paidMethod != null) _buildInfoRow('วิธีชำระเงิน', currentBill.paidMethod!),
                    if (currentBill.referenceNo != null) _buildInfoRow('เลขอ้างอิง', currentBill.referenceNo!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ===== บัตรรูปภาพ =====
            _themedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('รูปภาพเอกสาร'),
                  const Divider(),
                  const SizedBox(height: 8),

                  // แถวแรก: รูปบิล และ รูปสลิปการโอน
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รูปบิล',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _earthClay,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildImageCard(
                              currentBill.billImg,
                              'รูปบิล',
                              Icons.receipt_long,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'สลิปการโอน',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _earthClay,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildImageCard(
                              currentBill.slipImg,
                              'สลิปการโอน',
                              Icons.payment,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // แถวที่สอง: รูปใบเสร็จ (เต็มความกว้าง)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ใบเสร็จการชำระเงิน',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _earthClay,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildImageCard(
                        currentBill.receiptImg,
                        'ใบเสร็จการชำระเงิน',
                        Icons.receipt,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== ปุ่มเปลี่ยนสถานะ =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updatePaymentStatus,
                icon: Icon(currentBill.paidStatus == 1 ? Icons.undo : Icons.check),
                label: Text(currentBill.paidStatus == 1 ? 'เปลี่ยนเป็น "ยังไม่ชำระ"' : 'ยืนยันการชำระเงิน'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentBill.paidStatus == 1 ? _softTerracotta : _oliveGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 80), // เผื่อ FloatingActionButton
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _exportSingleBillAsPdf,
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.picture_as_pdf),
        label: Text(_isLoading ? 'กำลังสร้าง...' : 'Export PDF'),
        backgroundColor: _burntOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ===== Helpers =====
  Widget _themedCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _sandyTan.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _warmStone.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }

  Widget _cardTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: _softBrown,
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _earthClay,
              ),
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