import 'package:flutter/material.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/pages/house/bill/bill_detail.dart';
import 'package:fullproject/pages/house/widgets/appbar.dart';
import 'package:fullproject/theme/Color.dart';

class HouseBillPage extends StatefulWidget {
  final HouseModel houseData;

  const HouseBillPage({super.key, required this.houseData});

  @override
  State<HouseBillPage> createState() => _HouseBillPageState();
}

class _HouseBillPageState extends State<HouseBillPage> {
  late Future<List<BillModel>> _billsFuture;
  late Future<Map<String, dynamic>> _statsFuture;

  String _currentFilter = 'all'; // all, paid, unpaid, under_review

  final List<Map<String, String>> _filterOptions = [
    {'value': 'all', 'label': 'ทั้งหมด'},
    {'value': 'unpaid', 'label': 'ยังไม่จ่าย'},
    {'value': 'paid', 'label': 'จ่ายแล้ว'},
    {'value': 'under_review', 'label': 'กำลังตรวจสอบ'},
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
    switch (_currentFilter) {
      case 'unpaid':
        _billsFuture = BillDomain.getUnpaidByHouse(
          houseId: widget.houseData.houseId,
        );
        break;
      case 'paid':
        _billsFuture = BillDomain.getPaidByHouse(
          houseId: widget.houseData.houseId,
        );
        break;
      case 'under_review':
        _billsFuture = BillDomain.getByStatusInHouse(
          houseId: widget.houseData.houseId,
          status: "UNDER_REVIEW",
        );
        break;
      default:
        _billsFuture = BillDomain.getAllInHouse(
          houseId: widget.houseData.houseId,
        );
    }
  }

  void _loadStats() {
    _statsFuture = BillDomain.getHousePaymentStats(widget.houseData.houseId);
  }

  Future<Map<String, dynamic>> _loaddata() async {
    try {
      final bills = await BillDomain.getHousePaymentStats(
        widget.houseData.houseId,
      );
      final total_unpaid = await BillDomain.calUnpaidByHouse(
        houseId: widget.houseData.houseId,
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
      _loadBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HouseAppBar(house: widget.houseData?.houseNumber),
      backgroundColor: ThemeColors.ivoryWhite, // Ivory White
      body: RefreshIndicator(
        color: ThemeColors.softBrown, // Soft Brown
        onRefresh: () async => _refreshData(),
        child: Column(
          children: [
            // Simplified Stats Card
            _buildSimplifiedStatsCard(),

            // Simple Filter Controls
            _buildSimpleFilterControls(),

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
                            color: ThemeColors.softBrown, // Soft Brown
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
                            color:
                                ThemeColors.softTerracotta, // Soft Terracotta
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'เกิดข้อผิดพลาด: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeColors.burntOrange,
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
                            color: ThemeColors.warmStone, // Warm Stone
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

  Widget _buildSimplifiedStatsCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      color: ThemeColors.beige,
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
                    color: ThemeColors.softBrown, // Soft Brown
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
            final completedBills = stats['completed_bills'] ?? 0;
            final pendingBills = stats['pending_bills'] ?? 0;
            final rejectedBills = stats['rejected_bills'] ?? 0;
            final underReviewBills = stats['under_review_bills'] ?? 0;
            final overdueBills = stats['overdue_bills'] ?? 0;

            // รวมสถานะรอชำระและตรวจสอบ
            final waitingBills = pendingBills + underReviewBills;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   'สรุปข้อมูลบิล',
                //   style: TextStyle(
                //     fontSize: 20,
                //     fontWeight: FontWeight.bold,
                //     color: ThemeColors.softBrown, // Soft Brown
                //   ),
                // ),
                // const SizedBox(height: 16),

                // แถวยอดเงินและสถานะ
                Row(
                  children: [
                    // ยอดเงินค้างชำระ
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _changeFilter('unpaid'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ThemeColors.burntOrange.withOpacity(0.15),
                                ThemeColors.softTerracotta.withOpacity(0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ThemeColors.burntOrange.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: ThemeColors.burntOrange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ค้างชำระ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeColors.burntOrange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '฿${pendingAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.clayOrange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'คลิกดูรายละเอียด',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ThemeColors.earthClay,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // สถานะแยกออกมา
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSimpleStatItem(
                              'เสร็จสิ้น',
                              completedBills.toString(),
                              ThemeColors.oliveGreen, // Olive Green
                              Icons.check_circle,
                            ),
                          ),
                          Expanded(
                            child: _buildSimpleStatItem(
                              'รอดำเนินการ',
                              waitingBills.toString(),
                              ThemeColors.burntOrange, // Burnt Orange
                              Icons.pending,
                            ),
                          ),
                          Expanded(
                            child: _buildSimpleStatItem(
                              'ไม่ผ่าน',
                              rejectedBills.toString(),
                              ThemeColors.softTerracotta, // Soft Terracotta
                              Icons.cancel,
                            ),
                          ),
                        ],
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

  Widget _buildSimpleStatItem(
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: ThemeColors.earthClay, // Earth Clay
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFilterControls() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: ThemeColors.inputFill,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.filter_alt_outlined,
              color: ThemeColors.softBrown,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'กรองข้อมูล:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ThemeColors.softBrown,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ThemeColors.softBorder),
                  color: Colors.white,
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
                  dropdownColor: ThemeColors.inputFill,
                  style: TextStyle(
                    color: ThemeColors.softBrown,
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
                  onChanged: (value) {
                    if (value != null) _changeFilter(value);
                  },
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'unpaid':
        return ThemeColors.burntOrange; // Burnt Orange
      case 'paid':
        return ThemeColors.oliveGreen; // Olive Green
      case 'under_review':
        return ThemeColors.warmStone; // Warm Stone
      default:
        return ThemeColors.softBrown; // Soft Brown
    }
  }

  String _getEmptyMessage() {
    switch (_currentFilter) {
      case 'unpaid':
        return 'ไม่มีบิลที่ยังไม่จ่าย';
      case 'paid':
        return 'ไม่มีบิลที่จ่ายแล้ว';
      case 'under_review':
        return 'ไม่มีบิลที่กำลังตรวจสอบ';
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
      color: ThemeColors.inputFill,
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
            color: ThemeColors.softBrown,
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
                  color: ThemeColors.earthClay,
                ),
                const SizedBox(width: 4),
                Text(
                  'จำนวนเงิน: ฿${bill.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: ThemeColors.earthClay,
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
                  color: ThemeColors.earthClay,
                ),
                const SizedBox(width: 4),
                Text(
                  'วันครบกำหนด: ${_formatDate(bill.dueDate)}',
                  style: TextStyle(color: ThemeColors.earthClay),
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
                _getSimpleStatusText(),
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
          color: ThemeColors.burntOrange,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.burntOrange.withOpacity(0.3),
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
          color: ThemeColors.oliveGreen,
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
          color: ThemeColors.softTerracotta,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.softTerracotta.withOpacity(0.3),
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
      case 'UNDER_REVIEW':
        return ThemeColors.sandyTan; // Burnt Orange - รวมรอชำระและตรวจสอบ
      case 'REJECTED':
        return ThemeColors.softTerracotta; // Soft Terracotta
      case 'RECEIPT_SENT':
        return ThemeColors.oliveGreen; // Olive Green
      case 'OVERDUE':
        return ThemeColors.clayOrange; // Clay Orange
      default:
        return bill.paidStatus == 1
            ? ThemeColors.oliveGreen
            : ThemeColors.burntOrange;
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

  String _getSimpleStatusText() {
    switch (bill.status) {
      case 'PENDING':
        return 'รอชำระ';
      case 'UNDER_REVIEW':
        return 'กำลังตรวจสอบ';
      case 'REJECTED':
        return 'ไม่ผ่าน';
      case 'RECEIPT_SENT':
        return 'เสร็จสิ้น';
      case 'OVERDUE':
        return 'เลยกำหนด';
      default:
        return bill.paidStatus == 1 ? 'เสร็จสิ้น' : 'รอดำเนินการ';
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
        backgroundColor: ThemeColors.inputFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeColors.burntOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.payment,
                color: ThemeColors.burntOrange,
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
                  color: ThemeColors.softBrown,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeColors.beige,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ThemeColors.softBorder, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: ThemeColors.softBrown,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'บิลเลขที่: ${bill.billId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.softBrown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: ThemeColors.burntOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'จำนวนเงิน: ฿${bill.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ThemeColors.burntOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeColors.warmStone.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: ThemeColors.warmStone,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'หลังจากยืนยันการชำระ บิลจะถูกส่งไปตรวจสอบ',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeColors.earthClay,
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
              foregroundColor: ThemeColors.earthClay,
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
              backgroundColor: ThemeColors.burntOrange,
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
        backgroundColor: ThemeColors.inputFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ThemeColors.burntOrange),
              SizedBox(width: 20),
              Text(
                'กำลังประมวลผล...',
                style: TextStyle(
                  color: ThemeColors.softBrown,
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
        paidDate: DateTime.now().toIso8601String().split('T')[0],
        paidMethod: 'manual',
      );

      Navigator.pop(context); // ปิด Loading Dialog

      if (success) {
        // แสดง Success Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: ThemeColors.inputFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.oliveGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: ThemeColors.oliveGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'สำเร็จ!',
                    style: TextStyle(
                      color: ThemeColors.oliveGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'ส่งการชำระเงินแล้ว กำลังรอการตรวจสอบ',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.oliveGreen,
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
            backgroundColor: ThemeColors.inputFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.softTerracotta.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: ThemeColors.softTerracotta,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      color: ThemeColors.softTerracotta,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'ไม่สามารถชำระเงินได้ กรุณาลองใหม่อีกครั้ง',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.softTerracotta,
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
          backgroundColor: ThemeColors.inputFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'เกิดข้อผิดพลาด',
            style: TextStyle(
              color: ThemeColors.softTerracotta,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'เกิดข้อผิดพลาด: $e',
            style: const TextStyle(color: ThemeColors.earthClay),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.softTerracotta,
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
