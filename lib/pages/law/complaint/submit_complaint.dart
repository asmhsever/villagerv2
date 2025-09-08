// lib/pages/law/complaint/in_progress_complaints_page.dart
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

class InProgressComplaintsPage extends StatefulWidget {
  const InProgressComplaintsPage({super.key});

  @override
  State<InProgressComplaintsPage> createState() =>
      _InProgressComplaintsPageState();
}

class _InProgressComplaintsPageState extends State<InProgressComplaintsPage> {
  Future<List<ComplaintModel>>? _complaints;
  LawModel? law;
  Map<int, String> houseMap = {};
  Map<int, String> complaintTypeMap = {};
  Map<int, String> lawMap = {}; // เพิ่ม map สำหรับข้อมูลนิติ
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
        setState(() => law = user);
        await _loadHouseMap(user.villageId);
        await _loadComplaintTypeMap();
        await _loadLawMap(user.villageId);
        await _refreshComplaints();
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

  Future<void> _loadLawMap(int villageId) async {
    try {
      final laws = await SupabaseConfig.client
          .from('law')
          .select('law_id, law_name')
          .eq('village_id', villageId);

      setState(() {
        lawMap = {
          for (var law in laws)
            law['law_id']: law['law_name']?.toString() ?? 'ไม่ระบุชื่อ',
        };
      });
    } catch (e) {
      print('Error loading law map: $e');
    }
  }

  Future<void> _refreshComplaints() async {
    if (law != null) {
      setState(() {
        // ดึงเฉพาะคำร้องที่ in_progress
        _complaints = ComplaintDomain.getByStatus('in_progress');
      });
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

  void _navigateToDetail(ComplaintModel complaint) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LawComplaintDetailPage(complaint: complaint),
      ),
    );

    if (result == true) {
      await _refreshComplaints();
    }
  }

  List<ComplaintModel> _filterComplaints(List<ComplaintModel> complaints) {
    // กรองตาม village_id ของ law และเฉพาะ status in_progress
    return complaints.where((c) {
      final inVillage = houseMap.containsKey(c.houseId);
      final isInProgress = c.status == 'in_progress';
      return inVillage && isInProgress;
    }).toList();
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    final houseNumber = houseMap[complaint.houseId] ?? 'ไม่ทราบ';
    final typeName = complaintTypeMap[complaint.typeComplaint] ?? 'ไม่ระบุ';
    final assignedLawName = lawMap[complaint.resolvedByLawId] ?? 'ไม่ระบุ';
    final isHighPriority = complaint.level == '3' || complaint.level == '4';
    final isMyComplaint = complaint.resolvedByLawId == law?.lawId;

    return Card(
      elevation: 3,
      color: ThemeColors.ivoryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(complaint),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isMyComplaint
                ? Border.all(color: Colors.blue.withOpacity(0.5), width: 2)
                : null,
          ),
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        getTypeIcon(complaint.typeComplaint),
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  complaint.header,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ThemeColors.softBrown,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isHighPriority) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.priority_high,
                                        color: Colors.red,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'ด่วน',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
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
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  complaint.description,
                  style: TextStyle(fontSize: 14, color: ThemeColors.earthClay),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Assigned Law Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMyComplaint
                        ? Colors.blue.withOpacity(0.1)
                        : ThemeColors.beige,
                    borderRadius: BorderRadius.circular(8),
                    border: isMyComplaint
                        ? Border.all(color: Colors.blue.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMyComplaint ? Icons.person : Icons.person_outline,
                        color: isMyComplaint
                            ? Colors.blue
                            : ThemeColors.earthClay,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ผู้รับผิดชอบ: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeColors.earthClay,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          assignedLawName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isMyComplaint
                                ? Colors.blue
                                : ThemeColors.softBrown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isMyComplaint)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'ของฉัน',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom Row
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            color: Colors.blue,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'กำลังดำเนินการ',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Level Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: getLevelColor(complaint.level).withOpacity(0.2),
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

                    // Private indicator
                    if (complaint.isPrivate) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.warmStone.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock,
                              color: ThemeColors.warmStone,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'ส่วนตัว',
                              style: TextStyle(
                                fontSize: 9,
                                color: ThemeColors.warmStone,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'สร้างเมื่อ',
                          style: TextStyle(
                            fontSize: 9,
                            color: ThemeColors.warmStone,
                          ),
                        ),
                        Text(
                          formatDateFromString(complaint.createAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: ThemeColors.warmStone,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToDetail(complaint),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text(
                      isMyComplaint ? 'ดำเนินการต่อ' : 'ดูรายละเอียด',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMyComplaint
                          ? Colors.blue
                          : ThemeColors.softBrown,
                      foregroundColor: ThemeColors.ivoryWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                  ),
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
    return Scaffold(
      backgroundColor: ThemeColors.beige,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.hourglass_empty, size: 24),
            const SizedBox(width: 8),
            const Text(
              'คำร้องกำลังดำเนินการ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
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
                  CircularProgressIndicator(color: Colors.blue),
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
                        CircularProgressIndicator(color: Colors.blue),
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
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: ThemeColors.earthClay),
                          textAlign: TextAlign.center,
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
                } else {
                  final filtered = _filterComplaints(snapshot.data ?? []);
                  final myComplaints = filtered
                      .where((c) => c.resolvedByLawId == law?.lawId)
                      .toList();
                  final otherComplaints = filtered
                      .where((c) => c.resolvedByLawId != law?.lawId)
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: ThemeColors.oliveGreen,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ไม่มีคำร้องกำลังดำเนินการ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.earthClay,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ทุกคำร้องได้รับการจัดการแล้ว',
                            style: TextStyle(color: ThemeColors.earthClay),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Summary Header
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.withOpacity(0.1),
                              Colors.blue.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              color: Colors.blue,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'คำร้องกำลังดำเนินการ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ของฉัน ${myComplaints.length} รายการ • ทั้งหมด ${filtered.length} รายการ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: ThemeColors.earthClay,
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
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${filtered.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Complaints List
                      Expanded(
                        child: RefreshIndicator(
                          color: Colors.blue,
                          backgroundColor: ThemeColors.ivoryWhite,
                          onRefresh: _refreshComplaints,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              // แสดงคำร้องของตัวเองก่อน
                              final sortedComplaints = [
                                ...myComplaints,
                                ...otherComplaints,
                              ];
                              return _buildComplaintCard(
                                sortedComplaints[index],
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
    );
  }
}
