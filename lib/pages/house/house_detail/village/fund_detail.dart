import 'package:flutter/material.dart';
import 'package:fullproject/models/funds_model.dart';
import 'package:intl/intl.dart';
import 'package:fullproject/theme/Color.dart';

class HouseFundDetailPage extends StatelessWidget {
  final FundModel fund;

  const HouseFundDetailPage({Key? key, required this.fund}) : super(key: key);

  // Theme Colors

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '฿${formatter.format(amount)}';
  }

  // String _formatDate(DateTime? date) {
  //   if (date == null) return '-';
  //   final formatter = DateFormat('dd MMMM yyyy เวลา HH:mm น.', 'th');
  //   return formatter.format(date);
  // }
  //
  // String _formatDateShort(DateTime? date) {
  //   if (date == null) return '-';
  //   final formatter = DateFormat('dd/MM/yyyy HH:mm');
  //   return formatter.format(date);
  // }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = fund.type == 'income';
    final color = isIncome ? ThemeColors.oliveGreen : ThemeColors.burntOrange;
    final icon = isIncome
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final typeText = isIncome ? 'รายรับ' : 'รายจ่าย';

    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite,
      appBar: AppBar(
        title: Text(
          'รายละเอียดรายการ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.ivoryWhite,
            fontSize: 20,
          ),
        ),
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Type Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ThemeColors.ivoryWhite.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: ThemeColors.ivoryWhite, size: 20),
                        SizedBox(width: 8),
                        Text(
                          typeText,
                          style: TextStyle(
                            color: ThemeColors.ivoryWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Amount
                  Text(
                    '${isIncome ? '+' : '-'}${_formatCurrency(fund.amount)}',
                    style: TextStyle(
                      color: ThemeColors.ivoryWhite,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Date
                  Text(
                    fund.createdAt!.toIso8601String(),
                    style: TextStyle(
                      color: ThemeColors.ivoryWhite.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeColors.sandyTan, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.warmStone.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ThemeColors.softBrown,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'รายละเอียด',
                        style: TextStyle(
                          color: ThemeColors.softBrown,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Description
                  _buildDetailRow(
                    'คำอธิบาย',
                    fund.description,
                    Icons.description_outlined,
                  ),
                  SizedBox(height: 16),

                  // Amount
                  _buildDetailRow(
                    'จำนวนเงิน',
                    _formatCurrency(fund.amount),
                    Icons.monetization_on_outlined,
                  ),
                  SizedBox(height: 16),

                  // Type
                  _buildDetailRow('ประเภท', typeText, icon),
                  SizedBox(height: 16),

                  // Date/Time
                  _buildDetailRow(
                    'วันที่และเวลา',
                    fund.createdAt!.toIso8601String(),
                    Icons.access_time_outlined,
                  ),
                  SizedBox(height: 16),

                  // Fund ID
                  _buildDetailRow(
                    'รหัสรายการ',
                    '#${fund.fundId.toString().padLeft(6, '0')}',
                    Icons.tag_outlined,
                  ),
                ],
              ),
            ),

            // Receipt Image Section
            if (fund.receiptImg != null) ...[
              SizedBox(height: 16),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeColors.beige,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeColors.sandyTan, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.warmStone.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: ThemeColors.softBrown,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'หลักฐานการทำรายการ',
                          style: TextStyle(
                            color: ThemeColors.softBrown,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Image Container
                    GestureDetector(
                      onTap: () =>
                          _showFullScreenImage(context, fund.receiptImg!),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ThemeColors.sandyTan,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeColors.warmStone.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            fund.receiptImg!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                decoration: BoxDecoration(
                                  color: ThemeColors.ivoryWhite,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              ThemeColors.softBrown,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'กำลังโหลดรูปภาพ...',
                                        style: TextStyle(
                                          color: ThemeColors.earthClay,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: ThemeColors.burntOrange.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        size: 48,
                                        color: ThemeColors.burntOrange,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'ไม่สามารถโหลดรูปภาพได้',
                                        style: TextStyle(
                                          color: ThemeColors.burntOrange,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // View Full Size Button
                    Center(
                      child: TextButton.icon(
                        onPressed: () =>
                            _showFullScreenImage(context, fund.receiptImg!),
                        icon: Icon(
                          Icons.zoom_in_outlined,
                          color: ThemeColors.softTerracotta,
                        ),
                        label: Text(
                          'ดูขนาดเต็ม',
                          style: TextStyle(
                            color: ThemeColors.softTerracotta,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: ThemeColors.softTerracotta
                              .withOpacity(0.1),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ThemeColors.softBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ThemeColors.softBrown, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: ThemeColors.warmStone,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: ThemeColors.softBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Full Screen Image Viewer
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('หลักฐานการทำรายการ'),
        centerTitle: true,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'กำลังโหลดรูปภาพ...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'ไม่สามารถโหลดรูปภาพได้',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
