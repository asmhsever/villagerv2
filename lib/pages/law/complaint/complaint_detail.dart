import 'package:fullproject/pages/law/complaint/send_complaint.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/complaint_type_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/pages/law/complaint/complaint_delete.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:intl/intl.dart';

class LawComplaintDetailPage extends StatefulWidget {
  final ComplaintModel complaint;

  const LawComplaintDetailPage({super.key, required this.complaint});

  @override
  State<LawComplaintDetailPage> createState() => _LawComplaintDetailPageState();
}

class _LawComplaintDetailPageState extends State<LawComplaintDetailPage> {
  late ComplaintModel currentComplaint;
  String? houseNumber;
  String? complaintTypeName;
  bool isLoading = false;
  bool isUpdatingStatus = false;

  // Palette

  @override
  void initState() {
    super.initState();
    currentComplaint = widget.complaint;
    _loadAdditionalData();
  }

  Future<void> _loadAdditionalData() async {
    setState(() => isLoading = true);
    try {
      final house = await SupabaseConfig.client
          .from('house')
          .select('house_number')
          .eq('house_id', currentComplaint.houseId)
          .maybeSingle();

      final ComplaintTypeModel? complaintType =
          await ComplaintTypeDomain.getById(currentComplaint.typeComplaint);

      if (mounted) {
        setState(() {
          houseNumber = house?['house_number']?.toString() ?? 'ไม่ทราบ';
          complaintTypeName = complaintType?.type ?? 'ไม่ระบุ';
        });
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- Helpers (feedback) ---
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeColors.clayOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeColors.oliveGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String formatDateFromString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (_) {
      return dateString;
    }
  }

  // --- Mapping ---
  String getStatusLabel(String? status) {
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

  Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return ThemeColors.warmAmber;
      case 'received':
        return ThemeColors.focusedBrown; // distinguish from pending
      case 'in_progress':
        return ThemeColors.softTerracotta;
      case 'resolved':
        return ThemeColors.oliveGreen;
      case 'rejected':
        return ThemeColors.clayOrange;
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
        return ThemeColors.warmAmber;
      case '3':
        return ThemeColors.softTerracotta;
      case '4':
        return ThemeColors.clayOrange;
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

  // --- Data ops ---
  Future<void> _refreshData() async {
    if (!mounted) return;

    try {
      final updatedComplaint = await ComplaintDomain.getById(
        currentComplaint.complaintId!,
      );

      if (updatedComplaint != null && mounted) {
        // ใช้ microtask เพื่อป้องกัน build conflicts
        await Future.microtask(() {});
        setState(() => currentComplaint = updatedComplaint);
        await _loadAdditionalData();
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    }
  }

  void _navigateToDelete() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LawComplaintDeletePage(complaint: currentComplaint),
      ),
    );
    if (result == true) Navigator.pop(context, true);
  }

  // --- UI helpers ---
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Card(
      elevation: 4,
      color: backgroundColor ?? ThemeColors.ivoryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      shadowColor: ThemeColors.softBrown.withValues(alpha: 0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor ?? ThemeColors.ivoryWhite,
              (backgroundColor ?? ThemeColors.ivoryWhite).withValues(
                alpha: 0.8,
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeColors.sandyTan,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeColors.softBrown.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? ThemeColors.softBrown,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: iconColor ?? ThemeColors.softBrown,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeColors.softBorder, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(
                  color: ThemeColors.earthClay,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? ThemeColors.softBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // เพิ่ม functions เหล่านี้ในคลาส _LawComplaintDetailPageState

  Future<void> _acceptComplaint() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeColors.oliveGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: ThemeColors.oliveGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'รับคำร้องเรียน',
                style: TextStyle(
                  color: ThemeColors.softBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                color: ThemeColors.oliveGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThemeColors.oliveGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ThemeColors.oliveGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'การรับคำร้องเรียน',
                        style: TextStyle(
                          color: ThemeColors.oliveGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'สถานะจะเปลี่ยนเป็น "กำลังดำเนินการ"',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ยืนยันการรับคำร้องเรียนนี้?',
              style: TextStyle(color: ThemeColors.earthClay, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'หัวข้อ: ${currentComplaint.header}',
                style: TextStyle(
                  color: ThemeColors.softBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors.warmStone,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.oliveGreen,
              foregroundColor: ThemeColors.ivoryWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'รับคำร้องเรียน',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _performAcceptComplaint();
    }
  }

  Future<void> _performAcceptComplaint() async {
    setState(() => isUpdatingStatus = true);

    try {
      const acceptedByLawId = 1; // แทนที่ด้วย law user ID จริง

      await ComplaintDomain.acceptComplaint(
        complaintId: currentComplaint.complaintId!,
        acceptedByLawId: acceptedByLawId,
      );

      if (mounted) {
        _showSuccessSnackBar('รับคำร้องเรียนสำเร็จ');
        await _refreshData();
      }
    } catch (e) {
      print('Error accepting complaint: $e');
      if (mounted) {
        _showErrorSnackBar(
          'เกิดข้อผิดพลาดในการรับคำร้องเรียน: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUpdatingStatus = false);
      }
    }
  }

  // Widget สำหรับแสดงปุ่ม Action ตามสถานะ
  Widget _buildStatusActionButtons() {
    final status = currentComplaint.status?.toLowerCase();

    if (status == 'pending' || status == null) {
      // แสดงปุ่มรับคำร้องเรียน
      return Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeColors.oliveGreen,
                  ThemeColors.oliveGreen.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.oliveGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: isUpdatingStatus ? null : _acceptComplaint,
              icon: isUpdatingStatus
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeColors.ivoryWhite,
                        ),
                      ),
                    )
                  : Icon(Icons.check_circle_outline, size: 24),
              label: Text(
                isUpdatingStatus ? 'กำลังรับเรื่อง...' : 'รับคำร้องเรียน',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: ThemeColors.ivoryWhite,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'in_progress') {
      // แสดงปุ่มส่งคำร้องเรียน
      return Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeColors.oliveGreen,
                  ThemeColors.oliveGreen.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.oliveGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: isUpdatingStatus ? null : _resolveComplaint,
              icon: isUpdatingStatus
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeColors.ivoryWhite,
                        ),
                      ),
                    )
                  : Icon(Icons.send_rounded, size: 24),
              label: Text(
                isUpdatingStatus ? 'กำลังส่งเรื่อง...' : 'ส่งคำร้องเรียน',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: ThemeColors.ivoryWhite,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink(); // ไม่แสดงปุ่มสำหรับสถานะอื่น
  }

  Future<void> _resolveComplaint() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LawComplaintResolveFormPage(complaint: currentComplaint),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BuildImage(
        imagePath: currentComplaint.complaintImg!,
        tablePath: "complaint/complaint",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHighPriority =
        currentComplaint.level == '3' || currentComplaint.level == '4';

    return Scaffold(
      backgroundColor: ThemeColors.inputFill,
      appBar: AppBar(
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ThemeColors.softBrown, ThemeColors.focusedBrown],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'รายละเอียดคำร้อง',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: isLoading ? null : _refreshData,
              tooltip: 'รีเฟรชข้อมูล',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'delete') _navigateToDelete();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: ThemeColors.ivoryWhite,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ThemeColors.clayOrange.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_rounded,
                            color: ThemeColors.clayOrange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ลบ',
                          style: TextStyle(
                            color: ThemeColors.clayOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ThemeColors.softBrown),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโหลด...',
                    style: TextStyle(color: ThemeColors.earthClay),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: ThemeColors.softBrown,
              backgroundColor: ThemeColors.ivoryWhite,
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (isHighPriority)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ThemeColors.clayOrange,
                              ThemeColors.softTerracotta,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeColors.clayOrange.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.priority_high,
                                color: ThemeColors.ivoryWhite,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ร้องเรียนระดับความสำคัญสูง',
                                    style: TextStyle(
                                      color: ThemeColors.ivoryWhite,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'ต้องดำเนินการโดยเร่งด่วน',
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

                    // Header Summary Card
                    Card(
                      elevation: 8,
                      color: ThemeColors.ivoryWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                      shadowColor: ThemeColors.softBrown.withValues(
                        alpha: 0.15,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ThemeColors.ivoryWhite,
                              ThemeColors.inputFill,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(
                                        currentComplaint.status,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: getStatusColor(
                                          currentComplaint.status,
                                        ).withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      getTypeIcon(
                                        currentComplaint.typeComplaint,
                                      ),
                                      color: getStatusColor(
                                        currentComplaint.status,
                                      ),
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentComplaint.header,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: ThemeColors.softBrown,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'บ้านเลขที่ ${houseNumber ?? currentComplaint.houseId}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: ThemeColors.earthClay,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          getStatusColor(
                                            currentComplaint.status,
                                          ),
                                          getStatusColor(
                                            currentComplaint.status,
                                          ).withValues(alpha: 0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: getStatusColor(
                                            currentComplaint.status,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      getStatusLabel(currentComplaint.status),
                                      style: const TextStyle(
                                        color: ThemeColors.ivoryWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              _buildStatusActionButtons(),
                              const SizedBox(height: 24),
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      ThemeColors.softBorder,
                                      ThemeColors.softBorder.withValues(
                                        alpha: 0.3,
                                      ),
                                      ThemeColors.softBorder,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Text(
                                          'ระดับความสำคัญ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: ThemeColors.earthClay,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getLevelColor(
                                              currentComplaint.level,
                                            ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: getLevelColor(
                                                currentComplaint.level,
                                              ).withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Text(
                                            'ระดับ ${getLevelLabel(currentComplaint.level)}',
                                            style: TextStyle(
                                              color: getLevelColor(
                                                currentComplaint.level,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 50,
                                    color: ThemeColors.softBorder,
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Text(
                                          'ประเภท',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: ThemeColors.earthClay,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          complaintTypeName ?? 'ไม่ระบุ',
                                          style: const TextStyle(
                                            color: ThemeColors.softBrown,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Base info
                    _buildInfoCard(
                      title: 'ข้อมูลคำร้องเรียน',
                      icon: Icons.report_problem,
                      children: [
                        _buildInfoRow(
                          'วันที่ส่ง:',
                          formatDateFromString(currentComplaint.createAt),
                        ),
                        if (currentComplaint.updateAt != null)
                          _buildInfoRow(
                            'อัปเดตล่าสุด:',
                            formatDateFromString(currentComplaint.updateAt),
                          ),
                        _buildInfoRow(
                          'ความเป็นส่วนตัว:',
                          currentComplaint.isPrivate ? 'ส่วนตัว' : 'สาธารณะ',
                          valueColor: currentComplaint.isPrivate
                              ? ThemeColors.burntOrange
                              : ThemeColors.oliveGreen,
                          trailing: Icon(
                            currentComplaint.isPrivate
                                ? Icons.lock
                                : Icons.public,
                            color: currentComplaint.isPrivate
                                ? ThemeColors.burntOrange
                                : ThemeColors.oliveGreen,
                            size: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'รายละเอียดปัญหา:',
                          style: TextStyle(
                            color: ThemeColors.earthClay,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [ThemeColors.sandyTan, ThemeColors.beige],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ThemeColors.softBorder,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ThemeColors.softBrown.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            currentComplaint.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: ThemeColors.softBrown,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (currentComplaint.complaintImg != null &&
                        currentComplaint.complaintImg!.isNotEmpty)
                      _buildInfoCard(
                        title: 'รูปภาพปัญหา',
                        icon: Icons.image,
                        children: [
                          _buildImageWidget(currentComplaint.complaintImg!),
                        ],
                      ),

                    // Show resolved information if status is resolved
                    if (currentComplaint.status?.toLowerCase() == 'resolved')
                      _buildInfoCard(
                        title: 'ข้อมูลการแก้ไข',
                        icon: Icons.task_alt,
                        backgroundColor: ThemeColors.oliveGreen.withValues(
                          alpha: 0.05,
                        ),
                        iconColor: ThemeColors.oliveGreen,
                        children: [
                          if (currentComplaint.updateAt != null)
                            _buildInfoRow(
                              'วันที่แก้ไข:',
                              formatDateFromString(currentComplaint.updateAt),
                              valueColor: ThemeColors.oliveGreen,
                            ),

                          if (currentComplaint.resolvedByLawId != null)
                            _buildInfoRow(
                              'ผู้แก้ไข:',
                              'เจ้าหน้าที่ ID: ${currentComplaint.resolvedByLawId}',
                              valueColor: ThemeColors.softBrown,
                            ),

                          if (currentComplaint.resolvedDescription != null &&
                              currentComplaint
                                  .resolvedDescription!
                                  .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'รายละเอียดการแก้ไข:',
                              style: TextStyle(
                                color: ThemeColors.earthClay,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ThemeColors.oliveGreen.withValues(
                                      alpha: 0.1,
                                    ),
                                    ThemeColors.oliveGreen.withValues(
                                      alpha: 0.05,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: ThemeColors.oliveGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ThemeColors.oliveGreen.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: ThemeColors.oliveGreen,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'การแก้ไขปัญหา',
                                        style: TextStyle(
                                          color: ThemeColors.oliveGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    currentComplaint.resolvedDescription!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: ThemeColors.softBrown,
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Show resolved image if exists
                          if (currentComplaint.resolvedImg != null &&
                              currentComplaint.resolvedImg!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'รูปภาพการแก้ไข:',
                              style: TextStyle(
                                color: ThemeColors.earthClay,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: ThemeColors.oliveGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ThemeColors.oliveGreen.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BuildImage(
                                  imagePath: currentComplaint.resolvedImg!,
                                  tablePath: "complaint/resolved",
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Success message
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: ThemeColors.oliveGreen.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ThemeColors.oliveGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: ThemeColors.oliveGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'คำร้องเรียนได้รับการแก้ไขเรียบร้อย',
                                          style: TextStyle(
                                            color: ThemeColors.oliveGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'ขอบคุณที่รอคอย เจ้าหน้าที่ได้ดำเนินการแก้ไขปัญหาแล้ว',
                                          style: TextStyle(
                                            color: ThemeColors.earthClay,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
