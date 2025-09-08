import 'package:flutter/material.dart';
import 'package:fullproject/models/funds_model.dart';
import 'package:fullproject/pages/law/fund/fund_edit_page.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:intl/intl.dart';

class LawFundDetailPage extends StatelessWidget {
  final FundModel fund;

  const LawFundDetailPage({Key? key, required this.fund}) : super(key: key);

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '฿${formatter.format(amount)}';
  }

  void _showFullScreenImage(
    BuildContext context,
    String imageUrl,
    String title,
    String bucketPath,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imageUrl: imageUrl,
          title: title,
          bucketPath: bucketPath,
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LawFundEditPage(fund: fund)),
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
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                        Row(
                          children: [
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
                        SizedBox(width: 20),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _navigateToEdit(context),
                              child: Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      color: ThemeColors.ivoryWhite,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'แก้ไข',
                                      style: TextStyle(
                                        color: ThemeColors.ivoryWhite,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

            // Images Section - Display both receipt and approval images
            if (fund.receiptImg != null || fund.approvImg != null) ...[
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
                          Icons.image_outlined,
                          color: ThemeColors.softBrown,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'รูปภาพ',
                          style: TextStyle(
                            color: ThemeColors.softBrown,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Images Row
                    Row(
                      children: [
                        // Receipt Image
                        if (fund.receiptImg != null)
                          Expanded(
                            child: _buildImageCard(
                              context,
                              fund.receiptImg!,
                              'รูปใบเสร็จ',
                              Icons.receipt_long_outlined,
                              "funds/receipt",
                            ),
                          ),

                        if (fund.receiptImg != null && fund.approvImg != null)
                          SizedBox(width: 12),

                        // Approval Image
                        if (fund.approvImg != null)
                          Expanded(
                            child: _buildImageCard(
                              context,
                              fund.approvImg!,
                              'รูปหลักฐานอนุมัติ',
                              Icons.approval_outlined,
                              "funds/approv",
                            ),
                          ),
                      ],
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

  Widget _buildImageCard(
    BuildContext context,
    String imageUrl,
    String title,
    IconData icon,
    String bucketPath,
  ) {
    print(imageUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Icon(icon, color: ThemeColors.softTerracotta, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: ThemeColors.softTerracotta,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        // Image
        GestureDetector(
          onTap: () =>
              _showFullScreenImage(context, imageUrl, title, bucketPath),
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ThemeColors.sandyTan, width: 1),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.warmStone.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: BuildImage(imagePath: imageUrl, tablePath: bucketPath),
                ),
                // Tap indicator
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.zoom_in, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),

        // View button
        Center(
          child: TextButton(
            onPressed: () =>
                _showFullScreenImage(context, imageUrl, title, bucketPath),
            style: TextButton.styleFrom(
              backgroundColor: ThemeColors.softTerracotta.withOpacity(0.1),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'ดูขนาดเต็ม',
              style: TextStyle(
                color: ThemeColors.softTerracotta,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Full Screen Image Viewer
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String bucketPath;

  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.title,
    required this.bucketPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: BuildImage(imagePath: imageUrl, tablePath: bucketPath),
        ),
      ),
    );
  }
}
