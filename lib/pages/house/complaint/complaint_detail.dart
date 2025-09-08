import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/pages/house/complaint/complaint_delete.dart';
import 'package:fullproject/pages/house/complaint/complaint_edit.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/theme/Color.dart';

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

  @override
  void initState() {
    super.initState();
    _complaintFuture = ComplaintDomain.getById(widget.complaint.complaintId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.beige,
      appBar: AppBar(
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
        elevation: 0,
        title: Text(
          'ร้องเรียน #${widget.complaint.complaintId}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: ThemeColors.softBrown.withOpacity(0.3),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeColors.softBrown,
                    ),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูล...',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 16,
                    ),
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
                  color: ThemeColors.ivoryWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.earthClay.withOpacity(0.1),
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
                      color: ThemeColors.clayOrange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่สามารถโหลดข้อมูลร้องเรียนได้',
                      style: TextStyle(
                        color: ThemeColors.earthClay,
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
                if (complaint.complaintImg != null)
                  _buildImageSection(complaint.complaintImg!),
                const SizedBox(height: 16),
                if (complaint.status?.toLowerCase() == 'resolved')
                  _buildResolutionSection(complaint),
                const SizedBox(height: 16),
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
          colors: [
            ThemeColors.ivoryWhite,
            ThemeColors.sandyTan.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.1),
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
              color: ThemeColors.softBrown,
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
                      backgroundColor: ThemeColors.burntOrange,
                      foregroundColor: ThemeColors.ivoryWhite,
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
                  // Delete button with confirmation dialog
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(complaint),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('ลบข้อร้องเรียน'),
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: ThemeColors.mutedBurntSienna,
                          foregroundColor: ThemeColors.ivoryWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: ThemeColors.clayOrange.withOpacity(0.3),
                        ).copyWith(
                          // Hover effect for web/desktop
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color?>((
                                Set<MaterialState> states,
                              ) {
                                if (states.contains(MaterialState.hovered)) {
                                  return ThemeColors.clayOrange.withOpacity(
                                    0.1,
                                  );
                                }
                                if (states.contains(MaterialState.pressed)) {
                                  return ThemeColors.clickHighlight.withOpacity(
                                    0.2,
                                  );
                                }
                                return null;
                              }),
                        ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Confirmation dialog function
  void _showDeleteConfirmation(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeColors.ivoryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'ยืนยันการลบ',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'คุณแน่ใจหรือไม่ที่จะลบข้อร้องเรียนนี้? การดำเนินการนี้ไม่สามารถย้อนกลับได้',
            style: TextStyle(color: ThemeColors.earthClay),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ยกเลิก',
                style: TextStyle(color: ThemeColors.warmStone),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteComplaint(complaint);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.clayOrange,
                foregroundColor: ThemeColors.ivoryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  // Enhanced delete function with loading state
  void _deleteComplaint(ComplaintModel complaint) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('กำลังลบข้อร้องเรียน...'),
          backgroundColor: ThemeColors.warmStone,
        ),
      );

      // Perform delete
      await ComplaintDomain.delete(complaint.complaintId!);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ลบข้อร้องเรียนสำเร็จ'),
          backgroundColor: ThemeColors.oliveGreen,
        ),
      );
      Navigator.pop(context);

      // Refresh the list or update UI
      // setState(() {
      //   complaints.removeWhere((c) => c.complaintId == complaint.complaintId);
      // });
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
          backgroundColor: ThemeColors.clayOrange,
        ),
      );
    }
  }

  Widget _buildResolutionSection(ComplaintModel complaint) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeColors.oliveGreen.withOpacity(0.05),
            ThemeColors.oliveGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.oliveGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.oliveGreen.withOpacity(0.08),
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
            // Header with success icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.oliveGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: ThemeColors.ivoryWhite,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'แก้ไขเสร็จสิ้นแล้ว',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.oliveGreen,
                      ),
                    ),
                    Text(
                      'ผลการดำเนินการ',
                      style: TextStyle(
                        fontSize: 13,
                        color: ThemeColors.oliveGreen.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Resolved by information (if available)
            if (complaint.resolvedByLawId != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeColors.ivoryWhite.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ThemeColors.oliveGreen.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: ThemeColors.oliveGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ดำเนินการโดย',
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeColors.earthClay,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'เจ้าหน้าที่นิติ ID: ${complaint.resolvedByLawId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: ThemeColors.softBrown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Resolution description
            if (complaint.resolvedDescription != null &&
                complaint.resolvedDescription!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeColors.ivoryWhite.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ThemeColors.oliveGreen.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_rounded,
                          color: ThemeColors.oliveGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'รายละเอียดการแก้ไข',
                          style: TextStyle(
                            fontSize: 14,
                            color: ThemeColors.earthClay,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      complaint.resolvedDescription!,
                      style: TextStyle(
                        fontSize: 15,
                        color: ThemeColors.softBrown,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Resolution image (if available)
            if (complaint.resolvedImg != null &&
                complaint.resolvedImg!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeColors.ivoryWhite.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ThemeColors.oliveGreen.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_camera_rounded,
                          color: ThemeColors.oliveGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'รูปภาพผลการแก้ไข',
                          style: TextStyle(
                            fontSize: 14,
                            color: ThemeColors.earthClay,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: ThemeColors.oliveGreen.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: BuildImage(
                          imagePath: complaint.resolvedImg!,
                          tablePath: 'complaint/resolved',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoSection(ComplaintModel complaint) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.08),
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
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.08),
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
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.08),
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
                Icon(
                  Icons.image_rounded,
                  color: ThemeColors.softBrown,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'รูปภาพประกอบ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.softBrown,
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
                      color: ThemeColors.earthClay.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: BuildImage(
                  imagePath: imageUrl,
                  tablePath: 'complaint/complaint',
                ),
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
              color: ThemeColors.beige,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ThemeColors.softBrown, size: 20),
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
                    color: ThemeColors.earthClay,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge ? 16 : 15,
                    color: ThemeColors.softBrown,
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
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: ThemeColors.softBrown, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.earthClay,
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
              color: ThemeColors.softBrown,
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
      color: ThemeColors.warmStone.withOpacity(0.3),
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color badgeColor;
    String statusText = _getStatusText(status);

    switch (status?.toLowerCase()) {
      case 'in_progress':
        badgeColor = ThemeColors.burntOrange;
        break;
      case 'resolved':
        badgeColor = ThemeColors.oliveGreen;
        break;
      case 'pending':
      default:
        badgeColor = ThemeColors.clayOrange;
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
        badgeColor = ThemeColors.clayOrange;
        break;
      case '3':
        badgeColor = ThemeColors.burntOrange;
        break;
      case '1':
        badgeColor = ThemeColors.oliveGreen;
        break;
      case '2':
      default:
        badgeColor = ThemeColors.softTerracotta;
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

  // void _deleteComplaint(ComplaintModel complaint) async {
  //   final result = await DeleteComplaintWidget.show(
  //     context: context,
  //     complaint: complaint,
  //     getTypeText: _getTypeText,
  //     getStatusText: _getStatusText,
  //   );
  //
  //   if (result == true) {
  //     Navigator.pop(context, true);
  //   }
  // }

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
