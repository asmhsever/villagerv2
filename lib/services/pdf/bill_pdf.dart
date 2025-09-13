import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fullproject/models/bill_model.dart';
import 'package:intl/intl.dart';

class BillPDFService {
  // Format currency
  static String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '฿${formatter.format(amount)}';
  }

  // Format date
  static String _formatDate(DateTime? date) {
    if (date == null) return 'ไม่ระบุ';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format date with time
  static String _formatDateTime(DateTime? date) {
    if (date == null) return 'ไม่ระบุ';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // Load Thai font (optional)
  static Future<pw.Font?> _tryLoadThaiFont() async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Noto_Sans_Thai/NotoSansThai-Regular.ttf");
      return pw.Font.ttf(fontData);
    } catch (e) {
      print('Thai font not available: $e');
      return null;
    }
  }

  // Get service name in Thai
  static String _getServiceNameTh(String? englishName) {
    const serviceTranslations = {
      'Area Fee': 'ค่าพื้นที่ส่วนกลาง',
      'Trash Fee': 'ค่าขยะ',
      'water Fee': 'ค่าน้ำ',
      'Water Fee': 'ค่าน้ำ',
      'enegy Fee': 'ค่าไฟ',
      'Energy Fee': 'ค่าไฟ',
      'Electricity Fee': 'ค่าไฟ',
    };
    return serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุประเภท';
  }

  // Get status text in Thai
  static String _getStatusText(String status, int paidStatus) {
    const statusTranslations = {
      'DRAFT': 'แบบร่าง',
      'PENDING': 'รอชำระ',
      'UNDER_REVIEW': 'กำลังตรวจสอบ',
      'RECEIPT_SENT': 'เสร็จสิ้น',
      'REJECTED': 'สลิปไม่ผ่าน',
      'OVERDUE': 'เลยกำหนด',
      'WAIT_RECEIPT': 'รอส่งใบเสร็จ',
    };

    if (paidStatus == 1) return 'ชำระแล้ว';
    return statusTranslations[status.toUpperCase()] ?? 'ยังไม่ชำระ';
  }

  // Get status color
  static PdfColor _getStatusColor(String status, int paidStatus) {
    if (paidStatus == 1) return PdfColor.fromHex('#6B8E23'); // Green

    switch (status.toUpperCase()) {
      case 'DRAFT':
        return PdfColors.grey;
      case 'PENDING':
        return PdfColor.fromHex('#D2691E'); // Orange
      case 'UNDER_REVIEW':
        return PdfColor.fromHex('#B8860B'); // Dark goldenrod
      case 'RECEIPT_SENT':
        return PdfColor.fromHex('#6B8E23'); // Green
      case 'REJECTED':
        return PdfColor.fromHex('#CD5C5C'); // Indian red
      case 'OVERDUE':
        return PdfColor.fromHex('#FF4500'); // Red orange
      case 'WAIT_RECEIPT':
        return PdfColor.fromHex('#4682B4'); // Steel blue
      default:
        return PdfColor.fromHex('#D2691E');
    }
  }

  // Export single bill as PDF
  static Future<void> exportBillDetail(
      BillModel bill, {
        String? houseNumber,
        String? serviceName,
      }) async {
    print('Creating bill PDF...');

    try {
      final pdf = pw.Document();
      final thaiFont = await _tryLoadThaiFont();

      final statusText = _getStatusText(bill.status, bill.paidStatus);
      final statusColor = _getStatusColor(bill.status, bill.paidStatus);
      final serviceNameTh = _getServiceNameTh(serviceName);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: thaiFont != null ? pw.ThemeData.withFont(base: thaiFont) : null,
          build: (pw.Context context) {
            return pw.Padding(
              padding: pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Container(
                    width: double.infinity,
                    padding: pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: statusColor,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'ใบแจ้งค่าส่วนกลาง',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            font: thaiFont,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          _formatCurrency(bill.amount),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            font: thaiFont,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          statusText,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            font: thaiFont,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 24),

                  // Bill Details Section
                  pw.Container(
                    width: double.infinity,
                    padding: pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'รายละเอียดบิล',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: thaiFont,
                          ),
                        ),
                        pw.SizedBox(height: 12),

                        _buildDetailRow('เลขที่บิล', '#${bill.billId.toString().padLeft(6, '0')}', thaiFont),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('บ้านเลขที่', houseNumber ?? bill.houseId.toString(), thaiFont),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('ประเภทบริการ', serviceNameTh, thaiFont),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('จำนวนเงิน', _formatCurrency(bill.amount), thaiFont),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('สถานะ', statusText, thaiFont),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 16),

                  // Date Details Section
                  pw.Container(
                    width: double.infinity,
                    padding: pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ข้อมูลวันที่',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: thaiFont,
                          ),
                        ),
                        pw.SizedBox(height: 12),

                        _buildDetailRow('วันที่ออกบิล', _formatDate(bill.billDate), thaiFont),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('วันครบกำหนด', _formatDate(bill.dueDate), thaiFont),

                        if (bill.paidDate != null) ...[
                          pw.SizedBox(height: 8),
                          _buildDetailRow('วันที่ชำระ', _formatDate(bill.paidDate), thaiFont),
                        ],

                        if (bill.slipDate != null) ...[
                          pw.SizedBox(height: 8),
                          _buildDetailRow('วันที่อัปโหลดสลิป', _formatDateTime(bill.slipDate), thaiFont),
                        ],
                      ],
                    ),
                  ),

                  // Payment Details (if paid)
                  if (bill.paidStatus == 1 ||
                      bill.paidMethod != null ||
                      bill.referenceNo != null) ...[
                    pw.SizedBox(height: 16),
                    pw.Container(
                      width: double.infinity,
                      padding: pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#6B8E23').shade(0.1),
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColor.fromHex('#6B8E23').shade(0.3)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ข้อมูลการชำระเงิน',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              font: thaiFont,
                              color: PdfColor.fromHex('#6B8E23'),
                            ),
                          ),
                          pw.SizedBox(height: 12),

                          if (bill.paidMethod != null) ...[
                            _buildDetailRow('วิธีการจ่าย', bill.paidMethod!, thaiFont),
                            pw.SizedBox(height: 8),
                          ],

                          if (bill.referenceNo != null) ...[
                            _buildDetailRow('เลขที่อ้างอิง', bill.referenceNo!, thaiFont),
                            pw.SizedBox(height: 8),
                          ],

                          _buildDetailRow('สถานะการจ่าย', bill.paidStatus == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย', thaiFont),
                        ],
                      ),
                    ),
                  ],

                  // Additional info about images (without showing them)
                  if (bill.billImg?.isNotEmpty == true ||
                      bill.slipImg?.isNotEmpty == true ||
                      bill.receiptImg?.isNotEmpty == true) ...[
                    pw.SizedBox(height: 16),
                    pw.Container(
                      width: double.infinity,
                      padding: pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColors.blue200),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ไฟล์เอกสารประกอบ',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              font: thaiFont,
                              color: PdfColors.blue800,
                            ),
                          ),
                          pw.SizedBox(height: 8),

                          if (bill.billImg?.isNotEmpty == true)
                            pw.Text('• มีรูปบิล', style: pw.TextStyle(font: thaiFont, fontSize: 12)),
                          if (bill.slipImg?.isNotEmpty == true)
                            pw.Text('• มีรูปสลิปการโอน', style: pw.TextStyle(font: thaiFont, fontSize: 12)),
                          if (bill.receiptImg?.isNotEmpty == true)
                            pw.Text('• มีรูปใบเสร็จ', style: pw.TextStyle(font: thaiFont, fontSize: 12)),

                          pw.SizedBox(height: 4),
                          pw.Text(
                            'หมายเหตุ: ดูรูปภาพเอกสารได้ในแอปพลิเคชัน',
                            style: pw.TextStyle(
                              font: thaiFont,
                              fontSize: 10,
                              color: PdfColors.grey600,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Footer
                  pw.Spacer(),
                  pw.Divider(),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'สร้างเมื่อ: ${_formatDateTime(DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                          font: thaiFont,
                        ),
                      ),
                      pw.Text(
                        'ระบบจัดการหมู่บ้าน',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                          font: thaiFont,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      print('PDF created, trying to share...');

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'bill_${bill.billId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );

      print('PDF shared successfully');

    } catch (e) {
      print('PDF Error: $e');
      rethrow;
    }
  }

  // Export multiple bills as PDF
  static Future<void> exportBillsSummary(
      List<BillModel> bills, {
        String title = 'รายงานบิลทั้งหมด',
        Map<int, String>? houseNumbers,
        Map<int, String>? serviceNames,
      }) async {
    print('Creating bills summary PDF...');

    try {
      final pdf = pw.Document();
      final thaiFont = await _tryLoadThaiFont();

      final totalAmount = bills.fold<double>(0, (sum, bill) => sum + bill.amount);
      final paidAmount = bills.where((bill) => bill.paidStatus == 1)
          .fold<double>(0, (sum, bill) => sum + bill.amount);
      final unpaidAmount = totalAmount - paidAmount;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: thaiFont != null ? pw.ThemeData.withFont(base: thaiFont) : null,
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#2F4F4F'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        font: thaiFont,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'สร้างเมื่อ ${_formatDateTime(DateTime.now())}',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        font: thaiFont,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Summary
              pw.Container(
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'สรุปภาพรวม',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        font: thaiFont,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text('จำนวนบิล', style: pw.TextStyle(font: thaiFont)),
                            pw.Text(
                              '${bills.length}',
                              style: pw.TextStyle(
                                font: thaiFont,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Text('ยอดรวม', style: pw.TextStyle(font: thaiFont)),
                            pw.Text(
                              _formatCurrency(totalAmount),
                              style: pw.TextStyle(
                                font: thaiFont,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 18,
                                color: PdfColor.fromHex('#2F4F4F'),
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Text('ชำระแล้ว', style: pw.TextStyle(font: thaiFont)),
                            pw.Text(
                              _formatCurrency(paidAmount),
                              style: pw.TextStyle(
                                font: thaiFont,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 18,
                                color: PdfColor.fromHex('#6B8E23'),
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Text('ค้างชำระ', style: pw.TextStyle(font: thaiFont)),
                            pw.Text(
                              _formatCurrency(unpaidAmount),
                              style: pw.TextStyle(
                                font: thaiFont,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 18,
                                color: PdfColor.fromHex('#D2691E'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Table
              pw.Table.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: thaiFont,
                  fontSize: 10,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#2F4F4F'),
                ),
                cellStyle: pw.TextStyle(font: thaiFont, fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                data: <List<String>>[
                  <String>[
                    'บิล ID',
                    'บ้านเลขที่',
                    'ประเภท',
                    'จำนวนเงิน',
                    'วันออกบิล',
                    'วันครบกำหนด',
                    'สถานะ'
                  ],
                  ...bills.map((bill) => [
                    '#${bill.billId.toString().padLeft(6, '0')}',
                    houseNumbers?[bill.houseId] ?? bill.houseId.toString(),
                    _getServiceNameTh(serviceNames?[bill.service]),
                    _formatCurrency(bill.amount),
                    _formatDate(bill.billDate),
                    _formatDate(bill.dueDate),
                    _getStatusText(bill.status, bill.paidStatus),
                  ]).toList(),
                ],
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerHeight: 25,
                cellHeight: 20,
                columnWidths: {
                  0: pw.FixedColumnWidth(60),
                  1: pw.FixedColumnWidth(60),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FixedColumnWidth(70),
                  4: pw.FixedColumnWidth(70),
                  5: pw.FixedColumnWidth(70),
                  6: pw.FlexColumnWidth(1.5),
                },
              ),
            ];
          },
        ),
      );

      print('Bills summary PDF created, trying to share...');

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'bills_summary_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );

      print('Bills summary PDF shared successfully');

    } catch (e) {
      print('PDF Error: $e');
      rethrow;
    }
  }

  // Helper method for creating detail rows
  static pw.Widget _buildDetailRow(String label, String value, pw.Font? font) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 120,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
              font: font,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              font: font,
            ),
          ),
        ),
      ],
    );
  }
}