// lib/pages/law/complaint/complaint_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/complaint/complaint_detail.dart';
import 'package:fullproject/pages/law/complaint/complaint_detail_success.dart' hide ComplaintDetailPage;
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:intl/intl.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  Future<List<ComplaintModel>>? _complaints;
  LawModel? law;
  Map<int, String> houseMap = {};
  Map<int, String> complaintTypeMap = {};
  String? filterStatus;
  int? filterType;
  int? selectedHouseId;
  bool? filterPrivacy;
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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user is LawModel) {
        setState(() => law = user);
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

  Future<void> _loadHouseMap(int villageId) async {
    try {
      final houses = await SupabaseConfig.client
          .from('house')
          .select('house_id, house_number')
          .eq('village_id', villageId);

      setState(() {
        houseMap = {
          for (var house in houses)
            house['house_id']: house['house_number'].toString()
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
          for (var type in types)
            type.typeId: type.type ?? 'ไม่ระบุ'
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
    if (law != null) {
      setState(() {
        if (selectedHouseId != null) {
          // แสดงเฉพาะคำร้องของบ้านที่เลือก
          _complaints = ComplaintDomain.getAllInHouse(selectedHouseId!);
        } else {
          // แสดงทั้งหมู่บ้าน - ใช้ getAll() แทน getAllInVillage()
          // เพราะ getAllInVillage() กรองเฉพาะที่ไม่ private
          _complaints = ComplaintDomain.getAll();
        }
      });
    }
  }

  void _navigateToDetail(ComplaintModel complaint) async {
    Widget targetPage;

    // ถ้าคำร้องเสร็จสิ้นแล้ว ไปหน้า detail success
    if (complaint.status == 'resolved') {
      targetPage = ComplaintDetailSuccessPage(complaint: complaint);
    } else {
      // ถ้ายังไม่เสร็จสิ้น ไปหน้า detail ปกติ
      targetPage = ComplaintDetailPage(complaint: complaint);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetPage),
    );

    if (result == true) {
      await _refreshComplaints();
    }
  }

  List<ComplaintModel> _filterComplaints(List<ComplaintModel> complaints) {
    var filtered = complaints;

    // กรองตาม village_id ของ law
    filtered = filtered.where((c) {
      return houseMap.containsKey(c.houseId);
    }).toList();

    if (filterStatus != null) {
      filtered = filtered.where((c) => c.status == filterStatus).toList();
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

  Widget _buildHouseSelector() {
    if (houseMap.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // House Selector
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int?>(
              value: selectedHouseId,
              decoration: InputDecoration(
                labelText: 'เลือกบ้าน',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: warmStone),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: softBrown, width: 2),
                ),
                prefixIcon: Icon(Icons.home, color: earthClay),
                fillColor: ivoryWhite,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('ทั้งหมู่บ้าน'),
                ),
                ...houseMap.entries.map((entry) => DropdownMenuItem<int?>(
                  value: entry.key,
                  child: Text('บ้านเลขที่ ${entry.value}'),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  selectedHouseId = value;
                });
                _refreshComplaints();
              },
            ),
          ),

          const SizedBox(width: 12),

          // Privacy Filter
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<bool?>(
              value: filterPrivacy,
              decoration: InputDecoration(
                labelText: 'ความเป็นส่วนตัว',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: warmStone),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: softBrown, width: 2),
                ),
                prefixIcon: Icon(Icons.visibility, color: earthClay),
                fillColor: ivoryWhite,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem<bool?>(
                  value: null,
                  child: Text('ทั้งหมด'),
                ),
                DropdownMenuItem<bool?>(
                  value: false,
                  child: Row(
                    children: [
                      Icon(Icons.public, color: oliveGreen, size: 16),
                      const SizedBox(width: 4),
                      Text('สาธารณะ'),
                    ],
                  ),
                ),
                DropdownMenuItem<bool?>(
                  value: true,
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: burntOrange, size: 16),
                      const SizedBox(width: 4),
                      Text('ส่วนตัว'),
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
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? softBrown) : ivoryWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? (color ?? softBrown) : warmStone,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? ivoryWhite : earthClay,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    final houseNumber = houseMap[complaint.houseId] ?? 'ไม่ทราบ';
    final typeName = complaintTypeMap[complaint.typeComplaint] ?? 'ไม่ระบุ';
    final isHighPriority = complaint.level == '3' || complaint.level == '4';
    final isResolved = complaint.status == 'resolved';

    return Card(
      elevation: 3,
      color: ivoryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(complaint),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isResolved ? oliveGreen.withValues(alpha: 0.1) : beige,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isResolved ? Icons.check_circle : getTypeIcon(complaint.typeComplaint),
                      color: isResolved ? oliveGreen : softBrown,
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
                            color: softBrown,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'บ้านเลขที่ $houseNumber • $typeName',
                          style: TextStyle(
                            fontSize: 12,
                            color: earthClay,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isHighPriority)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                complaint.description,
                style: TextStyle(
                  fontSize: 14,
                  color: earthClay,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Status and Level Row
              Row(
                children: [
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(complaint.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isResolved) ...[
                          Icon(Icons.check, color: oliveGreen, size: 12),
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

                  const SizedBox(width: 8),

                  // Level
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getLevelColor(complaint.level).withValues(alpha: 0.2),
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
                      color: warmStone,
                    ),
                  ),
                ],
              ),

              // Private indicator
              if (complaint.isPrivate) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.lock, color: warmStone, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'ร้องเรียนแบบส่วนตัว',
                      style: TextStyle(
                        fontSize: 11,
                        color: warmStone,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        backgroundColor: softBrown,
        foregroundColor: ivoryWhite,
        elevation: 0,
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
      body: _complaints == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: softBrown),
            const SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(color: earthClay),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // House Selector
          _buildHouseSelector(),

          Expanded(
            child: FutureBuilder<List<ComplaintModel>>(
              future: _complaints,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: softBrown),
                        const SizedBox(height: 16),
                        Text(
                          'กำลังโหลดข้อมูล...',
                          style: TextStyle(color: earthClay),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: burntOrange, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'เกิดข้อผิดพลาด',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: burntOrange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: earthClay),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshComplaints,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: burntOrange,
                            foregroundColor: ivoryWhite,
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
                        Icon(Icons.report_outlined, color: warmStone, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีข้อมูลร้องเรียน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: earthClay,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedHouseId != null
                              ? 'ไม่มีคำร้องของบ้านนี้'
                              : 'ไม่มีข้อมูลร้องเรียนในระบบ',
                          style: TextStyle(color: earthClay),
                        ),
                      ],
                    ),
                  );
                } else {
                  final filtered = _filterComplaints(snapshot.data!);
                  final totalCount = filtered.length;
                  final pendingCount = filtered.where((c) =>
                  c.status == null || c.status == 'pending' || c.status == 'in_progress'
                  ).length;
                  final resolvedCount = filtered.where((c) => c.status == 'resolved').length;
                  final privateCount = filtered.where((c) => c.isPrivate).length;

                  return Column(
                    children: [
                      // Summary Card
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ivoryWhite,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: softBrown.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.analytics, color: softBrown),
                                const SizedBox(width: 8),
                                Text(
                                  selectedHouseId != null
                                      ? 'สรุปคำร้องบ้านเลขที่ ${houseMap[selectedHouseId]}'
                                      : 'สรุปข้อมูลร้องเรียน',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: softBrown,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '$totalCount',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: softBrown,
                                        ),
                                      ),
                                      Text(
                                        'ทั้งหมด',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: earthClay,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 30, color: warmStone),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '$pendingCount',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: burntOrange,
                                        ),
                                      ),
                                      Text(
                                        'รอดำเนินการ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: earthClay,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 30, color: warmStone),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '$resolvedCount',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: oliveGreen,
                                        ),
                                      ),
                                      Text(
                                        'เสร็จสิ้น',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: earthClay,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 30, color: warmStone),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '$privateCount',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: burntOrange,
                                        ),
                                      ),
                                      Text(
                                        'ส่วนตัว',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: earthClay,
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

                      // Filter Chips
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Text(
                                'กรอง: ',
                                style: TextStyle(
                                  color: earthClay,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'ทั้งหมด',
                                isSelected: filterStatus == null && filterType == null && filterPrivacy == null,
                                onTap: () => setState(() {
                                  filterStatus = null;
                                  filterType = null;
                                  filterPrivacy = null;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'รอดำเนินการ',
                                isSelected: filterStatus == 'pending',
                                onTap: () => setState(() => filterStatus = 'pending'),
                                color: burntOrange,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'กำลังดำเนินการ',
                                isSelected: filterStatus == 'in_progress',
                                onTap: () => setState(() => filterStatus = 'in_progress'),
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'เสร็จสิ้น',
                                isSelected: filterStatus == 'resolved',
                                onTap: () => setState(() => filterStatus = 'resolved'),
                                color: oliveGreen,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'สาธารณะ',
                                isSelected: filterPrivacy == false,
                                onTap: () => setState(() => filterPrivacy = false),
                                color: oliveGreen,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'ส่วนตัว',
                                isSelected: filterPrivacy == true,
                                onTap: () => setState(() => filterPrivacy = true),
                                color: burntOrange,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Complaints List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.filter_alt_off, color: warmStone, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'ไม่มีรายการตามเงื่อนไขที่เลือก',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: earthClay,
                                ),
                              ),
                            ],
                          ),
                        )
                            : RefreshIndicator(
                          color: softBrown,
                          backgroundColor: ivoryWhite,
                          onRefresh: _refreshComplaints,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              return _buildComplaintCard(filtered[index]);
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
        ],
      ),
    );
  }
}