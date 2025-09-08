import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/complaint/complaint_detail.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:intl/intl.dart';

class LawComplaintPage extends StatefulWidget {
  const LawComplaintPage({super.key});

  @override
  State<LawComplaintPage> createState() => _LawComplaintPageState();
}

class _LawComplaintPageState extends State<LawComplaintPage> {
  Future<List<ComplaintModel>>? _complaints;
  LawModel? lawData;
  Map<int, String> houseMap = {};
  Map<int, String> complaintTypeMap = {};
  String? filterStatus;
  int? filterType;
  int? selectedHouseId;
  bool? filterPrivacy;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user is LawModel) {
        setState(() => lawData = user);

        await _loadHouseMap(user.villageId);
        await _loadComplaintTypeMap();
        await _refreshComplaints();
      } else {
        setState(() {
          _complaints = Future.value([]);
        });
      }
    } catch (e) {
      print('Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
            backgroundColor: ThemeColors.burntOrange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadHouseMap(int villageId) async {
    try {
      final houses = await SupabaseConfig.client
          .from('house')
          .select('house_id, house_number')
          .eq('village_id', villageId);

      setState(() {
        houseMap = {
          for (var house in houses)
            house['house_id']: house['house_number'].toString(),
        };
      });
    } catch (e) {
      print('Error loading house map: $e');
    }
  }

  Future<void> _loadComplaintTypeMap() async {
    try {
      final types = await ComplaintTypeDomain.getAll();
      setState(() {
        complaintTypeMap = {
          for (var type in types) type.typeId: type.type ?? 'ไม่ระบุ',
        };
      });
    } catch (e) {
      print('Error loading complaint types: $e');
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
        return 'รอรับเรื่อง';
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'resolved':
        return 'เสร็จสิ้น';
      case null:
        return 'รอรับเรื่อง';
      default:
        return status ?? 'ไม่ระบุ';
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return ThemeColors.burntOrange;
      case 'in_progress':
        return Color(0xFF7B9FAB); // Dusty Blue
      case 'resolved':
        return ThemeColors.oliveGreen;
      case null:
        return ThemeColors.burntOrange;
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

  Future<void> _refreshComplaints() async {
    if (lawData != null) {
      setState(() {
        if (selectedHouseId != null) {
          _complaints = ComplaintDomain.getAllInHouse(selectedHouseId!);
        } else {
          _complaints = ComplaintDomain.getAll();
        }
      });
    }
  }

  // เพิ่มฟังก์ชันเหล่านี้ในคลาส
  void _showAcceptDialog(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'รับคำร้องเรียน',
          style: TextStyle(
            color: ThemeColors.softBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ยืนยันการรับคำร้องเรียนนี้?',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'หัวข้อ: ${complaint.header}',
                style: TextStyle(
                  color: ThemeColors.softBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: ThemeColors.warmStone),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptComplaint(complaint);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.oliveGreen,
              foregroundColor: ThemeColors.ivoryWhite,
            ),
            child: const Text('รับคำร้องเรียน'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ส่งคำร้องเรียน',
          style: TextStyle(
            color: ThemeColors.softBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ยืนยันการส่งคำร้องเรียนนี้?',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
            const SizedBox(height: 8),
            Text(
              'กรุณาตรวจสอบให้แน่ใจว่าได้แก้ไขปัญหาเรียบร้อยแล้ว',
              style: TextStyle(
                color: ThemeColors.warmStone,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'หัวข้อ: ${complaint.header}',
                style: TextStyle(
                  color: ThemeColors.softBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: ThemeColors.warmStone),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resolveComplaint(complaint);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.oliveGreen,
              foregroundColor: ThemeColors.ivoryWhite,
            ),
            child: const Text('ส่งคำร้องเรียน'),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสำหรับจัดการ actions
  void _acceptComplaint(ComplaintModel complaint) async {
    try {
      final acceptedByLawId = lawData!.lawId; // TODO: ใส่ law user ID จริง
      await ComplaintDomain.acceptComplaint(
        complaintId: complaint.complaintId!,
        acceptedByLawId: acceptedByLawId,
      );

      // รีเฟรช list
      _refreshComplaints();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('รับคำร้องเรียนสำเร็จ'),
          backgroundColor: ThemeColors.oliveGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resolveComplaint(ComplaintModel complaint) {
    _navigateToDetail(complaint); // ไปยังหน้ารายละเอียดเพื่อแก้ไข
  }

  void _navigateToDetail(ComplaintModel complaint) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LawComplaintDetailPage(complaint: complaint),
      ),
    );

    // if (result == true) {
    await _refreshComplaints();
    // }
  }

  List<ComplaintModel> _filterComplaints(List<ComplaintModel> complaints) {
    var filtered = complaints;

    // กรองตาม village_id ของ law
    filtered = filtered.where((c) {
      return houseMap.containsKey(c.houseId);
    }).toList();

    if (filterStatus != null) {
      if (filterStatus == 'pending') {
        filtered = filtered
            .where((c) => c.status == null || c.status == 'pending')
            .toList();
      } else {
        filtered = filtered.where((c) => c.status == filterStatus).toList();
      }
    }

    if (filterType != null) {
      filtered = filtered.where((c) => c.typeComplaint == filterType).toList();
    }

    // กรองตามความเป็นส่วนตัว
    if (filterPrivacy != null) {
      filtered = filtered.where((c) => c.isPrivate == filterPrivacy).toList();
    }

    return filtered;
  }

  Widget _buildSummaryCard(List<ComplaintModel> filtered) {
    if (houseMap.isEmpty) return const SizedBox.shrink();

    final totalCount = filtered.length;
    final pendingCount = filtered
        .where((c) => c.status == null || c.status == 'pending')
        .length;
    final inProgressCount = filtered
        .where((c) => c.status == 'in_progress')
        .length;
    final resolvedCount = filtered.where((c) => c.status == 'resolved').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.softBrown.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filters Section
          Row(
            children: [
              // House Selector
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'บ้าน',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeColors.earthClay,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: ThemeColors.warmStone),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: selectedHouseId,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 1,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: ThemeColors.earthClay,
                            size: 18,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'ทั้งหมู่บ้าน',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ThemeColors.earthClay,
                                ),
                              ),
                            ),
                            ...houseMap.entries.map(
                              (entry) => DropdownMenuItem<int?>(
                                value: entry.key,
                                child: Text(
                                  'บ้านเลขที่ ${entry.value}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ThemeColors.earthClay,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedHouseId = value;
                            });
                            _refreshComplaints();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Privacy Filter
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ความเป็นส่วนตัว',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeColors.earthClay,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: ThemeColors.warmStone),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<bool?>(
                          value: filterPrivacy,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 1,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: ThemeColors.earthClay,
                            size: 18,
                          ),
                          items: [
                            DropdownMenuItem<bool?>(
                              value: null,
                              child: Text(
                                'ทั้งหมด',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ThemeColors.earthClay,
                                ),
                              ),
                            ),
                            DropdownMenuItem<bool?>(
                              value: false,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.public,
                                    color: ThemeColors.oliveGreen,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'สาธารณะ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: ThemeColors.earthClay,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem<bool?>(
                              value: true,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    color: ThemeColors.burntOrange,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ส่วนตัว',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: ThemeColors.earthClay,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              filterPrivacy = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary Header
          Row(
            children: [
              Icon(Icons.analytics, color: ThemeColors.softBrown),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedHouseId != null
                      ? 'สรุปคำร้องบ้านเลขที่ ${houseMap[selectedHouseId]} (${totalCount} รายการ)'
                      : 'สรุปข้อมูลร้องเรียน (${totalCount} รายการ)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // รอรับเรื่อง (เป็นปุ่ม filter)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        filterStatus = 'pending';
                        filterType = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: filterStatus == 'pending'
                            ? ThemeColors.burntOrange.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: filterStatus == 'pending'
                            ? Border.all(
                                color: ThemeColors.burntOrange.withOpacity(0.3),
                              )
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$pendingCount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: filterStatus == 'pending'
                                  ? ThemeColors.burntOrange
                                  : ThemeColors.burntOrange.withOpacity(0.7),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pending_actions,
                                size: 10,
                                color: filterStatus == 'pending'
                                    ? ThemeColors.burntOrange
                                    : ThemeColors.burntOrange.withOpacity(0.7),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'รอรับเรื่อง',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ThemeColors.earthClay,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 30, color: ThemeColors.warmStone),

              // กำลังดำเนินการ (เป็นปุ่ม filter)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        filterStatus = 'in_progress';
                        filterType = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: filterStatus == 'in_progress'
                            ? Color(0xFF7B9FAB).withOpacity(0.1) // Dusty Blue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: filterStatus == 'in_progress'
                            ? Border.all(
                                color: Color(0xFF7B9FAB).withOpacity(0.3),
                              )
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$inProgressCount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: filterStatus == 'in_progress'
                                  ? Color(0xFF7B9FAB) // Dusty Blue
                                  : Color(0xFF7B9FAB).withOpacity(0.7),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.hourglass_empty,
                                size: 10,
                                color: filterStatus == 'in_progress'
                                    ? Color(0xFF7B9FAB) // Dusty Blue
                                    : Color(0xFF7B9FAB).withOpacity(0.7),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'ดำเนินการ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ThemeColors.earthClay,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 30, color: ThemeColors.warmStone),

              // เสร็จสิ้น (เป็นปุ่ม filter)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        filterStatus = 'resolved';
                        filterType = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: filterStatus == 'resolved'
                            ? ThemeColors.oliveGreen.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: filterStatus == 'resolved'
                            ? Border.all(
                                color: ThemeColors.oliveGreen.withOpacity(0.3),
                              )
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$resolvedCount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: filterStatus == 'resolved'
                                  ? ThemeColors.oliveGreen
                                  : ThemeColors.oliveGreen.withOpacity(0.7),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 10,
                                color: filterStatus == 'resolved'
                                    ? ThemeColors.oliveGreen
                                    : ThemeColors.oliveGreen.withOpacity(0.7),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'เสร็จสิ้น',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ThemeColors.earthClay,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    final houseNumber = houseMap[complaint.houseId] ?? 'ไม่ทราบ';
    final typeName = complaintTypeMap[complaint.typeComplaint] ?? 'ไม่ระบุ';
    final isHighPriority = complaint.level == '3' || complaint.level == '4';
    final isResolved = complaint.status == 'resolved';
    final isPending = complaint.status == 'pending' || complaint.status == null;
    final isInProgress = complaint.status == 'in_progress';
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0) {
          return const SizedBox.shrink();
        }

        final houseNumber = houseMap[complaint.houseId] ?? 'ไม่ทราบ';
        final typeName = complaintTypeMap[complaint.typeComplaint] ?? 'ไม่ระบุ';

        // ส่วนที่เหลือของ card...
        return Card(
          elevation: 3,
          color: ThemeColors.ivoryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToDetail(complaint),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Action Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isResolved
                              ? ThemeColors.oliveGreen.withValues(alpha: 0.1)
                              : ThemeColors.beige,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isResolved
                              ? Icons.check_circle
                              : getTypeIcon(complaint.typeComplaint),
                          color: isResolved
                              ? ThemeColors.oliveGreen
                              : ThemeColors.softBrown,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.header,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.softBrown,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'บ้านเลขที่ $houseNumber • $typeName',
                              style: TextStyle(
                                fontSize: 12,
                                color: ThemeColors.earthClay,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Priority Badge
                      if (isHighPriority)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ด่วน',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),

                      // Action Button (Right side)
                      _buildActionButton(
                        complaint,
                        isPending,
                        isInProgress,
                        isResolved,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    complaint.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: ThemeColors.earthClay,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Status and Level Row
                  Row(
                    children: [
                      // Status - ทำให้เป็นปุ่มกดได้
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              filterStatus = complaint.status ?? 'pending';
                              filterType = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor(
                                complaint.status,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  (filterStatus == complaint.status ||
                                      (filterStatus == 'pending' &&
                                          (complaint.status == null ||
                                              complaint.status == 'pending')))
                                  ? Border.all(
                                      color: getStatusColor(complaint.status),
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isResolved) ...[
                                  Icon(
                                    Icons.check,
                                    color: ThemeColors.oliveGreen,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                ] else if (complaint.status ==
                                    'in_progress') ...[
                                  Icon(
                                    Icons.hourglass_empty,
                                    color: Color(0xFF7B9FAB), // Dusty Blue
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                ] else ...[
                                  Icon(
                                    Icons.pending_actions,
                                    color: getStatusColor(complaint.status),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                Text(
                                  getStatusLabel(complaint.status),
                                  style: TextStyle(
                                    color: getStatusColor(complaint.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Level
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getLevelColor(
                            complaint.level,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ระดับ ${getLevelLabel(complaint.level)}',
                          style: TextStyle(
                            color: getLevelColor(complaint.level),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Date
                      Text(
                        formatDateFromString(complaint.createAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: ThemeColors.warmStone,
                        ),
                      ),
                    ],
                  ),

                  // Private indicator
                  if (complaint.isPrivate) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.lock,
                          color: ThemeColors.warmStone,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ร้องเรียนแบบส่วนตัว',
                          style: TextStyle(
                            fontSize: 11,
                            color: ThemeColors.warmStone,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget _buildComplaintCard(ComplaintModel complaint) {
  //   final houseNumber = houseMap[complaint.houseId] ?? 'ไม่ทราบ';
  //   final typeName = complaintTypeMap[complaint.typeComplaint] ?? 'ไม่ระบุ';
  //   final isHighPriority = complaint.level == '3' || complaint.level == '4';
  //   final isResolved = complaint.status == 'resolved';
  //   final isPending = complaint.status == 'pending' || complaint.status == null;
  //   final isInProgress = complaint.status == 'in_progress';
  //
  //   return Card(
  //     elevation: 3,
  //     color: ThemeColors.ivoryWhite,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  //     child: InkWell(
  //       borderRadius: BorderRadius.circular(12),
  //       onTap: () => _navigateToDetail(complaint),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Header Row with Action Button
  //             Row(
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.all(8),
  //                   decoration: BoxDecoration(
  //                     color: isResolved
  //                         ? ThemeColors.oliveGreen.withValues(alpha: 0.1)
  //                         : ThemeColors.beige,
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                   child: Icon(
  //                     isResolved
  //                         ? Icons.check_circle
  //                         : getTypeIcon(complaint.typeComplaint),
  //                     color: isResolved
  //                         ? ThemeColors.oliveGreen
  //                         : ThemeColors.softBrown,
  //                     size: 20,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         complaint.header,
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: ThemeColors.softBrown,
  //                         ),
  //                         maxLines: 1,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       Text(
  //                         'บ้านเลขที่ $houseNumber • $typeName',
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           color: ThemeColors.earthClay,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //
  //                 // Priority Badge
  //                 if (isHighPriority)
  //                   Container(
  //                     margin: const EdgeInsets.only(right: 8),
  //                     padding: const EdgeInsets.symmetric(
  //                       horizontal: 6,
  //                       vertical: 2,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       color: Colors.red.withValues(alpha: 0.2),
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                     child: Text(
  //                       'ด่วน',
  //                       style: TextStyle(
  //                         color: Colors.red,
  //                         fontWeight: FontWeight.bold,
  //                         fontSize: 10,
  //                       ),
  //                     ),
  //                   ),
  //
  //                 // Action Button (Right side)
  //                 _buildActionButton(
  //                   complaint,
  //                   isPending,
  //                   isInProgress,
  //                   isResolved,
  //                 ),
  //               ],
  //             ),
  //
  //             const SizedBox(height: 12),
  //
  //             // Description
  //             Text(
  //               complaint.description,
  //               style: TextStyle(fontSize: 14, color: ThemeColors.earthClay),
  //               maxLines: 2,
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //
  //             const SizedBox(height: 12),
  //
  //             // Status and Level Row
  //             Row(
  //               children: [
  //                 // Status - ทำให้เป็นปุ่มกดได้
  //                 Material(
  //                   color: Colors.transparent,
  //                   child: InkWell(
  //                     borderRadius: BorderRadius.circular(12),
  //                     onTap: () {
  //                       setState(() {
  //                         filterStatus = complaint.status ?? 'pending';
  //                         filterType = null;
  //                       });
  //                     },
  //                     child: Container(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 8,
  //                         vertical: 4,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         color: getStatusColor(
  //                           complaint.status,
  //                         ).withValues(alpha: 0.2),
  //                         borderRadius: BorderRadius.circular(12),
  //                         border:
  //                             (filterStatus == complaint.status ||
  //                                 (filterStatus == 'pending' &&
  //                                     (complaint.status == null ||
  //                                         complaint.status == 'pending')))
  //                             ? Border.all(
  //                                 color: getStatusColor(complaint.status),
  //                               )
  //                             : null,
  //                       ),
  //                       child: Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           if (isResolved) ...[
  //                             Icon(
  //                               Icons.check,
  //                               color: ThemeColors.oliveGreen,
  //                               size: 12,
  //                             ),
  //                             const SizedBox(width: 2),
  //                           ] else if (complaint.status == 'in_progress') ...[
  //                             Icon(
  //                               Icons.hourglass_empty,
  //                               color: Color(0xFF7B9FAB), // Dusty Blue
  //                               size: 12,
  //                             ),
  //                             const SizedBox(width: 2),
  //                           ] else ...[
  //                             Icon(
  //                               Icons.pending_actions,
  //                               color: getStatusColor(complaint.status),
  //                               size: 12,
  //                             ),
  //                             const SizedBox(width: 2),
  //                           ],
  //                           Text(
  //                             getStatusLabel(complaint.status),
  //                             style: TextStyle(
  //                               color: getStatusColor(complaint.status),
  //                               fontWeight: FontWeight.bold,
  //                               fontSize: 11,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //
  //                 const SizedBox(width: 8),
  //
  //                 // Level
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 8,
  //                     vertical: 4,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: getLevelColor(
  //                       complaint.level,
  //                     ).withValues(alpha: 0.2),
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   child: Text(
  //                     'ระดับ ${getLevelLabel(complaint.level)}',
  //                     style: TextStyle(
  //                       color: getLevelColor(complaint.level),
  //                       fontWeight: FontWeight.bold,
  //                       fontSize: 11,
  //                     ),
  //                   ),
  //                 ),
  //
  //                 const Spacer(),
  //
  //                 // Date
  //                 Text(
  //                   formatDateFromString(complaint.createAt),
  //                   style: TextStyle(
  //                     fontSize: 11,
  //                     color: ThemeColors.warmStone,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //
  //             // Private indicator
  //             if (complaint.isPrivate) ...[
  //               const SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   Icon(Icons.lock, color: ThemeColors.warmStone, size: 12),
  //                   const SizedBox(width: 4),
  //                   Text(
  //                     'ร้องเรียนแบบส่วนตัว',
  //                     style: TextStyle(
  //                       fontSize: 11,
  //                       color: ThemeColors.warmStone,
  //                       fontStyle: FontStyle.italic,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildActionButton(
    ComplaintModel complaint,
    bool isPending,
    bool isInProgress,
    bool isResolved,
  ) {
    if (isResolved) {
      // แสดงปุ่มดูรายละเอียด
      return Container(
        decoration: BoxDecoration(
          color: ThemeColors.oliveGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ThemeColors.oliveGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _navigateToDetail(complaint),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility,
                    size: 16,
                    color: ThemeColors.oliveGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ดู',
                    style: TextStyle(
                      color: ThemeColors.oliveGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (isPending) {
      // แสดงปุ่มรับคำร้องเรียน
      return Container(
        decoration: BoxDecoration(
          color: ThemeColors.oliveGreen,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.oliveGreen.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showAcceptDialog(complaint),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: ThemeColors.ivoryWhite,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'รับ',
                    style: TextStyle(
                      color: ThemeColors.ivoryWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (isInProgress) {
      // แสดงปุ่มส่งคำร้องเรียน
      return Container(
        decoration: BoxDecoration(
          color: ThemeColors.oliveGreen,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.oliveGreen.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showResolveDialog(complaint),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send, size: 16, color: ThemeColors.ivoryWhite),
                  const SizedBox(width: 4),
                  Text(
                    'ส่ง',
                    style: TextStyle(
                      color: ThemeColors.ivoryWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink(); // ถ้าไม่มีปุ่มให้แสดง
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.beige,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
        elevation: 1,
        title: const Text(
          'จัดการร้องเรียน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshComplaints,
              tooltip: 'รีเฟรช',
            ),
        ],
      ),
      body: SafeArea(
        child: _complaints == null
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
            : FutureBuilder<List<ComplaintModel>>(
                future: _complaints,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: ThemeColors.softBrown,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'กำลังโหลดข้อมูล...',
                            style: TextStyle(color: ThemeColors.earthClay),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: ThemeColors.burntOrange,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'เกิดข้อผิดพลาด',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.burntOrange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${snapshot.error}',
                              style: TextStyle(color: ThemeColors.earthClay),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshComplaints,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeColors.burntOrange,
                              foregroundColor: ThemeColors.ivoryWhite,
                            ),
                            child: const Text('ลองใหม่'),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.report_outlined,
                            color: ThemeColors.warmStone,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ไม่มีข้อมูลร้องเรียน',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.earthClay,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedHouseId != null
                                ? 'ไม่มีคำร้องของบ้านนี้'
                                : 'ไม่มีข้อมูลร้องเรียนในระบบ',
                            style: TextStyle(color: ThemeColors.earthClay),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final filtered = _filterComplaints(snapshot.data!);

                    return Column(
                      children: [
                        // Summary Card with Filters
                        _buildSummaryCard(filtered),

                        // Complaints List
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.filter_alt_off,
                                        color: ThemeColors.warmStone,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'ไม่มีรายการตามเงื่อนไขที่เลือก',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: ThemeColors.earthClay,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  color: ThemeColors.softBrown,
                                  backgroundColor: ThemeColors.ivoryWhite,
                                  onRefresh: _refreshComplaints,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 80),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      return _buildComplaintCard(
                                        filtered[index],
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    );
                  }
                },
              ),
      ),
    );
  }
}
