// lib/views/juristic/fees_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bill_detail_screen.dart';


class JuristicFeesScreen extends StatefulWidget {
  const JuristicFeesScreen({super.key});

  @override
  State<JuristicFeesScreen> createState() => _JuristicFeesScreenState();
}

class _JuristicFeesScreenState extends State<JuristicFeesScreen> {
  List<Map<String, dynamic>> _bills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    final client = Supabase.instance.client;
    try {
      final data = await client
          .from('bill_area')
          .select('bill_id, house_id, bill_date, total_amount, status');

      setState(() {
        _bills = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      debugPrint('loadBills error: $e');
      setState(() => _loading = false);
    }
  }

  String _formatStatus(int status) => status == 1 ? 'ชำระแล้ว' : 'ยังไม่จ่าย';

  Future<void> _toggleStatus(int billId, int currentStatus) async {
    final newStatus = currentStatus == 1 ? 0 : 1;
    await Supabase.instance.client
        .from('bill_area')
        .update({'status': newStatus})
        .eq('bill_id', billId);
    _loadBills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการค่าส่วนกลาง')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _bills.length,
        itemBuilder: (_, i) {
          final bill = _bills[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('บ้านเลขที่: ${bill['house_id']}'),
              subtitle: Text('ยอดรวม: ${bill['total_amount']} บาท'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_formatStatus(bill['status'])),
                  TextButton(
                    onPressed: () => _toggleStatus(bill['bill_id'], bill['status']),
                    child: const Text('เปลี่ยนสถานะ'),
                  ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BillDetailScreen(billId: bill['bill_id']),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
