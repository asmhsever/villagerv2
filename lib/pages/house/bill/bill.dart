import 'package:flutter/material.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/pages/house/bill/bill_detail.dart';

class HouseBillPage extends StatefulWidget {
  final int houseId;

  const HouseBillPage({super.key, required this.houseId});

  @override
  State<HouseBillPage> createState() => _HouseBillPageState();
}

class _HouseBillPageState extends State<HouseBillPage> {
  late Future<List<BillModel>> _billsFuture;
  late Future<Map<String, dynamic>> _statsFuture;

  String _currentFilter = 'all'; // all, paid, unpaid
  String _currentStatus =
      'all'; // all, DRAFT, PENDING, UNDER_REVIEW, REJECTED, RECEIPT_SENT, OVERDUE

  final List<Map<String, String>> _filterOptions = [
    {'value': 'all', 'label': 'ทั้งหมด'},
    {'value': 'unpaid', 'label': 'ยังไม่จ่าย'},
    {'value': 'paid', 'label': 'จ่ายแล้ว'},
  ];

  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'ทุกสถานะ'},
    {'value': 'PENDING', 'label': 'รอชำระ'},
    {'value': 'UNDER_REVIEW', 'label': 'กำลังตรวจสอบ'},
    {'value': 'REJECTED', 'label': 'สลิปไม่ผ่าน'},
    {'value': 'RECEIPT_SENT', 'label': 'เสร็จสิ้น'},
    {'value': 'OVERDUE', 'label': 'เลยกำหนด'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _loadBills();
    _loadStats();
  }

  void _loadBills() {
    if (_currentStatus != 'all') {
      _billsFuture = BillDomain.getByStatusInHouse(
        widget.houseId,
        _currentStatus,
      );
    } else {
      switch (_currentFilter) {
        case 'unpaid':
          _billsFuture = BillDomain.getUnpaidByHouse(houseId: widget.houseId);
          break;
        case 'paid':
          _billsFuture = BillDomain.getPaidByHouse(houseId: widget.houseId);
          break;
        default:
          _billsFuture = BillDomain.getAllInHouse(houseId: widget.houseId);
      }
    }
  }

  void _loadStats() {
    _statsFuture = BillDomain.getHousePaymentStats(widget.houseId);
  }

  Future<Map<String, dynamic>> _loaddata() async {
    try {
      final bills = await BillDomain.getHousePaymentStats(widget.houseId);
      final total_unpaid = await BillDomain.calUnpaidByHouse(
        houseId: widget.houseId,
      );
      return {"total_unpaid": total_unpaid, "bills": bills};
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  void _changeFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      if (filter != 'all') {
        _currentStatus = 'all'; // Reset status when changing filter
      }
      _loadBills();
    });
  }

  void _changeStatus(String status) {
    setState(() {
      _currentStatus = status;
      if (status != 'all') {
        _currentFilter = 'all'; // Reset filter when changing status
      }
      _loadBills();
    });
  }

  // เพิ่มฟังก์ชันสำหรับกรองบิลที่ยังไม่จ่าย
  void _filterUnpaidBills() {
    setState(() {
      _currentFilter = 'unpaid';
      _currentStatus = 'all';
      _loadBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF6), // Ivory White
      body: RefreshIndicator(
        color: const Color(0xFFA47551), // Soft Brown
        onRefresh: () async => _refreshData(),
        child: Column(
          children: [
            // Stats Card with Pending Amount
            _buildEnhancedStatsCard(),

            // Filter Controls
            _buildEnhancedFilterControls(),

            // Bills List
            Expanded(
              child: FutureBuilder<List<BillModel>>(
                future: _billsFuture,
                builder: (context, snapshot) {
                  // Loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFFA47551), // Soft Brown
                          ),
                          SizedBox(height: 16),
                          Text('กำลังโหลดข้อมูลบิล...'),
                        ],
                      ),
                    );
                  }

                  // Error state
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Color(0xFFD48B5C), // Soft Terracotta
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'เกิดข้อผิดพลาด: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE08E45),
                              // Burnt Orange
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _refreshData,
                            child: const Text('ลองอีกครั้ง'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Empty state
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Color(0xFFC7B9A5), // Warm Stone
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyMessage(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  // Success state with data
                  final bills = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      return BillCard(
                        bill: bill,
                        onTap: () => _navigateToBillDetail(bill),
                        onPaymentUpdate: _refreshData,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatsCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      color: const Color(0xFFF5F0E1),
      // Beige
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loaddata(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFFA47551), // Soft Brown
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('ไม่สามารถโหลดสถิติได้');
            }

            final data = snapshot.data!;
            final stats = data['bills'];
            final pendingAmount = data['total_unpaid'];
            final totalBills = stats['total_bills'] ?? 0;
            final completedBills = stats['completed_bills'] ?? 0;
            final pendingBills = stats['pending_bills'] ?? 0;
            final rejectedBills = stats['rejected_bills'] ?? 0;
            final underReviewBills = stats['under_review_bills'] ?? 0;
            final overdueBills = stats['overdue_bills'] ?? 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'สรุปข้อมูลบิล',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFA47551), // Soft Brown
                      ),
                    ),
                    // ปุ่มบิลที่ยังไม่จ่าย
                    ElevatedButton.icon(
                      onPressed: _filterUnpaidBills,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE08E45),
                        // Burnt Orange
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text(
                        'บิลยังไม่จ่าย',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ยอดเงินค้างชำระ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE08E45).withOpacity(0.1),
                        // Burnt Orange
                        const Color(0xFFD48B5C).withOpacity(0.1),
                        // Soft Terracotta
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE08E45).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: const Color(0xFFE08E45),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ยอดเงินค้างชำระ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE08E45),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '฿${pendingAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFCC7748), // Clay Orange
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'จาก ${pendingBills + rejectedBills + overdueBills} ใบ',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFFBFA18F), // Earth Clay
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // สถิติแยกตามประเภท
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'ทั้งหมด',
                        totalBills.toString(),
                        const Color(0xFFA47551), // Soft Brown
                        Icons.receipt_long,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'เสร็จสิ้น',
                        completedBills.toString(),
                        const Color(0xFFA3B18A), // Olive Green
                        Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'รอชำระ',
                        pendingBills.toString(),
                        const Color(0xFFE08E45), // Burnt Orange
                        Icons.pending,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'ตรวจสอบ',
                        underReviewBills.toString(),
                        const Color(0xFFC7B9A5), // Warm Stone
                        Icons.search,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'ไม่ผ่าน',
                        rejectedBills.toString(),
                        const Color(0xFFD48B5C), // Soft Terracotta
                        Icons.cancel,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFFBFA18F), // Earth Clay
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFilterControls() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFFBF9F3),
      // Input Fill
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  color: const Color(0xFFA47551), // Soft Brown
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'กรองข้อมูล',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA47551), // Soft Brown
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สถานะการจ่าย',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFBFA18F), // Earth Clay
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentStatus == 'all'
                                ? const Color(0xFFD0C4B0) // Soft Border
                                : const Color(0xFFDCDCDC), // Disabled Grey
                          ),
                          color: _currentStatus == 'all'
                              ? Colors.white
                              : const Color(0xFFDCDCDC).withOpacity(0.3),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _currentFilter,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                          dropdownColor: const Color(0xFFFBF9F3),
                          // Input Fill
                          style: TextStyle(
                            color: _currentStatus == 'all'
                                ? const Color(0xFFA47551) // Soft Brown
                                : const Color(0xFFBFA18F), // Earth Clay
                            fontWeight: FontWeight.w500,
                          ),
                          items: _filterOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option['value'],
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getFilterColor(option['value']!),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(option['label']!),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _currentStatus == 'all'
                              ? (value) {
                                  if (value != null) _changeFilter(value);
                                }
                              : null,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _currentStatus == 'all'
                                ? const Color(0xFFA47551) // Soft Brown
                                : const Color(0xFFBFA18F), // Earth Clay
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สถานะบิล',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFBFA18F), // Earth Clay
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentFilter == 'all'
                                ? const Color(0xFFD0C4B0) // Soft Border
                                : const Color(0xFFDCDCDC), // Disabled Grey
                          ),
                          color: _currentFilter == 'all'
                              ? Colors.white
                              : const Color(0xFFDCDCDC).withOpacity(0.3),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _currentStatus,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                          dropdownColor: const Color(0xFFFBF9F3),
                          // Input Fill
                          style: TextStyle(
                            color: _currentFilter == 'all'
                                ? const Color(0xFFA47551) // Soft Brown
                                : const Color(0xFFBFA18F), // Earth Clay
                            fontWeight: FontWeight.w500,
                          ),
                          items: _statusOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option['value'],
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(option['value']!),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(option['label']!),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _currentFilter == 'all'
                              ? (value) {
                                  if (value != null) _changeStatus(value);
                                }
                              : null,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _currentFilter == 'all'
                                ? const Color(0xFFA47551) // Soft Brown
                                : const Color(0xFFBFA18F), // Earth Clay
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
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'unpaid':
        return const Color(0xFFE08E45); // Burnt Orange
      case 'paid':
        return const Color(0xFFA3B18A); // Olive Green
      default:
        return const Color(0xFFA47551); // Soft Brown
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFE08E45); // Burnt Orange
      case 'UNDER_REVIEW':
        return const Color(0xFFC7B9A5); // Warm Stone
      case 'REJECTED':
        return const Color(0xFFD48B5C); // Soft Terracotta
      case 'RECEIPT_SENT':
        return const Color(0xFFA3B18A); // Olive Green
      case 'OVERDUE':
        return const Color(0xFFCC7748); // Clay Orange
      default:
        return const Color(0xFFA47551); // Soft Brown
    }
  }

  String _getEmptyMessage() {
    if (_currentStatus != 'all') {
      return 'ไม่มีบิลสถานะ ${_statusOptions.firstWhere((e) => e['value'] == _currentStatus)['label']}';
    }

    switch (_currentFilter) {
      case 'unpaid':
        return 'ไม่มีบิลที่ยังไม่จ่าย';
      case 'paid':
        return 'ไม่มีบิลที่จ่ายแล้ว';
      default:
        return 'ไม่มีข้อมูลบิล';
    }
  }

  void _navigateToBillDetail(BillModel bill) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BillDetailScreen(bill: bill)),
    ).then((_) => _refreshData()); // Refresh เมื่อกลับมา
  }
}

// Widget สำหรับแสดงข้อมูลบิลแต่ละรายการ (ปรับปรุงแล้ว)
class BillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onTap;
  final VoidCallback? onPaymentUpdate;

  const BillCard({
    Key? key,
    required this.bill,
    this.onTap,
    this.onPaymentUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFFBF9F3),
      // Input Fill
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_getStatusColor(), _getStatusColor().withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor().withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(_getStatusIcon(), color: Colors.white, size: 24),
        ),
        title: Text(
          'บิลเลขที่ ${bill.billId}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFFA47551), // Soft Brown
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: const Color(0xFFBFA18F), // Earth Clay
                ),
                const SizedBox(width: 4),
                Text(
                  'จำนวนเงิน: ฿${bill.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: const Color(0xFFBFA18F), // Earth Clay
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: const Color(0xFFBFA18F), // Earth Clay
                ),
                const SizedBox(width: 4),
                Text(
                  'วันครบกำหนด: ${_formatDate(bill.dueDate)}',
                  style: TextStyle(
                    color: const Color(0xFFBFA18F), // Earth Clay
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor().withOpacity(0.15),
                    _getStatusColor().withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: _buildTrailingWidget(context),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTrailingWidget(BuildContext context) {
    if (bill.status == 'PENDING' && bill.paidStatus == 0) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE08E45), // Burnt Orange
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE08E45).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.payment, color: Colors.white),
          onPressed: () => _showPaymentDialog(context),
        ),
      );
    } else if (bill.status == 'RECEIPT_SENT') {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFA3B18A), // Olive Green
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.check_circle, color: Colors.white, size: 24),
        ),
      );
    } else if (bill.status == 'REJECTED') {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD48B5C), // Soft Terracotta
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD48B5C).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: onTap,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
        ),
      );
    }
  }

  Color _getStatusColor() {
    switch (bill.status) {
      case 'PENDING':
        return const Color(0xFFE08E45); // Burnt Orange
      case 'UNDER_REVIEW':
        return const Color(0xFFC7B9A5); // Warm Stone
      case 'REJECTED':
        return const Color(0xFFD48B5C); // Soft Terracotta
      case 'RECEIPT_SENT':
        return const Color(0xFFA3B18A); // Olive Green
      case 'OVERDUE':
        return const Color(0xFFCC7748); // Clay Orange
      default:
        return bill.paidStatus == 1
            ? const Color(0xFFA3B18A) // Olive Green
            : const Color(0xFFE08E45); // Burnt Orange
    }
  }

  IconData _getStatusIcon() {
    switch (bill.status) {
      case 'PENDING':
        return Icons.pending_actions;
      case 'UNDER_REVIEW':
        return Icons.search;
      case 'REJECTED':
        return Icons.error_outline;
      case 'RECEIPT_SENT':
        return Icons.check_circle;
      case 'OVERDUE':
        return Icons.warning_amber;
      default:
        return bill.paidStatus == 1
            ? Icons.check_circle
            : Icons.pending_actions;
    }
  }

  String _getStatusText() {
    switch (bill.status) {
      case 'PENDING':
        return 'รอชำระ';
      case 'UNDER_REVIEW':
        return 'กำลังตรวจสอบ';
      case 'REJECTED':
        return 'สลิปไม่ผ่าน';
      case 'RECEIPT_SENT':
        return 'เสร็จสิ้น';
      case 'OVERDUE':
        return 'เลยกำหนด';
      default:
        return bill.paidStatus == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFBF9F3),
        // Input Fill
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE08E45).withOpacity(0.2),
                // Burnt Orange
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.payment,
                color: Color(0xFFE08E45),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'ยืนยันการชำระเงิน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA47551), // Soft Brown
                ),
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0E1), // Beige
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD0C4B0), // Soft Border
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: Color(0xFFA47551), // Soft Brown
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'บิลเลขที่: ${bill.billId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA47551), // Soft Brown
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFFE08E45), // Burnt Orange
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'จำนวนเงิน: ฿${bill.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFE08E45), // Burnt Orange
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7B9A5).withOpacity(0.2),
                  // Warm Stone
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFC7B9A5), // Warm Stone
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'หลังจากยืนยันการชำระ บิลจะถูกส่งไปตรวจสอบ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFBFA18F), // Earth Clay
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFBFA18F), // Earth Clay
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _markAsPaid(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE08E45),
              // Burnt Orange
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 18),
                SizedBox(width: 6),
                Text(
                  'ยืนยันชำระ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _markAsPaid(BuildContext context) async {
    // แสดง Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFBF9F3), // Input Fill
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFE08E45), // Burnt Orange
              ),
              SizedBox(width: 20),
              Text(
                'กำลังประมวลผล...',
                style: TextStyle(
                  color: Color(0xFFA47551), // Soft Brown
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await BillDomain.updatePaymentStatus(
        billId: bill.billId,
        paidStatus: 1,
        status: 'UNDER_REVIEW',
        // เปลี่ยนสถานะเป็นรอตรวจสอบ
        paidDate: DateTime.now().toIso8601String().split('T')[0],
        paidMethod: 'manual',
      );

      Navigator.pop(context); // ปิด Loading Dialog

      if (success) {
        // แสดง Success Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFFFBF9F3),
            // Input Fill
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA3B18A).withOpacity(0.2),
                    // Olive Green
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFFA3B18A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'สำเร็จ!',
                    style: TextStyle(
                      color: Color(0xFFA3B18A), // Olive Green
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'ส่งการชำระเงินแล้ว กำลังรอการตรวจสอบ',
              style: TextStyle(
                color: Color(0xFFBFA18F), // Earth Clay
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA3B18A), // Olive Green
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('รับทราบ'),
              ),
            ],
          ),
        );
        onPaymentUpdate?.call();
      } else {
        // แสดง Error Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFFFBF9F3),
            // Input Fill
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD48B5C).withOpacity(0.2),
                    // Soft Terracotta
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFD48B5C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      color: Color(0xFFD48B5C), // Soft Terracotta
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'ไม่สามารถชำระเงินได้ กรุณาลองใหม่อีกครั้ง',
              style: TextStyle(
                color: Color(0xFFBFA18F), // Earth Clay
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD48B5C),
                  // Soft Terracotta
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // ปิด Loading Dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFBF9F3),
          // Input Fill
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'เกิดข้อผิดพลาด',
            style: TextStyle(
              color: Color(0xFFD48B5C), // Soft Terracotta
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'เกิดข้อผิดพลาด: $e',
            style: const TextStyle(
              color: Color(0xFFBFA18F), // Earth Clay
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD48B5C), // Soft Terracotta
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    }
  }
}
