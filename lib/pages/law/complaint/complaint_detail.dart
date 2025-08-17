// lib/pages/law/complaint/complaint_detail.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/complaint_type_model.dart';
import 'package:fullproject/pages/law/complaint/complaint_edit.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:intl/intl.dart';

class ComplaintDetailPage extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailPage({super.key, required this.complaint});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  late ComplaintModel currentComplaint;
  String? houseNumber;
  String? complaintTypeName;
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
    try {
      // โหลดข้อมูลบ้าน
      final house = await SupabaseConfig.client
          .from('house')
          .select('house_number')
          .eq('house_id', currentComplaint.houseId)
          .maybeSingle();

      // โหลดข้อมูลประเภทร้องเรียน
      final complaintType = await ComplaintTypeDomain.getById(currentComplaint.typeComplaint);

      if (mounted) {
        setState(() {
          houseNumber = house?['house_number']?.toString() ?? 'ไม่ทราบ';
          complaintTypeName = complaintType?.type ?? 'ไม่ระบุ';
        });
      }
    } catch (e) {
      print('Error loading additional data: $e');
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
        return burntOrange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return oliveGreen;
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
        return Colors.orange;
      case '3':
        return burntOrange;
      case '4':
        return Colors.red;
      default:
        return earthClay;
    }
  }

  IconData getStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'in_progress':
        return Icons.construction;
      case 'resolved':
        return Icons.check_circle;
      case null:
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  IconData getLevelIcon(String level) {
    switch (level) {
      case '1':
        return Icons.info_outline;
      case '2':
        return Icons.warning_amber_outlined;
      case '3':
        return Icons.priority_high;
      case '4':
        return Icons.emergency;
      default:
        return Icons.help_outline;
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

  Future<void> _updateStatus() async {
    final statusOptions = [
      {'value': null, 'label': 'รอดำเนินการ', 'color': warmStone},
      {'value': 'pending', 'label': 'รออนุมัติ', 'color': burntOrange},
      {'value': 'in_progress', 'label': 'กำลังดำเนินการ', 'color': Colors.blue},
      {'value': 'resolved', 'label': 'เสร็จสิ้น', 'color': oliveGreen},
    ];

    final selectedStatus = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: softBrown),
            const SizedBox(width: 8),
            Text(
              'อัปเดตสถานะ',
              style: TextStyle(color: softBrown, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusOptions.map((option) {
            return ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: option['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(option['label'] as String),
              onTap: () => Navigator.pop(context, option['value'] as String?),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: warmStone)),
          ),
        ],
      ),
    );

    if (selectedStatus != null) {
      setState(() => isLoading = true);

      try {
        await ComplaintDomain.updateStatus(
          complaintId: currentComplaint.complaintId!,
          status: selectedStatus == null ? 'pending' : selectedStatus,
        );

        // Refresh data
        final updatedComplaint = await ComplaintDomain.getById(currentComplaint.complaintId!);
        if (updatedComplaint != null && mounted) {
          setState(() {
            currentComplaint = updatedComplaint;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('อัปเดตสถานะสำเร็จ'),
              backgroundColor: oliveGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
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
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: burntOrange, size: 28),
            const SizedBox(width: 12),
            Text(
              'ยืนยันการลบ',
              style: TextStyle(color: softBrown, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'คุณต้องการลบร้องเรียนนี้หรือไม่?\nเมื่อลบแล้วจะไม่สามารถกู้คืนได้',
          style: TextStyle(color: earthClay),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: warmStone),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: burntOrange,
              foregroundColor: ivoryWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);

      try {
        await ComplaintDomain.delete(currentComplaint.complaintId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ลบร้องเรียนสำเร็จ'),
              backgroundColor: oliveGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
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
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);

    try {
      final updatedComplaint = await ComplaintDomain.getById(currentComplaint.complaintId!);
      if (updatedComplaint != null && mounted) {
        setState(() {
          currentComplaint = updatedComplaint;
        });
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
  }) {
    return Card(
      elevation: 3,
      color: ivoryWhite,
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
                  child: Icon(icon, color: softBrown, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: softBrown,
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
        backgroundColor: softBrown,
        foregroundColor: ivoryWhite,
        elevation: 0,
        title: const Text(
          'รายละเอียดร้องเรียน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshData,
            tooltip: 'รีเฟรชข้อมูล',
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: isLoading ? null : () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComplaintEditPage(complaint: currentComplaint),
                ),
              );
              if (result == true && mounted) {
                await _refreshData();
              }
            },
            tooltip: 'แก้ไข',
          ),
          PopupMenuButton(
            color: ivoryWhite,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'update_status',
                child: Row(
                  children: [
                    Icon(Icons.update, color: softBrown, size: 20),
                    const SizedBox(width: 8),
                    Text('อัปเดตสถานะ', style: TextStyle(color: softBrown)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: burntOrange, size: 20),
                    const SizedBox(width: 8),
                    Text('ลบร้องเรียน', style: TextStyle(color: burntOrange)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'update_status') {
                _updateStatus();
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: softBrown),
            const SizedBox(height: 16),
            Text(
              'กำลังโหลด...',
              style: TextStyle(color: earthClay),
            ),
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
              // Status Banner
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
                              color: beige,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              getTypeIcon(currentComplaint.typeComplaint),
                              color: softBrown,
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
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      getStatusIcon(currentComplaint.status),
                                      color: getStatusColor(currentComplaint.status),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'สถานะ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: earthClay,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(currentComplaint.status).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    getStatusLabel(currentComplaint.status),
                                    style: TextStyle(
                                      color: getStatusColor(currentComplaint.status),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      getLevelIcon(currentComplaint.level),
                                      color: getLevelColor(currentComplaint.level),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ความสำคัญ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: earthClay,
                                      ),
                                    ),
                                  ],
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Basic Information
              _buildInfoCard(
                title: 'ข้อมูลพื้นฐาน',
                icon: Icons.info_outline,
                children: [
                  _buildInfoRow('รหัสร้องเรียน:', '${currentComplaint.complaintId}'),
                  _buildInfoRow('ประเภท:', complaintTypeName ?? 'ไม่ระบุ'),
                  _buildInfoRow('วันที่ส่ง:', formatDateFromString(currentComplaint.createAt)),
                  if (currentComplaint.updateAt != null)
                    _buildInfoRow('อัปเดตล่าสุด:', formatDateFromString(currentComplaint.updateAt)),
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
                ],
              ),

              // Description
              _buildInfoCard(
                title: 'รายละเอียด',
                icon: Icons.description,
                children: [
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

              // Image Section
              if (currentComplaint.img != null && currentComplaint.img!.isNotEmpty)
                _buildInfoCard(
                  title: 'รูปภาพประกอบ',
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

              const SizedBox(height: 80), // Space for action buttons
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ivoryWhite,
          boxShadow: [
            BoxShadow(
              color: softBrown.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : _updateStatus,
                icon: Icon(Icons.update, color: softBrown),
                label: Text(
                  'อัปเดตสถานะ',
                  style: TextStyle(color: softBrown),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: softBrown),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplaintEditPage(complaint: currentComplaint),
                    ),
                  );
                  if (result == true && mounted) {
                    await _refreshData();
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('แก้ไข'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: burntOrange,
                  foregroundColor: ivoryWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}