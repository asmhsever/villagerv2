import 'package:flutter/material.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/bill/bill_add_page.dart';
import 'package:fullproject/pages/law/bill/bill_detail_page.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:intl/intl.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  List<BillModel> _bills = [];
  LawModel? law;
  Map<int, String> houseMap = {};
  Map<int, String> serviceMap = {};
  String? filterStatus; // เปลี่ยนจาก int เป็น String เพื่อให้ตรงกับ BillModel.status
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 🎨 Warm Natural Color Scheme
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);
  static const Color softBorder = Color(0xFFD0C4B0);
  static const Color inputFill = Color(0xFFFBF9F3);
  static const Color softTerracotta = Color(0xFFD48B5C);
  static const Color clayOrange = Color(0xFFCC7748);
  static const Color neutralText = earthClay;
  static const Color primaryBorder = softBorder;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user is LawModel) {
        setState(() => law = user);
        await _loadHouseAndServiceData();
        await _loadBills();
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
        // ใช้ Future.wait เพื่อโหลดข้อมูลพร้อมกัน
        final results = await Future.wait([
          SupabaseConfig.client
              .from('house')
              .select('house_id, house_number')
              .eq('village_id', law!.villageId),
          SupabaseConfig.client
              .from('service')
              .select('service_id, name'),
        ]);

        final houseResponse = results[0];
        final serviceResponse = results[1];

        final Map<int, String> newHouseMap = {};
        for (var house in houseResponse) {
          newHouseMap[house['house_id'] as int] =
              (house['house_number'] ?? '').toString();
        }

        final Map<int, String> newServiceMap = {};
        for (var service in serviceResponse) {
          newServiceMap[service['service_id'] as int] =
              (service['name'] ?? '').toString();
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
          content: Text(message),
          backgroundColor: clayOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
    await _loadHouseAndServiceData();
    await _loadBills();
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
      if (filterStatus == 'unpaid') {
        filtered = filtered.where((b) => b.paidStatus == 0).toList();
      } else if (filterStatus == 'paid') {
        filtered = filtered.where((b) => b.paidStatus == 1).toList();
      } else {
        // กรองตาม BillModel.status
        filtered = filtered.where((b) => b.status == filterStatus).toList();
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
    return DateTime.now().isAfter(bill.dueDate);
  }

  Color _getStatusColor(BillModel bill) {
    switch (bill.status.toUpperCase()) {
      case 'RECEIPT_SENT':
        return oliveGreen;
      case 'PENDING':
        return softTerracotta;
      case 'UNDER_REVIEW':
        return softBrown;
      case 'REJECTED':
        return clayOrange;
      case 'OVERDUE':
        return clayOrange;
      default:
        if (bill.paidStatus == 1) return oliveGreen;
        if (_isOverdue(bill)) return clayOrange;
        return softTerracotta;
    }
  }

  IconData _getStatusIcon(BillModel bill) {
    switch (bill.status.toUpperCase()) {
      case 'RECEIPT_SENT':
        return Icons.check_circle;
      case 'PENDING':
        return Icons.schedule;
      case 'UNDER_REVIEW':
        return Icons.visibility;
      case 'REJECTED':
        return Icons.cancel;
      case 'OVERDUE':
        return Icons.warning;
      default:
        if (bill.paidStatus == 1) return Icons.check_circle;
        if (_isOverdue(bill)) return Icons.warning;
        return Icons.schedule;
    }
  }

  String _getStatusText(BillModel bill) {
    switch (bill.status.toUpperCase()) {
      case 'DRAFT':
        return 'แบบร่าง';
      case 'PENDING':
        return 'รอชำระ';
      case 'UNDER_REVIEW':
        return 'กำลังตรวจสอบ';
      case 'RECEIPT_SENT':
        return 'ส่งใบเสร็จแล้ว';
      case 'REJECTED':
        return 'ถูกปฏิเสธ';
      case 'OVERDUE':
        return 'เกินกำหนด';
      default:
        if (bill.paidStatus == 1) return 'ชำระแล้ว';
        if (_isOverdue(bill)) return 'เกินกำหนด';
        return 'ยังไม่ชำระ';
    }
  }

  // คำนวณสถิติแบบ real-time
  Map<String, int> _calculateStats() {
    return {
      'total': _bills.length,
      'unpaid': _bills.where((b) => b.paidStatus == 0).length,
      'paid': _bills.where((b) => b.paidStatus == 1).length,
      'pending': _bills.where((b) => b.status.toUpperCase() == 'PENDING').length,
      'under_review': _bills.where((b) => b.status.toUpperCase() == 'UNDER_REVIEW').length,
      'overdue': _bills.where((b) => _isOverdue(b)).length,
    };
  }

  List<TextSpan> _highlightSearchText(
      String text, String query, TextStyle baseStyle) {
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
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: baseStyle,
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: baseStyle.copyWith(
          backgroundColor: softBrown.withValues(alpha: 0.15),
          fontWeight: FontWeight.bold,
          color: softBrown,
        ),
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return spans;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sandyTan,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: neutralText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ivoryWhite,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: softBrown,
          foregroundColor: Colors.white,
          title: const Text(
            'จัดการค่าส่วนกลาง',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(softBrown),
          ),
        ),
      );
    }

    final stats = _calculateStats();
    final filteredBills = _filterBills(_bills);

    return Scaffold(
      backgroundColor: ivoryWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: softBrown,
        foregroundColor: Colors.white,
        title: const Text(
          'จัดการค่าส่วนกลาง',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isLoading ? null : _refreshBills,
              tooltip: 'รีเฟรช',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _bills.isEmpty && !_isLoading
          ? Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: sandyTan,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: softBrown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 64,
                  color: softBrown,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ไม่มีข้อมูลค่าส่วนกลาง',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'เริ่มต้นด้วยการเพิ่มบิลใหม่',
                style: TextStyle(
                  color: neutralText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToAddForm,
                icon: const Icon(Icons.add_rounded),
                label: const Text('เพิ่มบิลแรก'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: burntOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshBills,
        color: softBrown,
        child: Column(
          children: [
            // สถิติโดยรวม
            Container(
              margin: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'ทั้งหมด',
                      '${stats['total']}',
                      Icons.receipt_long_rounded,
                      softBrown,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'ยังไม่จ่าย',
                      '${stats['unpaid']}',
                      Icons.schedule_rounded,
                      softTerracotta,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'จ่ายแล้ว',
                      '${stats['paid']}',
                      Icons.check_circle_rounded,
                      oliveGreen,
                    ),
                  ),
                ],
              ),
            ),

            // ช่องค้นหาและตัวกรอง
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // ช่องค้นหา
                  Container(
                    decoration: BoxDecoration(
                      color: sandyTan,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryBorder),
                      boxShadow: [
                        BoxShadow(
                          color: earthClay.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                        'ค้นหาบ้านเลขที่, ประเภทบริการ, จำนวนเงิน, หรือสถานะ...',
                        hintStyle: const TextStyle(color: neutralText),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: softBrown,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: neutralText),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: inputFill,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ตัวกรองสถานะ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sandyTan,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_alt_rounded,
                          color: softBrown,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'กรองสถานะ:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: neutralText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: inputFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryBorder),
                            ),
                            child: DropdownButton<String?>(
                              value: filterStatus,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('ทั้งหมด'),
                                ),
                                DropdownMenuItem(
                                  value: 'unpaid',
                                  child: Text('ยังไม่ชำระ'),
                                ),
                                DropdownMenuItem(
                                  value: 'paid',
                                  child: Text('ชำระแล้ว'),
                                ),
                                DropdownMenuItem(
                                  value: 'PENDING',
                                  child: Text('รอชำระ'),
                                ),
                                DropdownMenuItem(
                                  value: 'UNDER_REVIEW',
                                  child: Text('กำลังตรวจสอบ'),
                                ),
                                DropdownMenuItem(
                                  value: 'RECEIPT_SENT',
                                  child: Text('ส่งใบเสร็จแล้ว'),
                                ),
                                DropdownMenuItem(
                                  value: 'REJECTED',
                                  child: Text('ถูกปฏิเสธ'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => filterStatus = value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: softBrown.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'แสดง ${filteredBills.length} รายการ',
                            style: const TextStyle(
                              color: softBrown,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: sandyTan,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryBorder),
                      boxShadow: [
                        BoxShadow(
                          color: earthClay.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(bill)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatusIcon(bill),
                          color: _getStatusColor(bill),
                          size: 24,
                        ),
                      ),
                      title: RichText(
                        text: TextSpan(
                          children: _highlightSearchText(
                            'บ้านเลขที่ $houseNumber',
                            _searchQuery,
                            const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: _highlightSearchText(
                                '${_getServiceNameTh(bill.service)} - ฿${formatCurrency(bill.amount)}',
                                _searchQuery,
                                const TextStyle(
                                  color: neutralText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: softBrown,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ครบกำหนด: ${formatDate(bill.dueDate)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: neutralText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(bill)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(bill)
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(bill),
                          style: TextStyle(
                            color: _getStatusColor(bill),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: () => _navigateToDetail(bill),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: burntOrange.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _navigateToAddForm,
          backgroundColor: burntOrange,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'เพิ่มค่าส่วนกลาง',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}