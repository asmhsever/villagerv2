import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fullproject/models/funds_model.dart';
import 'package:intl/intl.dart';

class SimpleFundPDFService {
  // Format currency
  static String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '฿${formatter.format(amount)}';
  }

  // Format date
  static String _formatDate(DateTime? date) {
    if (date == null) return 'ไม่ระบุ';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // ลองโหลด Thai font แบบ optional
  static Future<pw.Font?> _tryLoadThaiFont() async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Noto_Sans_Thai/NotoSansThai-Regular.ttf");
      return pw.Font.ttf(fontData);
    } catch (e) {
      print('Thai font not available: $e');
      return null;
    }
  }

  // Export fund detail พร้อมจัดการ font
  static Future<void> exportFundDetail(FundModel fund) async {
    print('Creating improved PDF...');

    try {
      final pdf = pw.Document();
      final thaiFont = await _tryLoadThaiFont();

      final isIncome = fund.type == 'income';
      final typeText = isIncome ? 'รายรับ' : 'รายจ่าย';
      final color = isIncome ? PdfColor.fromHex('#6B8E23') : PdfColor.fromHex('#D2691E');

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
                      color: color,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'รายละเอียดรายการ',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            font: thaiFont,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '${isIncome ? '+' : '-'}${_formatCurrency(fund.amount)}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            font: thaiFont,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          typeText,
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

                  // Details Section
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
                          'รายละเอียด',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: thaiFont,
                          ),
                        ),
                        pw.SizedBox(height: 12),

                        _buildDetailRow('รหัสรายการ', '#${fund.fundId.toString().padLeft(6, '0')}', thaiFont),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('คำอธิบาย', fund.description, thaiFont),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('จำนวนเงิน', _formatCurrency(fund.amount), thaiFont),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('ประเภท', typeText, thaiFont),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('วันที่และเวลา', _formatDate(fund.createdAt), thaiFont),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('หมู่บ้าน ID', fund.villageId.toString(), thaiFont),
                      ],
                    ),
                  ),

                  // Images info (if exists)
                  if (fund.receiptImg?.isNotEmpty == true || fund.approvImg?.isNotEmpty == true) ...[
                    pw.SizedBox(height: 16),
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
                            'รูปภาพประกอบ',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              font: thaiFont,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          if (fund.receiptImg?.isNotEmpty == true)
                            pw.Text('• รูปใบเสร็จ: ${fund.receiptImg}',
                                style: pw.TextStyle(font: thaiFont, fontSize: 12)),
                          if (fund.approvImg?.isNotEmpty == true)
                            pw.Text('• รูปหลักฐานอนุมัติ: ${fund.approvImg}',
                                style: pw.TextStyle(font: thaiFont, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],

                  // Footer
                  pw.Spacer(),
                  pw.Divider(),
                  pw.Text(
                    'สร้างเมื่อ: ${_formatDate(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      font: thaiFont,
                    ),
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
        filename: 'fund_detail_${fund.fundId}.pdf',
      );

      print('PDF shared successfully');

    } catch (e) {
      print('PDF Error: $e');
      rethrow;
    }
  }

  // Helper สำหรับสร้างแถวรายละเอียด
  static pw.Widget _buildDetailRow(String label, String value, pw.Font? font) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 100,
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