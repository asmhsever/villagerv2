import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/pages/house/complaint/complaint_delete.dart';
import 'package:fullproject/pages/house/complaint/complaint_edit.dart';
import 'package:fullproject/services/image_service.dart';

// หน้าสำหรับดูรายละเอียดร้องเรียน (Enhanced UI with Natural Theme)
class ComplaintDetailScreen extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailScreen({Key? key, required this.complaint})
    : super(key: key);

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late Future<ComplaintModel?> _complaintFuture;

  // Theme Colors
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);
  static const Color softTerracotta = Color(0xFFD48B5C);
  static const Color clayOrange = Color(0xFFCC7748);

  @override
  void initState() {
    super.initState();
    _complaintFuture = ComplaintDomain.getById(widget.complaint.complaintId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        backgroundColor: softBrown,
        foregroundColor: ivoryWhite,
        elevation: 0,
        title: Text(
          'ร้องเรียน #${widget.complaint.complaintId}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: softBrown.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              onPressed: () {
                setState(() {
                  _complaintFuture = ComplaintDomain.getById(
                    widget.complaint.complaintId!,
                  );
                });
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<ComplaintModel?>(
        future: _complaintFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(softBrown),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูล...',
                    style: TextStyle(color: earthClay, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ivoryWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: earthClay.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: clayOrange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่สามารถโหลดข้อมูลร้องเรียนได้',
                      style: TextStyle(
                        color: earthClay,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final complaint = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge and Action Buttons
                _buildHeaderSection(complaint),
                const SizedBox(height: 20),

                // Main Information Cards
                _buildMainInfoSection(complaint),
                const SizedBox(height: 16),

                // Additional Details
                _buildAdditionalInfoSection(complaint),
                const SizedBox(height: 16),

                // Image Section
                if (complaint.img != null) _buildImageSection(complaint.img!),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(ComplaintModel complaint) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ivoryWhite, sandyTan.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: earthClay.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge and Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(complaint.status),
              _buildLevelBadge(complaint.level),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            complaint.header ?? 'ไม่มีหัวข้อ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: softBrown,
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          if (complaint.status?.toLowerCase() == 'pending' ||
              complaint.status == null)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editComplaint(complaint),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('แก้ไข'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: burntOrange,
                      foregroundColor: ivoryWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteComplaint(complaint),
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('ลบ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: clayOrange,
                      foregroundColor: ivoryWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMainInfoSection(ComplaintModel complaint) {
    return Container(
      decoration: BoxDecoration(
        color: ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: earthClay.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Description - Full width
          _buildDetailRow(
            Icons.description_rounded,
            'รายละเอียด',
            complaint.description ?? 'ไม่มีรายละเอียด',
            isLarge: true,
          ),
          _buildDivider(),

          // Two columns row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildCompactDetailItem(
                    Icons.home_rounded,
                    'บ้านเลขที่',
                    complaint.houseId.toString(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactDetailItem(
                    Icons.category_rounded,
                    'ประเภท',
                    _getTypeText(complaint.typeComplaint),
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(),

          // Privacy - Full width (or you can pair it with another item)
          _buildDetailRow(
            complaint.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
            'ความเป็นส่วนตัว',
            complaint.isPrivate ? 'ส่วนตัว' : 'สาธารณะ',
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection(ComplaintModel complaint) {
    return Container(
      decoration: BoxDecoration(
        color: ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: earthClay.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildCompactDetailItem(
                Icons.access_time_rounded,
                'วันที่สร้าง',
                _formatDateTime(complaint.createAt),
              ),
            ),
            if (complaint.updateAt != null) ...[
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompactDetailItem(
                  Icons.update_rounded,
                  'วันที่อัพเดท',
                  _formatDateTime(complaint.updateAt!),
                ),
              ),
            ] else ...[
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
              // Empty space if no update date
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: earthClay.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image_rounded, color: softBrown, size: 20),
                const SizedBox(width: 8),
                Text(
                  'รูปภาพประกอบ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: softBrown,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: earthClay.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: BuildImage(imagePath: imageUrl, tablePath: 'complaint'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isLarge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: beige,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: softBrown, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: earthClay,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge ? 16 : 15,
                    color: softBrown,
                    fontWeight: isLarge ? FontWeight.w500 : FontWeight.normal,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: beige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: softBrown, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: earthClay,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: softBrown,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: warmStone.withOpacity(0.3),
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color badgeColor;
    String statusText = _getStatusText(status);

    switch (status?.toLowerCase()) {
      case 'in_progress':
        badgeColor = burntOrange;
        break;
      case 'resolved':
        badgeColor = oliveGreen;
        break;
      case 'pending':
      default:
        badgeColor = clayOrange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String? level) {
    Color badgeColor;
    String levelText = _getLevelText(level);

    switch (level) {
      case '4':
      case '5':
        badgeColor = clayOrange;
        break;
      case '3':
        badgeColor = burntOrange;
        break;
      case '1':
        badgeColor = oliveGreen;
        break;
      case '2':
      default:
        badgeColor = softTerracotta;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text(
            levelText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeText(int type) {
    switch (type) {
      case 1:
        return 'สาธารณูปโภค';
      case 2:
        return 'ความปลอดภัย';
      case 3:
        return 'สิ่งแวดล้อม';
      case 4:
        return 'การบริการ';
      default:
        return 'อื่นๆ';
    }
  }

  void _deleteComplaint(ComplaintModel complaint) async {
    final result = await DeleteComplaintWidget.show(
      context: context,
      complaint: complaint,
      getTypeText: _getTypeText,
      getStatusText: _getStatusText,
    );

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  void _editComplaint(ComplaintModel complaint) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseComplaintEditPage(complaint: complaint),
      ),
    );

    if (result == true) {
      setState(() {
        _complaintFuture = ComplaintDomain.getById(
          widget.complaint.complaintId!,
        );
      });
    }
  }

  String _getLevelText(String? level) {
    if (level == null) return 'ปกติ';

    switch (level) {
      case '1':
        return 'ต่ำ';
      case '2':
        return 'ปกติ';
      case '3':
        return 'สูง';
      case '4':
      case '5':
        return 'เร่งด่วน';
      default:
        return 'ปกติ';
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'resolved':
        return 'เสร็จสิ้น';
      case 'pending':
      default:
        return 'รอดำเนินการ';
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const monthNames = [
        '',
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ];
      return '${date.day} ${monthNames[date.month]} ${date.year + 543} เวลา ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
