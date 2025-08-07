import 'package:flutter/material.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/models/bill_model.dart';

class HouseBillPage extends StatefulWidget {
  final int houseId;

  const HouseBillPage({super.key, required this.houseId});

  @override
  State<HouseBillPage> createState() => _HouseBillPageState();
}

class _HouseBillPageState extends State<HouseBillPage> {
  late Future<List<BillModel>> _billsFuture;
  String _currentFilter = 'all'; // all, unpaid, paid

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  void _loadBills() {
    switch (_currentFilter) {
      case 'unpaid':
        _billsFuture = BillDomain.getUnpaidInHouse(houseId: widget.houseId);
        break;
      case 'paid':
        _billsFuture = BillDomain.getPaidInHouse(houseId: widget.houseId);
        break;
      default:
        _billsFuture = BillDomain.getAllInHouse(houseId: widget.houseId);
    }
  }

  void _refreshBills() {
    setState(() {
      _loadBills();
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
      body: RefreshIndicator(
        onRefresh: () async => _refreshBills(),
        child: FutureBuilder<List<BillModel>>(
          future: _billsFuture,
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
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
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshBills,
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
                      color: Colors.grey,
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
                  onPaymentUpdate: _refreshBills,
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _getEmptyMessage() {
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
    ).then((_) => _refreshBills()); // Refresh เมื่อกลับมา
  }

  void _navigateToAddBill() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Text("e")),
    ).then((_) => _refreshBills()); // Refresh เมื่อกลับมา
  }
}

// Widget สำหรับแสดงข้อมูลบิลแต่ละรายการ
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
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bill.paidStatus == 1 ? Colors.green : Colors.orange,
          child: Icon(
            bill.paidStatus == 1 ? Icons.check : Icons.pending,
            color: Colors.white,
          ),
        ),
        title: Text(
          'บิลเลขที่ ${bill.billId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('จำนวนเงิน: ฿${bill.amount.toStringAsFixed(2)}'),
            Text('วันครบกำหนด: ${bill.dueDate}'),
            Text(
              bill.paidStatus == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย',
              style: TextStyle(
                color: bill.paidStatus == 1 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: bill.paidStatus == 0
            ? IconButton(
                icon: const Icon(Icons.payment),
                onPressed: () => _showPaymentDialog(context),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
        onTap: onTap,
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ชำระเงิน'),
        content: Text('ต้องการชำระบิลเลขที่ ${bill.billId} หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _markAsPaid(context);
            },
            child: const Text('ชำระ'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(BuildContext context) async {
    final success = await BillDomain.updatePaymentStatus(
      billId: bill.billId,
      paidStatus: 1,
      paidDate: DateTime.now().toIso8601String().split('T')[0],
      paidMethod: 'manual',
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ชำระเงินสำเร็จ')));
      onPaymentUpdate?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการชำระเงิน')),
      );
    }
  }
}

// หน้าสำหรับดูรายละเอียดบิล (Lazy Loading เฉพาะบิล)
class BillDetailScreen extends StatefulWidget {
  final BillModel bill;

  const BillDetailScreen({Key? key, required this.bill}) : super(key: key);

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  late Future<BillModel?> _billFuture;

  @override
  void initState() {
    super.initState();
    _billFuture = BillDomain.getById(widget.bill.billId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('บิลเลขที่ ${widget.bill.billId}')),
      body: FutureBuilder<BillModel?>(
        future: _billFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('ไม่สามารถโหลดข้อมูลบิลได้'));
          }

          final bill = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('เลขที่บิล', bill.billId.toString()),
                _buildDetailRow('บ้านเลขที่', bill.houseId.toString()),
                _buildDetailRow('วันที่ออกบิล', bill.billDate.toString()),
                _buildDetailRow(
                  'จำนวนเงิน',
                  '฿${bill.amount.toStringAsFixed(2)}',
                ),
                _buildDetailRow('วันครบกำหนด', bill.dueDate.toString()),
                _buildDetailRow(
                  'สถานะ',
                  bill.paidStatus == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย',
                ),
                if (bill.paidDate != null)
                  _buildDetailRow('วันที่จ่าย', bill.paidDate!.toString()),
                if (bill.paidMethod != null)
                  _buildDetailRow('วิธีการจ่าย', bill.paidMethod!),
                if (bill.referenceNo != null)
                  _buildDetailRow('เลขที่อ้างอิง', bill.referenceNo!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
