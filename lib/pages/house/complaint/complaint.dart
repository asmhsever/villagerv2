import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/extensions/context_extensions.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/pages/house/complaint/complaint_detail.dart';
import 'package:fullproject/pages/house/complaint/complaint_form.dart';
import 'package:fullproject/pages/house/widgets/appbar.dart';
import 'package:fullproject/theme/Color.dart';

class HouseComplaintPage extends StatefulWidget {
  final HouseModel houseData; // ดูเฉพาะบ้านนี้เท่านั้น

  const HouseComplaintPage({Key? key, required this.houseData})
    : super(key: key);

  @override
  State<HouseComplaintPage> createState() => _HouseComplaintPageState();
}

class _HouseComplaintPageState extends State<HouseComplaintPage>
    with TickerProviderStateMixin {
  late Future<List<ComplaintModel>> _complaintsFuture;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<ComplaintModel> _allComplaints = [];
  List<ComplaintModel> _filteredComplaints = [];

  // Filter states
  String _statusFilter = 'all';
  String _levelFilter = 'all';
  String _typeFilter = 'all';

  // Theme Colors

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadComplaints() {
    _complaintsFuture = ComplaintDomain.getAllInHouse(widget.houseData.houseId);
    _complaintsFuture.then((complaints) {
      setState(() {
        _allComplaints = complaints;
        _applyFilters();
        _animationController.forward();
      });
    });
  }

  void _applyFilters() {
    _filteredComplaints = _allComplaints.where((complaint) {
      // Status filter
      bool statusMatch =
          _statusFilter == 'all' ||
          (_statusFilter == 'pending' &&
              complaint.status?.toLowerCase() == 'pending') ||
          (_statusFilter == 'in_progress' &&
              complaint.status?.toLowerCase() == 'in_progress') ||
          (_statusFilter == 'resolved' &&
              complaint.status?.toLowerCase() == 'resolved');

      // Level filter
      bool levelMatch =
          _levelFilter == 'all' ||
          (_levelFilter == '1' && complaint.level == '1') ||
          (_levelFilter == '2' && complaint.level == '2') ||
          (_levelFilter == '3' && complaint.level == '3') ||
          (_levelFilter == '4-5' &&
              (complaint.level == '4' || complaint.level == '5'));

      // Type filter
      bool typeMatch =
          _typeFilter == 'all' ||
          (_typeFilter == '1' && complaint.typeComplaint == 1) ||
          (_typeFilter == '2' && complaint.typeComplaint == 2) ||
          (_typeFilter == '3' && complaint.typeComplaint == 3) ||
          (_typeFilter == '4' && complaint.typeComplaint == 4);

      return statusMatch && levelMatch && typeMatch;
    }).toList();

    // Sort by creation date (newest first)
    _filteredComplaints.sort((a, b) => b.createAt.compareTo(a.createAt));
  }

  void _refreshComplaints() {
    _animationController.reset();
    setState(() {
      _loadComplaints();
    });
  }

  void _addComplaint({required int houseId}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseComplaintFormPage(houseId: houseId),
      ),
    );

    if (result == true) _refreshComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HouseAppBar(house: widget.houseData?.houseNumber),
      backgroundColor: ThemeColors.beige,
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),

          // Complaint List
          Expanded(
            child: RefreshIndicator(
              color: ThemeColors.softBrown,
              backgroundColor: ThemeColors.ivoryWhite,
              onRefresh: () async => _refreshComplaints(),
              child: FutureBuilder<List<ComplaintModel>>(
                future: _complaintsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  if (_filteredComplaints.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildComplaintList();
                },
              ),
            ),
          ),

          // Add Button
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: ThemeColors.softBrown,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ตัวกรอง',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeColors.softBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredComplaints.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.softBrown,
                    ),
                  ),
                ),
                const Spacer(),
                if (_statusFilter != 'all' ||
                    _levelFilter != 'all' ||
                    _typeFilter != 'all')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _statusFilter = 'all';
                        _levelFilter = 'all';
                        _typeFilter = 'all';
                        _applyFilters();
                      });
                    },
                    child: Text(
                      'ล้างทั้งหมด',
                      style: TextStyle(
                        color: ThemeColors.clayOrange,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Dropdown Filters
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              children: [
                _buildDropdownRow('สถานะ', _buildStatusDropdown()),
                const SizedBox(height: 12),
                _buildDropdownRow('ระดับ', _buildLevelDropdown()),
                const SizedBox(height: 12),
                _buildDropdownRow('ประเภท', _buildTypeDropdown()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, Widget dropdown) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ThemeColors.earthClay,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: dropdown),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    final Map<String, String> statusOptions = {
      'all': 'ทั้งหมด',
      'pending': 'รอดำเนินการ',
      'in_progress': 'กำลังดำเนินการ',
      'resolved': 'เสร็จสิ้น',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      height: 40,
      decoration: BoxDecoration(
        color: ThemeColors.sandyTan,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.warmStone, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          isExpanded: true,
          style: TextStyle(color: ThemeColors.earthClay, fontSize: 14),
          dropdownColor: ThemeColors.ivoryWhite,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ThemeColors.earthClay,
            size: 20,
          ),
          items: statusOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(
                  color: ThemeColors.earthClay,
                  fontWeight: _statusFilter == entry.key
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _statusFilter = newValue;
                _applyFilters();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildLevelDropdown() {
    final Map<String, String> levelOptions = {
      'all': 'ทั้งหมด',
      '1': 'ต่ำ',
      '2': 'ปกติ',
      '3': 'สูง',
      '4-5': 'เร่งด่วน',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      height: 40,
      decoration: BoxDecoration(
        color: ThemeColors.sandyTan,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.warmStone, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _levelFilter,
          isExpanded: true,
          style: TextStyle(color: ThemeColors.earthClay, fontSize: 14),
          dropdownColor: ThemeColors.ivoryWhite,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ThemeColors.earthClay,
            size: 20,
          ),
          items: levelOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(
                  color: ThemeColors.earthClay,
                  fontWeight: _levelFilter == entry.key
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _levelFilter = newValue;
                _applyFilters();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final Map<String, String> typeOptions = {
      'all': 'ทั้งหมด',
      '1': 'สาธารณูปโภค',
      '2': 'ความปลอดภัย',
      '3': 'สิ่งแวดล้อม',
      '4': 'การบริการ',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      height: 40,
      decoration: BoxDecoration(
        color: ThemeColors.sandyTan,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.warmStone, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _typeFilter,
          isExpanded: true,
          style: TextStyle(color: ThemeColors.earthClay, fontSize: 14),
          dropdownColor: ThemeColors.ivoryWhite,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ThemeColors.earthClay,
            size: 20,
          ),
          items: typeOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(
                  color: ThemeColors.earthClay,
                  fontWeight: _typeFilter == entry.key
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _typeFilter = newValue;
                _applyFilters();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'กำลังโหลดข้อมูลร้องเรียน...',
            style: TextStyle(color: ThemeColors.earthClay, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
              'เกิดข้อผิดพลาดในการโหลดข้อมูล',
              style: TextStyle(
                color: ThemeColors.earthClay,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshComplaints,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.burntOrange,
                foregroundColor: ThemeColors.ivoryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.feedback_outlined,
              size: 48,
              color: ThemeColors.warmStone,
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่พบข้อมูลร้องเรียนที่ตรงกับเงื่อนไข',
              style: TextStyle(
                color: ThemeColors.earthClay,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ลองปรับเปลี่ยนตัวกรองหรือสร้างร้องเรียนใหม่',
              style: TextStyle(color: ThemeColors.warmStone, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          itemCount: _filteredComplaints.length,
          itemBuilder: (context, index) {
            final complaint = _filteredComplaints[index];
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              child: ComplaintCard(
                complaint: complaint,
                onTap: () => _navigateToComplaintDetail(complaint),
                onStatusUpdate: _refreshComplaints,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ThemeColors.burntOrange, ThemeColors.softTerracotta],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.burntOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _addComplaint(houseId: widget.houseData.houseId),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: ThemeColors.ivoryWhite,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'สร้างร้องเรียนใหม่',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.ivoryWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToComplaintDetail(ComplaintModel complaint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintDetailScreen(complaint: complaint),
      ),
    ).then((result) {
      _refreshComplaints();
    });
  }
}

// Enhanced Complaint Card Widget
class ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback? onTap;
  final VoidCallback? onStatusUpdate;

  const ComplaintCard({
    Key? key,
    required this.complaint,
    this.onTap,
    this.onStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    _buildStatusAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.header,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: ThemeColors.softBrown,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(complaint.createAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeColors.earthClay,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPriorityBadge(),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  complaint.description,
                  style: TextStyle(
                    color: ThemeColors.earthClay,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Chips Row
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildTypeChip(),
                    if (complaint.isPrivate) _buildPrivacyChip(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAvatar() {
    Color color;
    IconData icon;
    String text;

    switch (complaint.status?.toLowerCase()) {
      case 'resolved':
        color = ThemeColors.oliveGreen;
        icon = Icons.check_circle_rounded;
        text = 'เสร็จสิ้น';
        break;
      case 'in_progress':
        color = ThemeColors.burntOrange;
        icon = Icons.sync_rounded;
        text = 'ดำเนินการ';
        break;
      case 'pending':
      default:
        color = ThemeColors.softTerracotta;
        icon = Icons.pending_rounded;
        text = 'รอดำเนินการ';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildPriorityBadge() {
    String text;
    Color color;

    switch (complaint.level) {
      case '1':
        text = 'ต่ำ';
        color = ThemeColors.oliveGreen;
        break;
      case '2':
        text = 'ปกติ';
        color = ThemeColors.burntOrange;
        break;
      case '3':
        text = 'สูง';
        color = ThemeColors.softTerracotta;
        break;
      case '4':
      case '5':
        text = 'เร่งด่วน';
        color = ThemeColors.clayOrange;
        break;
      default:
        text = 'ปกติ';
        color = ThemeColors.warmStone;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, color: color, size: 12),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip() {
    String text;
    Color color;

    switch (complaint.typeComplaint) {
      case 1:
        text = 'สาธารณูปโภค';
        color = ThemeColors.softTerracotta;
        break;
      case 2:
        text = 'ความปลอดภัย';
        color = ThemeColors.clayOrange;
        break;
      case 3:
        text = 'สิ่งแวดล้อม';
        color = ThemeColors.oliveGreen;
        break;
      case 4:
        text = 'การบริการ';
        color = ThemeColors.burntOrange;
        break;
      default:
        text = 'อื่นๆ';
        color = ThemeColors.warmStone;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPrivacyChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeColors.softBrown.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.softBrown.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, color: ThemeColors.softBrown, size: 12),
          const SizedBox(width: 2),
          Text(
            'ส่วนตัว',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
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
      return '${date.day} ${monthNames[date.month]} ${date.year + 543}';
    } catch (e) {
      return dateString;
    }
  }
}
