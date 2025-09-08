import 'package:flutter/material.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/bill/bill_add_page.dart';
import 'package:fullproject/pages/law/bill/bill_detail_page.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:intl/intl.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage>
    with SingleTickerProviderStateMixin {
  List<BillModel> _bills = [];
  LawModel? law;
  Map<int, String> houseMap = {};
  Map<int, String> serviceMap = {};
  String? filterStatus;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user is LawModel) {
        setState(() => law = user);
        await _loadHouseAndServiceData();
        await _loadBills();
        _animationController.forward();
      } else {
        if (mounted) {
          setState(() {
            _bills = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล');
      }
    }
  }

  Future<void> _loadHouseAndServiceData() async {
    try {
      if (law != null) {
        final results = await Future.wait([
          SupabaseConfig.client
              .from('house')
              .select('house_id, house_number')
              .eq('village_id', law!.villageId),
          SupabaseConfig.client.from('service').select('service_id, name'),
        ]);

        final houseResponse = results[0];
        final serviceResponse = results[1];

        final Map<int, String> newHouseMap = {};
        for (var house in houseResponse) {
          newHouseMap[house['house_id'] as int] = (house['house_number'] ?? '')
              .toString();
        }

        final Map<int, String> newServiceMap = {};
        for (var service in serviceResponse) {
          newServiceMap[service['service_id'] as int] = (service['name'] ?? '')
              .toString();
        }

        if (mounted) {
          setState(() {
            houseMap = newHouseMap;
            serviceMap = newServiceMap;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading house and service data: $e');
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูลบ้านและบริการ');
      }
    }
  }

  Future<void> _loadBills() async {
    if (law == null) return;

    try {
      setState(() => _isLoading = true);

      final bills = await BillDomain.getAllInVillage(villageId: law!.villageId);

      if (mounted) {
        setState(() {
          _bills = bills;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bills: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูลบิล');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: ThemeColors.terracottaRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  String _getServiceNameTh(int serviceId) {
    const serviceTranslations = {
      'Area Fee': 'ค่าพื้นที่ส่วนกลาง',
      'Trash Fee': 'ค่าขยะ',
      'water Fee': 'ค่าน้ำ',
      'Water Fee': 'ค่าน้ำ',
      'enegy Fee': 'ค่าไฟ',
      'Energy Fee': 'ค่าไฟ',
      'Electricity Fee': 'ค่าไฟ',
    };

    final englishName = serviceMap[serviceId];
    return serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุ';
  }

  Future<void> _refreshBills() async {
    _animationController.reset();
    await _loadHouseAndServiceData();
    await _loadBills();
    _animationController.forward();
  }

  Future<void> _navigateToAddForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BillAddPage()),
    );
    if (!mounted) return;
    if (result == true) {
      await _refreshBills();
    }
  }

  Future<void> _navigateToDetail(BillModel bill) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BillDetailPage(bill: bill)),
    );
    if (!mounted) return;
    if (result == true) {
      await _refreshBills();
    }
  }

  List<BillModel> _filterBills(List<BillModel> bills) {
    List<BillModel> filtered = bills;

    // กรองตามสถานะ
    if (filterStatus != null && filterStatus!.isNotEmpty) {
      final target = filterStatus!.toUpperCase();

      if (target == 'RECEIPT_SENT') {
        // ชำระเสร็จสิ้น: สถานะ RECEIPT_SENT หรือ paid_status = 1
        filtered = filtered
            .where(
              (b) =>
                  b.status.toUpperCase() == 'RECEIPT_SENT' || b.paidStatus == 1,
            )
            .toList();
      } else if (target == 'UNPAID') {
        // ยังไม่ได้ชำระ: รวม PENDING, REJECTED, OVERDUE ที่ยังไม่จ่าย
        filtered = filtered
            .where(
              (b) =>
                  b.paidStatus == 0 &&
                  [
                    'PENDING',
                    'REJECTED',
                    'OVERDUE',
                    'DRAFT',
                  ].contains(b.status.toUpperCase()),
            )
            .toList();
      } else {
        // ที่เหลือกรองตรงตาม status
        filtered = filtered
            .where((b) => b.status.toUpperCase() == target)
            .toList();
      }
    }

    // กรองตามคำค้นหา
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((bill) {
        final houseNumber =
            houseMap[bill.houseId]?.toLowerCase() ?? '${bill.houseId}';
        final serviceName = _getServiceNameTh(bill.service).toLowerCase();
        final amount = bill.amount.toString();
        final status = _getStatusText(bill).toLowerCase();
        final query = _searchQuery.toLowerCase();

        return houseNumber.contains(query) ||
            serviceName.contains(query) ||
            amount.contains(query) ||
            status.contains(query);
      }).toList();
    }

    return filtered;
  }

  bool _isOverdue(BillModel bill) {
    if (bill.paidStatus == 1) return false;
    final now = DateTime.now();
    final due = bill.dueDate;
    return now.isAfter(DateTime(due.year, due.month, due.day, 23, 59, 59));
  }

  Color _getStatusColor(BillModel bill) {
    // ตรวจสอบสถานะหลักก่อน
    if (bill.paidStatus == 1 || bill.status.toUpperCase() == 'RECEIPT_SENT') {
      return ThemeColors.sageGreen; // ชำระเสร็จสิ้น
    }

    if (bill.status.toUpperCase() == 'UNDER_REVIEW') {
      return ThemeColors.caramel; // กำลังตรวจสอบ
    }

    if (bill.status.toUpperCase() == 'WAIT_RECEIPT') {
      return ThemeColors.infoBlue; // รอส่งใบเสร็จ
    }

    // ยังไม่ชำระ - ใช้สีต่างๆ ตามสถานะย่อย
    if (_isOverdue(bill) || bill.status.toUpperCase() == 'OVERDUE') {
      return ThemeColors.errorRust; // เกินกำหนด
    }

    if (bill.status.toUpperCase() == 'REJECTED') {
      return ThemeColors.terracottaRed; // ถูกปฏิเสธ -> ยังไม่ได้ชำระ
    }

    return ThemeColors.rustOrange; // ยังไม่ชำระทั่วไป
  }

  IconData _getStatusIcon(BillModel bill) {
    if (bill.paidStatus == 1 || bill.status.toUpperCase() == 'RECEIPT_SENT') {
      return Icons.check_circle_rounded;
    }

    switch (bill.status.toUpperCase()) {
      case 'PENDING':
        return Icons.schedule_rounded;
      case 'UNDER_REVIEW':
        return Icons.search_rounded;
      case 'WAIT_RECEIPT':
        return Icons.receipt_rounded;
      case 'REJECTED': // REJECTED แสดงเป็น pending เหมือน ยังไม่ได้ชำระ
        return Icons.pending_actions_rounded;
      case 'OVERDUE':
        return Icons.warning_amber_rounded;
      default:
        if (_isOverdue(bill)) return Icons.warning_amber_rounded;
        return Icons.schedule_rounded;
    }
  }

  String _getStatusText(BillModel bill) {
    // ตรวจสอบสถานะหลักก่อน
    if (bill.paidStatus == 1 || bill.status.toUpperCase() == 'RECEIPT_SENT') {
      return 'ชำระเสร็จสิ้น';
    }

    if (bill.status.toUpperCase() == 'UNDER_REVIEW') {
      return 'กำลังตรวจสอบ';
    }

    if (bill.status.toUpperCase() == 'WAIT_RECEIPT') {
      return 'รอส่งใบเสร็จ';
    }

    // สถานะอื่นๆ = ยังไม่ชำระ
    switch (bill.status.toUpperCase()) {
      case 'DRAFT':
        return 'ยังไม่ได้ชำระ';
      case 'PENDING':
        return 'ยังไม่ได้ชำระ';
      case 'REJECTED': // REJECTED แสดงเป็น ยังไม่ได้ชำระ
        return 'ยังไม่ได้ชำระ';
      case 'OVERDUE':
        return 'ยังไม่ได้ชำระ (เกิน)';
      default:
        if (_isOverdue(bill)) return 'ยังไม่ได้ชำระ (เกิน)';
        return 'ยังไม่ได้ชำระ';
    }
  }

  // คำนวณสถิติแบบ real-time
  Map<String, int> _calculateStats() {
    int pending = 0;
    int inProgress = 0;
    int waitingReceipt = 0;
    int resolved = 0;

    for (var bill in _bills) {
      if (bill.paidStatus == 1 || bill.status.toUpperCase() == 'RECEIPT_SENT') {
        resolved++;
      } else if (bill.status.toUpperCase() == 'UNDER_REVIEW') {
        inProgress++;
      } else if (bill.status.toUpperCase() == 'WAIT_RECEIPT') {
        waitingReceipt++;
      } else {
        pending++; // รวม PENDING, REJECTED, OVERDUE, DRAFT
      }
    }

    return {
      'total': _bills.length,
      'pending': pending,
      'in_progress': inProgress,
      'waiting_receipt': waitingReceipt,
      'resolved': resolved,
    };
  }

  List<TextSpan> _highlightSearchText(
    String text,
    String query,
    TextStyle baseStyle,
  ) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            backgroundColor: ThemeColors.goldenHoney.withOpacity(0.3),
            fontWeight: FontWeight.bold,
            color: ThemeColors.deepMahogany,
          ),
        ),
      );

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return spans;
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
    String filterType,
  ) {
    final isSelected = filterStatus == filterType;

    return GestureDetector(
      onTap: () {
        setState(() {
          filterStatus = filterStatus == filterType ? null : filterType;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [color.withOpacity(0.2), color.withOpacity(0.1)]
                : [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.3 : 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: ThemeColors.dustyBrown,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'กำลังกรอง',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _bills.isEmpty) {
      return Scaffold(
        backgroundColor: ThemeColors.creamWhite,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: ThemeColors.deepMahogany,
          foregroundColor: Colors.white,
          title: Text(
            'จัดการค่าส่วนกลาง',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.dustyBrown.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ThemeColors.deepMahogany,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'กำลังโหลดข้อมูล...',
                  style: TextStyle(
                    color: ThemeColors.deepMahogany,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final stats = _calculateStats();
    final filteredBills = _filterBills(_bills);

    return Scaffold(
      backgroundColor: ThemeColors.creamWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ThemeColors.deepMahogany,
        foregroundColor: Colors.white,
        title: Text(
          'จัดการค่าส่วนกลาง',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _refreshBills,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _bills.isEmpty && !_isLoading
          ? FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ThemeColors.dustyBrown.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ThemeColors.rustOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: ThemeColors.rustOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่มีข้อมูลค่าส่วนกลาง',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.deepMahogany,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'เริ่มต้นด้วยการเพิ่มบิลใหม่',
                        style: TextStyle(
                          color: ThemeColors.dustyBrown,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _navigateToAddForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeColors.rustOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'เพิ่มบิลแรก',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshBills,
              color: ThemeColors.deepMahogany,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // สถิติโดยรวม - Clickable Cards
                      Container(
                        margin: const EdgeInsets.all(16.0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ThemeColors.dustyBrown.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'ทั้งหมด',
                                '${stats['total']}',
                                Icons.receipt_long_rounded,
                                ThemeColors.deepMahogany,
                                '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'ยังไม่ชำระ',
                                '${stats['pending']}',
                                Icons.pending_actions_rounded,
                                ThemeColors.rustOrange,
                                'UNPAID',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'กำลังตรวจสอบ',
                                '${stats['in_progress']}',
                                Icons.search_rounded,
                                ThemeColors.caramel,
                                'UNDER_REVIEW',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'รอส่งใบเสร็จ',
                                '${stats['waiting_receipt']}',
                                Icons.receipt_rounded,
                                ThemeColors.infoBlue,
                                'WAIT_RECEIPT',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'ชำระเสร็จสิ้น',
                                '${stats['resolved']}',
                                Icons.check_circle_rounded,
                                ThemeColors.sageGreen,
                                'RECEIPT_SENT',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ช่องค้นหาและ Clear Filter
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            // ช่องค้นหา
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: ThemeColors.dustyBrown.withOpacity(
                                      0.2,
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'ค้นหาบ้านเลขที่, ประเภทบริการ, จำนวนเงิน...',
                                    hintStyle: TextStyle(
                                      color: ThemeColors.dustyBrown.withOpacity(
                                        0.6,
                                      ),
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: ThemeColors.deepMahogany,
                                      size: 20,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear_rounded,
                                              color: ThemeColors.dustyBrown,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: ThemeColors.deepMahogany,
                                    fontSize: 14,
                                  ),
                                  onChanged: (value) {
                                    setState(() => _searchQuery = value);
                                  },
                                ),
                              ),
                            ),

                            // Clear Filter และ Result Count
                            if (filterStatus != null) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => filterStatus = null),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: ThemeColors.terracottaRed
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.clear_rounded,
                                        color: ThemeColors.terracottaRed,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ล้างตัวกรอง',
                                        style: TextStyle(
                                          color: ThemeColors.terracottaRed,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Result Count
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ThemeColors.goldenHoney.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                '${filteredBills.length} รายการ',
                                style: TextStyle(
                                  color: ThemeColors.deepMahogany,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // รายการบิล
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: filteredBills.length,
                          itemBuilder: (context, index) {
                            final bill = filteredBills[index];
                            final houseNumber =
                                houseMap[bill.houseId] ?? '${bill.houseId}';

                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 300 + (index * 50),
                              ),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, animationValue, child) {
                                return Transform.translate(
                                  offset: Offset(0, 10 * (1 - animationValue)),
                                  child: Opacity(
                                    opacity: animationValue,
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _getStatusColor(
                                            bill,
                                          ).withOpacity(0.2),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: ThemeColors.dustyBrown
                                                .withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          onTap: () => _navigateToDetail(bill),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                // Status Icon
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      bill,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: _getStatusColor(
                                                        bill,
                                                      ).withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    _getStatusIcon(bill),
                                                    color: _getStatusColor(
                                                      bill,
                                                    ),
                                                    size: 20,
                                                  ),
                                                ),

                                                const SizedBox(width: 16),

                                                // Bill Info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // House Number & Status
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: RichText(
                                                              text: TextSpan(
                                                                children: _highlightSearchText(
                                                                  'บ้านเลขที่ $houseNumber',
                                                                  _searchQuery,
                                                                  TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: ThemeColors
                                                                        .deepMahogany,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                // ตั้งค่า filter ตามสถานะที่กด
                                                                if (bill.paidStatus ==
                                                                        1 ||
                                                                    bill.status
                                                                            .toUpperCase() ==
                                                                        'RECEIPT_SENT') {
                                                                  filterStatus =
                                                                      'RECEIPT_SENT';
                                                                } else if (bill
                                                                        .status
                                                                        .toUpperCase() ==
                                                                    'UNDER_REVIEW') {
                                                                  filterStatus =
                                                                      'UNDER_REVIEW';
                                                                } else if (bill
                                                                        .status
                                                                        .toUpperCase() ==
                                                                    'WAIT_RECEIPT') {
                                                                  filterStatus =
                                                                      'WAIT_RECEIPT';
                                                                } else {
                                                                  filterStatus =
                                                                      'UNPAID';
                                                                }
                                                              });
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    _getStatusColor(
                                                                      bill,
                                                                    ).withOpacity(
                                                                      0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                border: Border.all(
                                                                  color:
                                                                      _getStatusColor(
                                                                        bill,
                                                                      ).withOpacity(
                                                                        0.3,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    _getStatusText(
                                                                      bill,
                                                                    ),
                                                                    style: TextStyle(
                                                                      color:
                                                                          _getStatusColor(
                                                                            bill,
                                                                          ),
                                                                      fontSize:
                                                                          11,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Icon(
                                                                    Icons
                                                                        .filter_alt_rounded,
                                                                    size: 12,
                                                                    color:
                                                                        _getStatusColor(
                                                                          bill,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      const SizedBox(height: 8),

                                                      // Service & Amount
                                                      RichText(
                                                        text: TextSpan(
                                                          children: _highlightSearchText(
                                                            '${_getServiceNameTh(bill.service)} • ฿${formatCurrency(bill.amount)}',
                                                            _searchQuery,
                                                            TextStyle(
                                                              color: ThemeColors
                                                                  .dustyBrown,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      const SizedBox(height: 6),

                                                      // Due Date
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .calendar_today_rounded,
                                                            size: 14,
                                                            color: ThemeColors
                                                                .infoBlue,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            'ครบกำหนด: ${formatDate(bill.dueDate)}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: ThemeColors
                                                                  .dustyBrown,
                                                            ),
                                                          ),
                                                          if (_isOverdue(
                                                            bill,
                                                          )) ...[
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical: 2,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: ThemeColors
                                                                    .errorRust
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      6,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                'เกิน ${DateTime.now().difference(bill.dueDate).inDays} วัน',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: ThemeColors
                                                                      .errorRust,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(width: 12),

                                                // Action Arrow
                                                Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  color: ThemeColors.dustyBrown,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // Spacing for FAB
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddForm,
        backgroundColor: ThemeColors.rustOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'เพิ่มค่าส่วนกลาง',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
