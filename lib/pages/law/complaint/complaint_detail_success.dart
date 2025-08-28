// lib/pages/law/complaint/complaint_detail_success.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/domains/success_complaint_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/complaint_type_model.dart';
import 'package:fullproject/models/success_complaint_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:intl/intl.dart';

class LawComplaintDetailSuccessPage extends StatefulWidget {
  final ComplaintModel complaint;

  const LawComplaintDetailSuccessPage({super.key, required this.complaint});

  @override
  State<LawComplaintDetailSuccessPage> createState() =>
      _LawComplaintDetailSuccessPageState();
}

class _LawComplaintDetailSuccessPageState
    extends State<LawComplaintDetailSuccessPage> {
  late ComplaintModel currentComplaint;
  SuccessComplaintModel? successComplaint;
  String? houseNumber;
  String? complaintTypeName;
  String? lawName;
  bool isLoading = false;

  // Earthy Theme Colors

  @override
  void initState() {
    super.initState();
    currentComplaint = widget.complaint;
    _loadAdditionalData();
  }

  Future<void> _loadAdditionalData() async {
    setState(() => isLoading = true);

    try {
      // โหลดข้อมูลพร้อมกัน - แก้ไข type inference
      final List<Future<dynamic>> futures = [
        // โหลดข้อมูลบ้าน
        SupabaseConfig.client
            .from('house')
            .select('house_number')
            .eq('house_id', currentComplaint.houseId)
            .maybeSingle(),

        // โหลดข้อมูลประเภทร้องเรียน
        ComplaintTypeDomain.getById(currentComplaint.typeComplaint),

        // โหลดข้อมูลการดำเนินการเสร็จสิ้น (คืนค่าเป็น List)
        SuccessComplaintDomain.getByComplaintId(currentComplaint.complaintId!),
      ];

      final results = await Future.wait(futures);

      final house = results[0] as Map<String, dynamic>?;
      final complaintType = results[1] as ComplaintTypeModel?;
      final successList = results[2] as List<SuccessComplaintModel>;

      // เลือกข้อมูลการดำเนินการล่าสุด (ถ้ามีหลายรายการ)
      SuccessComplaintModel? latestSuccess;
      if (successList.isNotEmpty) {
        // เรียงตามวันที่ล่าสุด (ถ้ามี successAt) หรือ id ล่าสุด
        successList.sort((a, b) {
          // ถ้ามี successAt ให้เรียงตามวันที่
          if (a.successAt != null && b.successAt != null) {
            return b.successAt!.compareTo(a.successAt!);
          }
          // ถ้าไม่มี successAt ให้เรียงตาม id
          if (a.id != null && b.id != null) {
            return b.id!.compareTo(a.id!);
          }
          return 0;
        });
        latestSuccess = successList.first;
      }

      // โหลดชื่อนิติกร (ถ้ามีข้อมูลการดำเนินการ)
      String? lawName;
      if (latestSuccess?.lawId != null) {
        try {
          final law = await SupabaseConfig.client
              .from('law')
              .select('first_name, last_name')
              .eq('law_id', latestSuccess!.lawId!)
              .maybeSingle();

          if (law != null) {
            lawName = '${law['first_name']} ${law['last_name']}';
          }
        } catch (e) {
          debugPrint('Error loading law data: $e');
        }
      }

      if (mounted) {
        setState(() {
          houseNumber = house?['house_number']?.toString() ?? 'ไม่ทราบ';
          complaintTypeName = complaintType?.type ?? 'ไม่ระบุ';
          successComplaint = latestSuccess;
          this.lawName = lawName;
        });
      }
    } catch (e) {
      debugPrint('Error loading additional data: $e');
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeColors.burntOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String formatDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  // Unified format function that handles both DateTime and String
  String formatAnyDate(dynamic date) {
    if (date == null) return '-';
    if (date is DateTime) return formatDateTime(date);
    if (date is String) return formatDateString(date);
    return '-';
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

  Future<void> _refreshData() async {
    try {
      final updatedComplaint = await ComplaintDomain.getById(
        currentComplaint.complaintId!,
      );
      if (updatedComplaint != null && mounted) {
        setState(() {
          currentComplaint = updatedComplaint;
        });
        await _loadAdditionalData();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
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

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
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
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl, String emptyMessage) {
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
            color: ThemeColors.beige,
            child: Center(
              child: CircularProgressIndicator(
                color: ThemeColors.oliveGreen,
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
          color: ThemeColors.beige,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: ThemeColors.earthClay,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage,
                  style: const TextStyle(color: ThemeColors.earthClay),
                  textAlign: TextAlign.center,
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
      backgroundColor: ThemeColors.beige,
      appBar: AppBar(
        backgroundColor: ThemeColors.oliveGreen,
        foregroundColor: ThemeColors.ivoryWhite,
        elevation: 0,
        title: const Text(
          'รายละเอียดคำร้องที่เสร็จสิ้น',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading ? null : _refreshData,
            tooltip: 'รีเฟรชข้อมูล',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ThemeColors.oliveGreen),
                  const SizedBox(height: 16),
                  const Text(
                    'กำลังโหลด...',
                    style: TextStyle(color: ThemeColors.earthClay),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: ThemeColors.oliveGreen,
              backgroundColor: ThemeColors.ivoryWhite,
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Success Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: ThemeColors.oliveGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeColors.oliveGreen.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: ThemeColors.ivoryWhite,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'การดำเนินการเสร็จสิ้น',
                                  style: TextStyle(
                                    color: ThemeColors.ivoryWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'คำร้องนี้ได้รับการแก้ไขเรียบร้อยแล้ว',
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
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
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

                    // Header Summary Card
                    Card(
                      elevation: 5,
                      color: ThemeColors.ivoryWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ThemeColors.oliveGreen.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    getTypeIcon(currentComplaint.typeComplaint),
                                    color: ThemeColors.oliveGreen,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentComplaint.header,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: ThemeColors.softBrown,
                                        ),
                                      ),
                                      Text(
                                        'บ้านเลขที่ ${houseNumber ?? currentComplaint.houseId}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: ThemeColors.earthClay,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ThemeColors.oliveGreen,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'เสร็จสิ้น',
                                    style: TextStyle(
                                      color: ThemeColors.ivoryWhite,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Text(
                                        'ระดับความสำคัญ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ThemeColors.earthClay,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getLevelColor(
                                            currentComplaint.level,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'ระดับ ${getLevelLabel(currentComplaint.level)}',
                                          style: TextStyle(
                                            color: getLevelColor(
                                              currentComplaint.level,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: ThemeColors.warmStone,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Text(
                                        'ประเภท',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ThemeColors.earthClay,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        complaintTypeName ?? 'ไม่ระบุ',
                                        style: const TextStyle(
                                          color: ThemeColors.softBrown,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
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

                    // ข้อมูลคำร้องเดิม
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
                        const SizedBox(height: 8),
                        const Text(
                          'รายละเอียดปัญหา:',
                          style: TextStyle(
                            color: ThemeColors.earthClay,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ThemeColors.beige,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentComplaint.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: ThemeColors.softBrown,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // รูปภาพปัญหาเดิม
                    if (currentComplaint.img != null &&
                        currentComplaint.img!.isNotEmpty)
                      _buildInfoCard(
                        title: 'รูปภาพปัญหา',
                        icon: Icons.image,
                        children: [
                          _buildImageWidget(
                            currentComplaint.img!,
                            'ไม่สามารถโหลดรูปภาพปัญหาได้',
                          ),
                        ],
                      ),

                    // ข้อมูลการดำเนินการ
                    if (successComplaint != null)
                      _buildInfoCard(
                        title: 'ข้อมูลการดำเนินการ',
                        icon: Icons.assignment_turned_in,
                        backgroundColor: ThemeColors.oliveGreen.withValues(
                          alpha: 0.05,
                        ),
                        iconColor: ThemeColors.oliveGreen,
                        children: [
                          _buildInfoRow(
                            'ผู้ดำเนินการ:',
                            lawName ?? 'ไม่ระบุ',
                            valueColor: ThemeColors.oliveGreen,
                          ),
                          _buildInfoRow(
                            'วันที่เสร็จสิ้น:',
                            formatDateTime(successComplaint!.successAt),
                            valueColor: ThemeColors.oliveGreen,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'รายละเอียดการดำเนินการ:',
                            style: TextStyle(
                              color: ThemeColors.earthClay,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ThemeColors.oliveGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ThemeColors.oliveGreen.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              successComplaint!.description ??
                                  'ไม่มีรายละเอียด',
                            ),
                          ),
                        ],
                      ),

                    // รูปภาพการดำเนินการ
                    if (successComplaint?.img != null &&
                        successComplaint!.img!.isNotEmpty)
                      _buildInfoCard(
                        title: 'รูปภาพหลักฐานการดำเนินการ',
                        icon: Icons.camera_alt,
                        backgroundColor: ThemeColors.oliveGreen.withValues(
                          alpha: 0.05,
                        ),
                        iconColor: ThemeColors.oliveGreen,
                        children: [
                          _buildImageWidget(
                            successComplaint!.img!,
                            'ไม่สามารถโหลดรูปภาพหลักฐานได้',
                          ),
                        ],
                      ),

                    // ข้อความหากไม่มีข้อมูลการดำเนินการ
                    if (successComplaint == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: ThemeColors.warmStone.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ThemeColors.warmStone.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: ThemeColors.warmStone,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ยังไม่มีข้อมูลการดำเนินการ',
                              style: TextStyle(
                                color: ThemeColors.warmStone,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'รอการอัปเดตจากเจ้าหน้าที่',
                              style: TextStyle(
                                color: ThemeColors.warmStone,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
