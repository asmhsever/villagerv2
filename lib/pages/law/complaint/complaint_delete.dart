// lib/pages/law/complaint/complaint_delete.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/complaint_type_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:intl/intl.dart';

class LawComplaintDeletePage extends StatefulWidget {
  final ComplaintModel complaint;

  const LawComplaintDeletePage({super.key, required this.complaint});

  @override
  State<LawComplaintDeletePage> createState() => _LawComplaintDeletePageState();
}

class _LawComplaintDeletePageState extends State<LawComplaintDeletePage> {
  String? houseNumber;
  String? complaintTypeName;
  bool isLoading = false;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadAdditionalData();
  }

  Future<void> _loadAdditionalData() async {
    setState(() => isLoading = true);

    try {
      // โหลดข้อมูลบ้าน
      final house = await SupabaseConfig.client
          .from('house')
          .select('house_number')
          .eq('house_id', widget.complaint.houseId)
          .maybeSingle();

      // โหลดข้อมูลประเภทร้องเรียน
      final complaintType = await ComplaintTypeDomain.getById(
        widget.complaint.typeComplaint,
      );

      if (mounted) {
        setState(() {
          houseNumber = house?['house_number']?.toString() ?? 'ไม่ทราบ';
          complaintTypeName = complaintType?.type ?? 'ไม่ระบุ';
        });
      }
    } catch (e) {
      print('Error loading additional data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String formatDateFromString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'รออนุมัติ';
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'resolved':
        return 'เสร็จสิ้น';
      case null:
        return 'รอดำเนินการ';
      default:
        return status ?? 'ไม่ระบุ';
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return ThemeColors.burntOrange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return ThemeColors.oliveGreen;
      case null:
        return ThemeColors.warmStone;
      default:
        return ThemeColors.earthClay;
    }
  }

  String getLevelLabel(String level) {
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

  Color getLevelColor(String level) {
    switch (level) {
      case '1':
        return ThemeColors.oliveGreen;
      case '2':
        return Colors.orange;
      case '3':
        return ThemeColors.burntOrange;
      case '4':
        return Colors.red;
      default:
        return ThemeColors.earthClay;
    }
  }

  IconData getTypeIcon(int? typeId) {
    switch (typeId) {
      case 1:
        return Icons.water_damage;
      case 2:
        return Icons.electrical_services;
      case 3:
        return Icons.security;
      case 4:
        return Icons.clean_hands;
      case 5:
        return Icons.local_parking;
      default:
        return Icons.report_problem;
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_forever, color: Colors.red, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ยืนยันการลบ',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'คำเตือน',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'คุณต้องการลบร้องเรียนนี้หรือไม่?',
              style: TextStyle(color: ThemeColors.earthClay, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ข้อมูลที่จะถูกลบ:',
                    style: TextStyle(
                      color: ThemeColors.softBrown,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• หัวข้อ: ${widget.complaint.header}',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '• บ้านเลขที่: ${houseNumber ?? widget.complaint.houseId}',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '• ประเภท: ${complaintTypeName ?? 'ไม่ระบุ'}',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '• สถานะ: ${getStatusLabel(widget.complaint.status)}',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 13,
                    ),
                  ),
                  if (widget.complaint.complaintImg?.isNotEmpty == true)
                    Text(
                      '• รูปภาพประกอบ: มี',
                      style: TextStyle(
                        color: ThemeColors.earthClay,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors.warmStone,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: ThemeColors.ivoryWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_forever, size: 18),
                const SizedBox(width: 4),
                const Text(
                  'ลบถาวร',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _performDelete();
    }
  }

  Future<void> _performDelete() async {
    setState(() => isDeleting = true);

    try {
      final success = await ComplaintDomain.delete(
        widget.complaint.complaintId!,
      );

      if (success && mounted) {
        // แสดงการแจ้งเตือนความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: ThemeColors.ivoryWhite),
                const SizedBox(width: 8),
                const Text(
                  'ลบร้องเรียนสำเร็จ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: ThemeColors.oliveGreen,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // กลับไปหน้าก่อนหน้า 2 ครั้ง (ข้าม detail page)
        Navigator.pop(context, true); // กลับจาก delete page
        Navigator.pop(context, true); // กลับจาก detail page ไปยัง list page
      } else {
        throw Exception('ไม่สามารถลบร้องเรียนได้');
      }
    } catch (e) {
      print('Error deleting complaint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: ThemeColors.ivoryWhite),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'เกิดข้อผิดพลาด: ${e.toString()}',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: ThemeColors.ivoryWhite,
              onPressed: () => _confirmDelete(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isDeleting = false);
      }
    }
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Card(
      elevation: 3,
      color: backgroundColor ?? ThemeColors.ivoryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.beige,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? ThemeColors.softBrown,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor ?? ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: ThemeColors.earthClay,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? ThemeColors.softBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHighPriority =
        widget.complaint.level == '3' || widget.complaint.level == '4';

    return Scaffold(
      backgroundColor: ThemeColors.beige,
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: ThemeColors.ivoryWhite,
        elevation: 0,
        title: const Text(
          'ลบร้องเรียน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isDeleting ? null : () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ThemeColors.softBrown),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูล...',
                    style: TextStyle(color: ThemeColors.earthClay),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Warning Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: ThemeColors.ivoryWhite,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'การลบข้อมูลถาวร',
                                style: TextStyle(
                                  color: ThemeColors.ivoryWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'ข้อมูลที่ลบแล้วจะไม่สามารถกู้คืนได้',
                                style: TextStyle(
                                  color: ThemeColors.ivoryWhite,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Priority Banner
                  if (isHighPriority)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: ThemeColors.burntOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.priority_high,
                            color: ThemeColors.ivoryWhite,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'ร้องเรียนระดับความสำคัญสูง',
                            style: TextStyle(
                              color: ThemeColors.ivoryWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Complaint Summary
                  _buildInfoCard(
                    title: 'ข้อมูลร้องเรียนที่จะถูกลบ',
                    icon: getTypeIcon(widget.complaint.typeComplaint),
                    backgroundColor: Colors.red.withValues(alpha: 0.05),
                    iconColor: Colors.red,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.complaint.header,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.complaint.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Basic Information
                  _buildInfoCard(
                    title: 'ข้อมูลพื้นฐาน',
                    icon: Icons.info_outline,
                    children: [
                      _buildInfoRow(
                        'รหัสร้องเรียน:',
                        '${widget.complaint.complaintId}',
                      ),
                      _buildInfoRow(
                        'บ้านเลขที่:',
                        houseNumber ?? '${widget.complaint.houseId}',
                      ),
                      _buildInfoRow('ประเภท:', complaintTypeName ?? 'ไม่ระบุ'),
                      _buildInfoRow(
                        'วันที่ส่ง:',
                        formatDateFromString(widget.complaint.createAt),
                      ),
                      if (widget.complaint.updateAt != null)
                        _buildInfoRow(
                          'อัปเดตล่าสุด:',
                          formatDateFromString(widget.complaint.updateAt),
                        ),
                      _buildInfoRow(
                        'สถานะ:',
                        getStatusLabel(widget.complaint.status),
                        valueColor: getStatusColor(widget.complaint.status),
                      ),
                      _buildInfoRow(
                        'ระดับความสำคัญ:',
                        'ระดับ ${getLevelLabel(widget.complaint.level)}',
                        valueColor: getLevelColor(widget.complaint.level),
                      ),
                      _buildInfoRow(
                        'ความเป็นส่วนตัว:',
                        widget.complaint.isPrivate ? 'ส่วนตัว' : 'สาธารณะ',
                        valueColor: widget.complaint.isPrivate
                            ? ThemeColors.burntOrange
                            : ThemeColors.oliveGreen,
                      ),
                    ],
                  ),

                  // Image Information
                  if (widget.complaint.complaintImg?.isNotEmpty == true)
                    _buildInfoCard(
                      title: 'รูปภาพประกอบ',
                      icon: Icons.image,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'รูปภาพประกอบจะถูกลบไปด้วย',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.complaint.complaintImg!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 200,
                                  color: ThemeColors.beige,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          color: ThemeColors.earthClay,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'ไม่สามารถโหลดรูปภาพได้',
                                          style: TextStyle(
                                            color: ThemeColors.earthClay,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 80), // Space for buttons
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeColors.ivoryWhite,
          boxShadow: [
            BoxShadow(
              color: ThemeColors.softBrown.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: ThemeColors.warmStone),
                label: Text(
                  'ยกเลิก',
                  style: TextStyle(color: ThemeColors.warmStone),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ThemeColors.warmStone),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isDeleting ? null : _confirmDelete,
                icon: isDeleting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ThemeColors.ivoryWhite,
                          ),
                        ),
                      )
                    : const Icon(Icons.delete_forever),
                label: Text(
                  isDeleting ? 'กำลังลบ...' : 'ลบถาวร',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: ThemeColors.ivoryWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
