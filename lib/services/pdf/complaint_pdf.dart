import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/complaint_type_model.dart';
import 'package:intl/intl.dart';

class ComplaintPDFService {
  // Format currency
  static String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '฿${formatter.format(amount)}';
  }

  // Format date
  static String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'ไม่ระบุ';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (_) {
      return dateString;
    }
  }

  // Format date with time
  static String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'ไม่ระบุ';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (_) {
      return dateString;
    }
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

  // Get status text in Thai
  static String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'รออนุมัติ';
      case 'received':
        return 'รับเรื่องแล้ว';
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'resolved':
        return 'เสร็จสิ้น';
      case 'rejected':
        return 'ปฏิเสธ';
      case null:
        return 'รอดำเนินการ';
      default:
        return status ?? 'ไม่ระบุ';
    }
  }

  // Get status color
  static PdfColor _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return PdfColor.fromHex('#FFA500'); // Orange
      case 'received':
        return PdfColor.fromHex('#4682B4'); // Steel blue
      case 'in_progress':
        return PdfColor.fromHex('#FF6347'); // Tomato
      case 'resolved':
        return PdfColor.fromHex('#6B8E23'); // Olive green
      case 'rejected':
        return PdfColor.fromHex('#DC143C'); // Crimson
      case null:
        return PdfColor.fromHex('#708090'); // Slate gray
      default:
        return PdfColor.fromHex('#696969'); // Dim gray
    }
  }

  // Get level text in Thai
  static String _getLevelText(String level) {
    switch (level) {
      case '1':
        return 'ต่ำ';
      case '2':
        return 'ปานกลาง';
      case '3':
        return 'สูง';
      case '4':
        return 'ฉุกเฉิน';
      default:
        return level;
    }
  }

  // Get level color
  static PdfColor _getLevelColor(String level) {
    switch (level) {
      case '1':
        return PdfColor.fromHex('#6B8E23'); // Green
      case '2':
        return PdfColor.fromHex('#FFA500'); // Orange
      case '3':
        return PdfColor.fromHex('#FF6347'); // Red
      case '4':
        return PdfColor.fromHex('#DC143C'); // Crimson
      default:
        return PdfColors.grey;
    }
  }

  // Get privacy text
  static String _getPrivacyText(bool isPrivate) {
    return isPrivate ? 'ส่วนตัว' : 'สาธารณะ';
  }

  // Export single complaint as PDF
  static Future<void> exportComplaintDetail(
      ComplaintModel complaint, {
        String? houseNumber,
        String? complaintTypeName,
      }) async {
    print('Creating complaint PDF...');

    try {
      final pdf = pw.Document();
      final thaiFont = await _tryLoadThaiFont();

      final statusText = _getStatusText(complaint.status);
      final statusColor = _getStatusColor(complaint.status);
      final levelText = _getLevelText(complaint.level);
      final levelColor = _getLevelColor(complaint.level);
      final privacyText = _getPrivacyText(complaint.isPrivate);

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
                  color: statusColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'รายละเอียดร้องเรียน',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        font: thaiFont,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      complaint.header,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        font: thaiFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Text(
                            statusText,
                            style: pw.TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              font: thaiFont,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Basic Information
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
                      'ข้อมูลพื้นฐาน',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        font: thaiFont,
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    _buildDetailRow('เลขที่ร้องเรียน', '#${complaint.complaintId?.toString().padLeft(6, '0') ?? 'N/A'}', thaiFont),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('บ้านเลขที่', houseNumber ?? complaint.houseId.toString(), thaiFont),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('ประเภทร้องเรียน', complaintTypeName ?? 'ไม่ระบุ', thaiFont),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('ระดับความสำคัญ', 'ระดับ $levelText', thaiFont),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('ความเป็นส่วนตัว', privacyText, thaiFont),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('สถานะ', statusText, thaiFont),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Date Information
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

                    _buildDetailRow('วันที่ส่งร้องเรียน', _formatDateTime(complaint.createAt), thaiFont),
                    if (complaint.updateAt != null && complaint.updateAt!.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      _buildDetailRow('อัปเดตล่าสุด', _formatDateTime(complaint.updateAt), thaiFont),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Complaint Description
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F0F8FF'), // Alice blue
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Icon(pw.IconData(0xe0b7), color: PdfColors.blue800, size: 18), // Report icon
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'รายละเอียดปัญหา',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: thaiFont,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      complaint.description,
                      style: pw.TextStyle(
                        fontSize: 14,
                        font: thaiFont,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Resolved Information (if resolved)
              if (complaint.status?.toLowerCase() == 'resolved' &&
                  complaint.resolvedDescription != null &&
                  complaint.resolvedDescription!.isNotEmpty) ...[
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
                      pw.Row(
                        children: [
                          pw.Icon(pw.IconData(0xe86c), color: PdfColor.fromHex('#6B8E23'), size: 18), // Check circle
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'ข้อมูลการแก้ไข',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              font: thaiFont,
                              color: PdfColor.fromHex('#6B8E23'),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 12),

                      if (complaint.resolvedByLawId != null)
                        _buildDetailRow('ผู้แก้ไข', 'เจ้าหน้าที่ ID: ${complaint.resolvedByLawId}', thaiFont),

                      pw.SizedBox(height: 8),
                      pw.Text(
                        'รายละเอียดการแก้ไข:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          font: thaiFont,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        complaint.resolvedDescription!,
                        style: pw.TextStyle(
                          fontSize: 14,
                          font: thaiFont,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Images Information (without showing actual images)
              if (complaint.complaintImg?.isNotEmpty == true ||
                  (complaint.resolvedImg?.isNotEmpty == true &&
                      complaint.status?.toLowerCase() == 'resolved')) ...[
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
                      pw.Row(
                        children: [
                          pw.Icon(pw.IconData(0xe413), color: PdfColors.blue800, size: 18), // Photo icon
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'ไฟล์เอกสารประกอบ',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              font: thaiFont,
                              color: PdfColors.blue800,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),

                      if (complaint.complaintImg?.isNotEmpty == true)
                        pw.Text('• มีรูปภาพปัญหา', style: pw.TextStyle(font: thaiFont, fontSize: 12)),
                      if (complaint.resolvedImg?.isNotEmpty == true &&
                          complaint.status?.toLowerCase() == 'resolved')
                        pw.Text('• มีรูปภาพการแก้ไข', style: pw.TextStyle(font: thaiFont, fontSize: 12)),

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
                    'สร้างเมื่อ: ${_formatDateTime(DateTime.now().toIso8601String())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      font: thaiFont,
                    ),
                  ),
                  pw.Text(
                    'ระบบจัดการร้องเรียนหมู่บ้าน',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      font: thaiFont,
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      print('PDF created, trying to share...');

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'complaint_${complaint.complaintId ?? 'unknown'}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );

      print('PDF shared successfully');

    } catch (e) {
      print('PDF Error: $e');
      rethrow;
    }
  }

  // Export complaints summary as PDF
  static Future<void> exportComplaintsSummary(
      List<ComplaintModel> complaints, {
        String title = 'รายงานร้องเรียนทั้งหมด',
        Map<int, String>? houseNumbers,
        Map<int, String>? complaintTypeNames,
      }) async {
    print('Creating complaints summary PDF...');

    try {
      final pdf = pw.Document();
      final thaiFont = await _tryLoadThaiFont();

      // Calculate statistics
      final totalComplaints = complaints.length;
      final pendingComplaints = complaints.where((c) =>
          ['pending', 'in_progress', null].contains(c.status?.toLowerCase())).length;
      final resolvedComplaints = complaints.where((c) =>
      c.status?.toLowerCase() == 'resolved').length;
      final highPriorityComplaints = complaints.where((c) =>
          ['3', '4'].contains(c.level)).length;
      final privateComplaints = complaints.where((c) => c.isPrivate).length;

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
                      'สร้างเมื่อ ${_formatDateTime(DateTime.now().toIso8601String())}',
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

              // Summary Statistics
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

                    // Statistics Grid
                    pw.Table(
                      children: [
                        pw.TableRow(
                          children: [
                            _buildStatCard('จำนวนร้องเรียน', totalComplaints.toString(), PdfColor.fromHex('#2F4F4F'), thaiFont),
                            _buildStatCard('รอดำเนินการ', pendingComplaints.toString(), PdfColor.fromHex('#FFA500'), thaiFont),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            _buildStatCard('เสร็จสิ้น', resolvedComplaints.toString(), PdfColor.fromHex('#6B8E23'), thaiFont),
                            _buildStatCard('ความสำคัญสูง', highPriorityComplaints.toString(), PdfColor.fromHex('#DC143C'), thaiFont),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildStatCard('ร้องเรียนส่วนตัว', privateComplaints.toString(), PdfColor.fromHex('#4682B4'), thaiFont),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Complaints Table
              if (complaints.isNotEmpty) ...[
                pw.Text(
                  'รายละเอียดร้องเรียน',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: thaiFont,
                  ),
                ),
                pw.SizedBox(height: 10),

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
                      'ID',
                      'บ้านเลขที่',
                      'หัวข้อ',
                      'ประเภท',
                      'ระดับ',
                      'สถานะ',
                      'วันที่ส่ง',
                      'ความเป็นส่วนตัว'
                    ],
                    ...complaints.map((complaint) => [
                      '#${complaint.complaintId?.toString().padLeft(6, '0') ?? 'N/A'}',
                      houseNumbers?[complaint.houseId] ?? complaint.houseId.toString(),
                      complaint.header.length > 20
                          ? '${complaint.header.substring(0, 17)}...'
                          : complaint.header,
                      complaintTypeNames?[complaint.typeComplaint] ?? 'ไม่ระบุ',
                      _getLevelText(complaint.level),
                      _getStatusText(complaint.status),
                      _formatDate(complaint.createAt),
                      _getPrivacyText(complaint.isPrivate),
                    ]).toList(),
                  ],
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerHeight: 25,
                  cellHeight: 20,
                  columnWidths: {
                    0: pw.FixedColumnWidth(40),
                    1: pw.FixedColumnWidth(50),
                    2: pw.FlexColumnWidth(2.5),
                    3: pw.FlexColumnWidth(1.5),
                    4: pw.FixedColumnWidth(40),
                    5: pw.FlexColumnWidth(1),
                    6: pw.FixedColumnWidth(60),
                    7: pw.FixedColumnWidth(50),
                  },
                ),
              ] else ...[
                pw.Container(
                  padding: pw.EdgeInsets.all(20),
                  child: pw.Text(
                    'ไม่มีข้อมูลร้องเรียน',
                    style: pw.TextStyle(
                      font: thaiFont,
                      fontSize: 16,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ];
          },
        ),
      );

      print('Complaints summary PDF created, trying to share...');

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'complaints_summary_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );

      print('Complaints summary PDF shared successfully');

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

  // Helper method for statistics cards
  static pw.Widget _buildStatCard(String label, String value, PdfColor color, pw.Font? font) {
    return pw.Container(
      margin: pw.EdgeInsets.all(4),
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color.shade(0.3)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
              font: font,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: color,
              font: font,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}