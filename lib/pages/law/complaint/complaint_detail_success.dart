// lib/pages/law/complaint/complaint_detail_success.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/domains/success_complaint_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/complaint_type_model.dart';
import 'package:fullproject/models/success_complaint_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:intl/intl.dart';

class ComplaintDetailSuccessPage extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailSuccessPage({super.key, required this.complaint});

  @override
  State<ComplaintDetailSuccessPage> createState() => _ComplaintDetailSuccessPageState();
}

class _ComplaintDetailSuccessPageState extends State<ComplaintDetailSuccessPage> {
  late ComplaintModel currentComplaint;
  SuccessComplaintModel? successComplaint;
  String? houseNumber;
  String? complaintTypeName;
  String? lawName;
  bool isLoading = false;

  // Earthy Theme Colors
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);

  @override
  void initState() {
    super.initState();
    currentComplaint = widget.complaint;
    _loadAdditionalData();
  }

  Future<void> _loadAdditionalData() async {
    setState(() => isLoading = true);

    try {
      // โหลดข้อมูลบ้าน
      final house = await SupabaseConfig.client
          .from('house')
          .select('house_number')
          .eq('house_id', currentComplaint.houseId)
          .maybeSingle();

      // โหลดข้อมูลประเภทร้องเรียน
      final complaintType = await ComplaintTypeDomain.getById(currentComplaint.typeComplaint);

      // โหลดข้อมูลการดำเนินการเสร็จสิ้น
      final success = await SuccessComplaintDomain.getByComplaintId(currentComplaint.complaintId!);

      // โหลดชื่อนิติกร (ถ้ามีข้อมูลการดำเนินการ)
      String? lawName;
      if (success != null) {
        final law = await SupabaseConfig.client
            .from('law')
            .select('first_name, last_name')
            .eq('law_id', success.lawId)
            .maybeSingle();

        if (law != null) {
          lawName = '${law['first_name']} ${law['last_name']}';
        }
      }

      if (mounted) {
        setState(() {
          houseNumber = house?['house_number']?.toString() ?? 'ไม่ทราบ';
          complaintTypeName = complaintType?.type ?? 'ไม่ระบุ';
          successComplaint = success;
          this.lawName = lawName;
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
        return Colors.orange;
      case '3':
        return burntOrange;
      case '4':
        return Colors.red;
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

  Future<void> _refreshData() async {
    setState(() => isLoading = true);

    try {
      final updatedComplaint = await ComplaintDomain.getById(currentComplaint.complaintId!);
      if (updatedComplaint != null && mounted) {
        setState(() {
          currentComplaint = updatedComplaint;
        });
        await _loadAdditionalData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
            backgroundColor: burntOrange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
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
      color: backgroundColor ?? ivoryWhite,
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
                    color: beige,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor ?? softBrown, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor ?? softBrown,
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor, Widget? trailing}) {
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
                color: earthClay,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? softBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHighPriority = currentComplaint.level == '3' || currentComplaint.level == '4';

    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        backgroundColor: oliveGreen,
        foregroundColor: ivoryWhite,
        elevation: 0,
        title: const Text(
          'รายละเอียดคำร้องที่เสร็จสิ้น',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshData,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: oliveGreen),
            const SizedBox(height: 16),
            Text(
              'กำลังโหลด...',
              style: TextStyle(color: earthClay),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        color: oliveGreen,
        backgroundColor: ivoryWhite,
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
                  color: oliveGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: ivoryWhite, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'การดำเนินการเสร็จสิ้น',
                            style: TextStyle(
                              color: ivoryWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'คำร้องนี้ได้รับการแก้ไขเรียบร้อยแล้ว',
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

              // Priority Banner
              if (isHighPriority)
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
                      Icon(Icons.priority_high, color: ivoryWhite),
                      const SizedBox(width: 12),
                      Text(
                        'ร้องเรียนระดับความสำคัญสูง',
                        style: TextStyle(
                          color: ivoryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Header Summary Card
              Card(
                elevation: 5,
                color: ivoryWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              color: oliveGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              getTypeIcon(currentComplaint.typeComplaint),
                              color: oliveGreen,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentComplaint.header,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: softBrown,
                                  ),
                                ),
                                Text(
                                  'บ้านเลขที่ ${houseNumber ?? currentComplaint.houseId}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: earthClay,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: oliveGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'เสร็จสิ้น',
                              style: TextStyle(
                                color: ivoryWhite,
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
                                Text(
                                  'ระดับความสำคัญ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: earthClay,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: getLevelColor(currentComplaint.level).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'ระดับ ${getLevelLabel(currentComplaint.level)}',
                                    style: TextStyle(
                                      color: getLevelColor(currentComplaint.level),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 40, color: warmStone),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'ประเภท',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: earthClay,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  complaintTypeName ?? 'ไม่ระบุ',
                                  style: TextStyle(
                                    color: softBrown,
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
                  _buildInfoRow('รหัสร้องเรียน:', '${currentComplaint.complaintId}'),
                  _buildInfoRow('วันที่ส่ง:', formatDateFromString(currentComplaint.createAt)),
                  _buildInfoRow(
                    'ความเป็นส่วนตัว:',
                    currentComplaint.isPrivate ? 'ส่วนตัว' : 'สาธารณะ',
                    valueColor: currentComplaint.isPrivate ? burntOrange : oliveGreen,
                    trailing: Icon(
                      currentComplaint.isPrivate ? Icons.lock : Icons.public,
                      color: currentComplaint.isPrivate ? burntOrange : oliveGreen,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'รายละเอียดปัญหา:',
                    style: TextStyle(
                      color: earthClay,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: beige,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentComplaint.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: softBrown,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),

              // รูปภาพปัญหาเดิม
              if (currentComplaint.img != null && currentComplaint.img!.isNotEmpty)
                _buildInfoCard(
                  title: 'รูปภาพปัญหา',
                  icon: Icons.image,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        currentComplaint.img!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 200,
                              color: beige,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: earthClay, size: 48),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ไม่สามารถโหลดรูปภาพได้',
                                      style: TextStyle(color: earthClay),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),

              // ข้อมูลการดำเนินการ
              if (successComplaint != null)
                _buildInfoCard(
                  title: 'ข้อมูลการดำเนินการ',
                  icon: Icons.assignment_turned_in,
                  backgroundColor: oliveGreen.withValues(alpha: 0.05),
                  iconColor: oliveGreen,
                  children: [
                    _buildInfoRow('ผู้ดำเนินการ:', lawName ?? 'ไม่ระบุ', valueColor: oliveGreen),
                    _buildInfoRow('วันที่เสร็จสิ้น:', formatDateFromString(successComplaint!.successAt), valueColor: oliveGreen),
                    const SizedBox(height: 8),
                    Text(
                      'รายละเอียดการดำเนินการ:',
                      style: TextStyle(
                        color: earthClay,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: oliveGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: oliveGreen.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        successComplaint!.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: oliveGreen,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

              // รูปภาพการดำเนินการ
              if (successComplaint?.img != null && successComplaint!.img!.isNotEmpty)
                _buildInfoCard(
                  title: 'รูปภาพหลักฐานการดำเนินการ',
                  icon: Icons.camera_alt,
                  backgroundColor: oliveGreen.withValues(alpha: 0.05),
                  iconColor: oliveGreen,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        successComplaint!.img!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 200,
                              color: beige,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: earthClay, size: 48),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ไม่สามารถโหลดรูปภาพได้',
                                      style: TextStyle(color: earthClay),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}