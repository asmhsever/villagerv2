// File: lib/pages/law/complaint/complaint_detail.dart
// Update: remove bottom bar; move "ลบคำร้อง" button under the "การจัดการคำร้อง" card.
// Also supports statuses: pending, received, in_progress, resolved, rejected.

import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/complaint_type_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/pages/law/complaint/complaint_delete.dart';
import 'package:fullproject/pages/law/complaint/complaint_success.dart';
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
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);

  static const Color softBorder = Color(0xFFD0C4B0);
  static const Color focusedBrown = Color(0xFF916846);
  static const Color inputFill = Color(0xFFFBF9F3);
  static const Color softTerracotta = Color(0xFFD48B5C);
  static const Color clayOrange = Color(0xFFCC7748);
  static const Color warmAmber = Color(0xFFDA9856);

  // Valid status options
  static const List<String> _statusOptions = <String>[
    'pending',
    'received',
    'in_progress',
    'resolved',
    'rejected',
  ];

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
        backgroundColor: clayOrange,
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
        backgroundColor: oliveGreen,
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
        return warmAmber;
      case 'received':
        return focusedBrown; // distinguish from pending
      case 'in_progress':
        return softTerracotta;
      case 'resolved':
        return oliveGreen;
      case 'rejected':
        return clayOrange;
      case null:
        return warmStone;
      default:
        return earthClay;
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
        return oliveGreen;
      case '2':
        return warmAmber;
      case '3':
        return softTerracotta;
      case '4':
        return clayOrange;
      default:
        return earthClay;
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
    try {
      final updatedComplaint = await ComplaintDomain.getById(
        currentComplaint.complaintId!,
      );
      if (updatedComplaint != null && mounted) {
        setState(() => currentComplaint = updatedComplaint);
        await _loadAdditionalData();
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (isUpdatingStatus) return;

    // Navigate to success form when resolved; no bottom button needed.
    if (newStatus == 'resolved') {
      _navigateToSuccess();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: getStatusColor(newStatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                newStatus == 'in_progress'
                    ? Icons.play_arrow
                    : newStatus == 'received'
                    ? Icons.mark_email_read_rounded
                    : newStatus == 'rejected'
                    ? Icons.block
                    : Icons.pending,
                color: getStatusColor(newStatus),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'อัปเดตสถานะ',
              style: TextStyle(
                color: getStatusColor(newStatus),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'เปลี่ยนสถานะเป็น "${getStatusLabel(newStatus)}" ใช่หรือไม่?',
          style: const TextStyle(color: earthClay),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: getStatusColor(newStatus),
              foregroundColor: ivoryWhite,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isUpdatingStatus = true);
    try {
      final success = await ComplaintDomain.updateStatus(
        complaintId: currentComplaint.complaintId!,
        status: newStatus,
      );
      if (success && mounted) {
        _showSuccessSnackBar('อัปเดตสถานะสำเร็จ');
        await _refreshData();
      } else {
        throw Exception('ไม่สามารถอัปเดตสถานะได้');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => isUpdatingStatus = false);
    }
  }

  void _navigateToSuccess() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LawSuccessComplaintFormPage(complaint: currentComplaint),
      ),
    );
    if (result == true) Navigator.pop(context, true);
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
      color: backgroundColor ?? ivoryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      shadowColor: softBrown.withValues(alpha: 0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor ?? ivoryWhite,
              (backgroundColor ?? ivoryWhite).withValues(alpha: 0.8),
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
                      color: sandyTan,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: softBrown.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor ?? softBrown, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: iconColor ?? softBrown,
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
          color: inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: softBorder, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(
                  color: earthClay,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? softBrown,
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

  Widget _buildImageWidget(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            color: beige,
            child: Center(
              child: CircularProgressIndicator(
                color: softBrown,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: beige,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: earthClay, size: 48),
                SizedBox(height: 8),
                Text(
                  'ไม่สามารถโหลดรูปภาพได้',
                  style: TextStyle(color: earthClay),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHighPriority =
        currentComplaint.level == '3' || currentComplaint.level == '4';

    return Scaffold(
      backgroundColor: inputFill,
      appBar: AppBar(
        backgroundColor: softBrown,
        foregroundColor: ivoryWhite,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [softBrown, focusedBrown],
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
              color: ivoryWhite,
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
                            color: clayOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_rounded,
                            color: clayOrange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ลบ',
                          style: TextStyle(
                            color: clayOrange,
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
                  CircularProgressIndicator(color: softBrown),
                  SizedBox(height: 16),
                  Text('กำลังโหลด...', style: TextStyle(color: earthClay)),
                ],
              ),
            )
          : RefreshIndicator(
              color: softBrown,
              backgroundColor: ivoryWhite,
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
                            colors: [clayOrange, softTerracotta],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: clayOrange.withValues(alpha: 0.3),
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
                                color: ivoryWhite,
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
                                      color: ivoryWhite,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'ต้องดำเนินการโดยเร่งด่วน',
                                    style: TextStyle(
                                      color: ivoryWhite,
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
                      color: ivoryWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                      shadowColor: softBrown.withValues(alpha: 0.15),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [ivoryWhite, inputFill],
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
                                            color: softBrown,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'บ้านเลขที่ ${houseNumber ?? currentComplaint.houseId}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: earthClay,
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
                                        color: ivoryWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      softBorder,
                                      softBorder.withValues(alpha: 0.3),
                                      softBorder,
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
                                            color: earthClay,
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
                                    color: softBorder,
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Text(
                                          'ประเภท',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: earthClay,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          complaintTypeName ?? 'ไม่ระบุ',
                                          style: const TextStyle(
                                            color: softBrown,
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
                          'รหัสร้องเรียน:',
                          '${currentComplaint.complaintId}',
                        ),
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
                              ? burntOrange
                              : oliveGreen,
                          trailing: Icon(
                            currentComplaint.isPrivate
                                ? Icons.lock
                                : Icons.public,
                            color: currentComplaint.isPrivate
                                ? burntOrange
                                : oliveGreen,
                            size: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'รายละเอียดปัญหา:',
                          style: TextStyle(
                            color: earthClay,
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
                              colors: [sandyTan, beige],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: softBorder, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: softBrown.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            currentComplaint.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: softBrown,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Status management
                    _buildInfoCard(
                      title: 'การจัดการคำร้อง',
                      icon: Icons.admin_panel_settings,
                      backgroundColor: softBrown.withValues(alpha: 0.05),
                      iconColor: softBrown,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.assignment, color: earthClay, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'อัปเดตสถานะคำร้อง:',
                              style: TextStyle(
                                color: earthClay,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: warmStone),
                            borderRadius: BorderRadius.circular(8),
                            color: ivoryWhite,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value:
                                  _statusOptions.contains(
                                    currentComplaint.status?.toLowerCase(),
                                  )
                                  ? currentComplaint.status!.toLowerCase()
                                  : null,
                              hint: const Text(
                                'เลือกสถานะ',
                                style: TextStyle(color: earthClay),
                              ),
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: softBrown,
                              ),
                              style: const TextStyle(
                                color: softBrown,
                                fontSize: 16,
                              ),
                              onChanged: isUpdatingStatus
                                  ? null
                                  : (String? newValue) {
                                      if (newValue != null &&
                                          newValue != currentComplaint.status) {
                                        _updateStatus(newValue);
                                      }
                                    },
                              items: _statusOptions
                                  .map<DropdownMenuItem<String>>(
                                    (String value) => DropdownMenuItem(
                                      value: value,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: getStatusColor(value),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(getStatusLabel(value)),
                                          if (value == 'resolved') ...[
                                            const Spacer(),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: oliveGreen,
                                              size: 16,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'หมายเหตุ: เลือก "เสร็จสิ้น" จะพาไปหน้าบันทึกผล • เลือก "ปฏิเสธ" จะบันทึกสถานะว่าไม่รับเรื่อง',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // DELETE button moved here (bottom of management section)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _navigateToDelete,
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'ลบคำร้อง',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (currentComplaint.img != null &&
                        currentComplaint.img!.isNotEmpty)
                      _buildInfoCard(
                        title: 'รูปภาพปัญหา',
                        icon: Icons.image,
                        children: [_buildImageWidget(currentComplaint.img!)],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
