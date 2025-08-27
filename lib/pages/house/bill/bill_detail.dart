import 'package:flutter/material.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/pages/house/bill/pay_bill.dart';
import 'package:fullproject/services/image_service.dart';

class BillDetailScreen extends StatefulWidget {
  final BillModel bill;

  const BillDetailScreen({Key? key, required this.bill}) : super(key: key);

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<BillModel?> _billFuture;
  late TabController _tabController;
  late List<Map<String, dynamic>> _imageTabs;

  @override
  void initState() {
    super.initState();
    _billFuture = BillDomain.getById(widget.bill.billId);
    _initializeTabs();
    _tabController = TabController(length: _imageTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeTabs() {
    _imageTabs = [
      {
        'title': 'บิล',
        'icon': Icons.receipt_long,
        'imagePath': widget.bill.billImg,
        'bucket': 'bill/bill',
        'emptyMessage': 'ไม่มีรูปบิล',
        'description': 'รูปบิลจะแสดงที่นี่เมื่อมีการอัปโหลด',
      },
      {
        'title': 'สลิป',
        'icon': Icons.payment,
        'imagePath': widget.bill.slipImg,
        'bucket': 'bill/slip',
        'emptyMessage': 'ไม่มีสลิปการโอน',
        'description': 'สลิปการโอนจะแสดงที่นี่เมื่อชำระเงิน',
      },
      {
        'title': 'ใบเสร็จ',
        'icon': Icons.receipt,
        'imagePath': widget.bill.receiptImg,
        'bucket': 'bill/receipt',
        'emptyMessage': 'ไม่มีใบเสร็จ',
        'description': 'ใบเสร็จจะแสดงที่นี่เมื่อการชำระเสร็จสิ้น',
      },
    ];
  }

  void _refreshBill() {
    setState(() {
      _billFuture = BillDomain.getById(widget.bill.billId);
    });
  }

  bool _canPay(String status) {
    return ['PENDING', 'REJECTED', 'OVERDUE', 'REFUNDED'].contains(status);
  }

  void _navigateToPayment(BillModel bill) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BillPaymentPage(bill: bill)),
    ).then((result) {
      if (result == true) {
        _refreshBill();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF6), // Ivory White
      appBar: AppBar(
        title: Text(
          'บิลเลขที่ ${widget.bill.billId}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFDF6), // Ivory White
          ),
        ),
        backgroundColor: const Color(0xFFA47551),
        // Soft Brown
        foregroundColor: const Color(0xFFFFFDF6),
        // Ivory White
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBill,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: FutureBuilder<BillModel?>(
        future: _billFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFA47551)),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูลบิล...',
                    style: TextStyle(color: Color(0xFFBFA18F)),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFD48B5C),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ไม่สามารถโหลดข้อมูลบิลได้',
                    style: TextStyle(fontSize: 16, color: Color(0xFFBFA18F)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshBill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE08E45),
                      foregroundColor: const Color(0xFFFFFDF6),
                    ),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          final bill = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatusCard(bill),
                      const SizedBox(height: 16),
                      _buildBillDetailsCard(bill),
                      const SizedBox(height: 16),
                      if (bill.paidDate != null ||
                          bill.paidMethod != null ||
                          bill.referenceNo != null ||
                          bill.slipDate != null)
                        _buildPaymentDetailsCard(bill),
                    ],
                  ),
                ),
              ),
              if (_canPay(bill.status) && bill.paidStatus == 0)
                _buildPaymentButton(bill),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BillModel bill) {
    return Card(
      color: const Color(0xFFF5F0E1),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(bill.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(bill.status),
                    color: _getStatusColor(bill.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'สถานะบิล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA47551),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _getStatusColor(bill.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _getStatusColor(bill.status).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                _getStatusText(bill.status),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getStatusColor(bill.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getStatusDescription(bill.status),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFBFA18F), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillDetailsCard(BillModel bill) {
    return Card(
      color: const Color(0xFFFBF9F3),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: const Color(0xFFA47551).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFFA47551),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'รายละเอียดบิล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA47551),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('เลขที่บิล', bill.billId.toString()),
            _buildDetailRow('บ้านเลขที่', bill.houseId.toString()),
            _buildDetailRow('วันที่ออกบิล', _formatDate(bill.billDate)),
            _buildDetailRow('วันครบกำหนด', _formatDate(bill.dueDate)),
            const Divider(color: Color(0xFFD8CAB8)),
            _buildDetailRow(
              'จำนวนเงิน',
              '฿${bill.amount.toStringAsFixed(2)}',
              isAmount: true,
            ),
            _buildDetailRow(
              'สถานะการจ่าย',
              bill.paidStatus == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย',
              statusColor: bill.paidStatus == 1
                  ? const Color(0xFFA3B18A)
                  : const Color(0xFFE08E45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTab(Map<String, dynamic> tab) {
    final hasImage = tab['imagePath'] != null;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tab['icon'],
            size: 16,
            color: hasImage ? null : const Color(0xFFDCDCDC),
          ),
          const SizedBox(width: 6),
          Text(tab['title']),
          if (hasImage) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFA3B18A),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> tab) {
    if (tab['imagePath'] == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD0C4B0), width: 1),
          color: const Color(0xFFFFFDF6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab['icon'], size: 48, color: const Color(0xFFDCDCDC)),
            const SizedBox(height: 12),
            Text(
              tab['emptyMessage'],
              style: const TextStyle(
                color: Color(0xFFBFA18F),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tab['description'],
              style: const TextStyle(color: Color(0xFFC7B9A5), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFA3B18A).withOpacity(0.3),
          width: 1,
        ),
        color: const Color(0xFFFFFDF6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            BuildImage(
              imagePath: tab['imagePath'],
              tablePath: tab['bucket'],
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showFullScreenImage(tab),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(BillModel bill) {
    return Card(
      color: const Color(0xFFFBF9F3),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: const Color(0xFFA3B18A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Color(0xFFA3B18A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ข้อมูลการชำระเงิน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA47551),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // แสดงข้อมูลการชำระก่อน
            if (bill.slipDate != null)
              _buildDetailRow(
                'วันที่-เวลาโอนเงิน',
                _formatDateTime(bill.slipDate!),
              ),
            if (bill.paidDate != null)
              _buildDetailRow('วันที่จ่าย', _formatDate(bill.paidDate!)),
            if (bill.paidMethod != null)
              _buildDetailRow('วิธีการจ่าย', bill.paidMethod!),
            if (bill.referenceNo != null)
              _buildDetailRow('เลขที่อ้างอิง', bill.referenceNo!),

            // เพิ่ม Image Viewer ในส่วนนี้
            const SizedBox(height: 20),
            _buildPaymentImageViewer(bill),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentImageViewer(BillModel bill) {
    final hasAnyImage = _imageTabs.any((tab) => tab['imagePath'] != null);

    if (!hasAnyImage) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD0C4B0), width: 1),
          color: const Color(0xFFF5F0E1),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: Color(0xFFBFA18F),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'ยังไม่มีรูปภาพที่เกี่ยวข้อง',
              style: TextStyle(color: Color(0xFFBFA18F), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFFD8CAB8)),
        const SizedBox(height: 12),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE08E45).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.photo_library,
                color: Color(0xFFE08E45),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'รูปภาพที่เกี่ยวข้อง',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA47551),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD8CAB8), width: 1),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFFA47551),
              borderRadius: BorderRadius.circular(6),
            ),
            indicatorPadding: const EdgeInsets.all(3),
            dividerColor: Colors.transparent,
            labelColor: const Color(0xFFFFFDF6),
            unselectedLabelColor: const Color(0xFFBFA18F),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            tabs: _imageTabs.map((tab) => _buildImageTab(tab)).toList(),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 250,
          child: TabBarView(
            controller: _tabController,
            children: _imageTabs.map((tab) => _buildTabContent(tab)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton(BillModel bill) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF6),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8CAB8)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFE08E45),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getPaymentMessage(bill.status),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFBFA18F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _navigateToPayment(bill),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE08E45),
                  foregroundColor: const Color(0xFFFFFDF6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: const Color(0xFFE08E45).withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _getPaymentButtonText(bill.status),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isAmount = false,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFFBFA18F),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
                color: statusColor ?? const Color(0xFFA47551),
                fontSize: isAmount ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(Map<String, dynamic> tab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black.withOpacity(0.5),
            foregroundColor: Colors.white,
            title: Text(
              'รูป${tab['title']}',
              style: const TextStyle(color: Colors.white),
            ),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ฟีเจอร์ดาวน์โหลดจะพัฒนาในอนาคต'),
                      backgroundColor: Color(0xFFA3B18A),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: BuildImage(
                imagePath: tab['imagePath'],
                tablePath: tab['bucket'],
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFE08E45);
      case 'UNDER_REVIEW':
        return const Color(0xFFC7B9A5);
      case 'REJECTED':
        return const Color(0xFFD48B5C);
      case 'RECEIPT_SENT':
        return const Color(0xFFA3B18A);
      case 'OVERDUE':
        return const Color(0xFFCC7748);
      case 'REFUNDED':
        return const Color(0xFFA3B18A);
      default:
        return const Color(0xFFBFA18F);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.pending;
      case 'UNDER_REVIEW':
        return Icons.search;
      case 'REJECTED':
        return Icons.cancel;
      case 'RECEIPT_SENT':
        return Icons.check_circle;
      case 'OVERDUE':
        return Icons.warning;
      case 'REFUNDED':
        return Icons.refresh;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
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
      case 'REFUNDED':
        return 'คืนเงินแล้ว';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'PENDING':
        return 'บิลรอการชำระเงิน';
      case 'UNDER_REVIEW':
        return 'สลิปการโอนอยู่ระหว่างการตรวจสอบ';
      case 'REJECTED':
        return 'สลิปการโอนไม่ผ่านการตรวจสอบ กรุณาชำระใหม่';
      case 'RECEIPT_SENT':
        return 'ชำระเงินเรียบร้อยแล้ว';
      case 'OVERDUE':
        return 'บิลเลยกำหนดชำระ กรุณาชำระโดยด่วน';
      case 'REFUNDED':
        return 'ได้รับการคืนเงินแล้ว ต้องชำระใหม่';
      default:
        return '';
    }
  }

  String _getPaymentMessage(String status) {
    switch (status) {
      case 'PENDING':
        return 'สามารถชำระเงินได้ภายในวันครบกำหนด';
      case 'REJECTED':
        return 'สลิปการโอนไม่ผ่าน กรุณาชำระใหม่';
      case 'OVERDUE':
        return 'บิลเลยกำหนดแล้ว กรุณาชำระโดยด่วน';
      case 'REFUNDED':
        return 'ได้รับการคืนเงิน กรุณาชำระใหม่';
      default:
        return 'สามารถชำระเงินได้';
    }
  }

  String _getPaymentButtonText(String status) {
    switch (status) {
      case 'REJECTED':
        return 'ชำระใหม่';
      case 'OVERDUE':
        return 'ชำระเงิน (เลยกำหนด)';
      case 'REFUNDED':
        return 'ชำระใหม่';
      default:
        return 'ชำระเงิน';
    }
  }
}
