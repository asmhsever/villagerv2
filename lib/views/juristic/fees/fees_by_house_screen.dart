// 📁 lib/views/juristic/fees/fees_by_house_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'fees_bill_add_screen.dart';
import 'fees_detail_screen.dart';

class FeesByHouseScreen extends StatefulWidget {
  final int houseId;
  const FeesByHouseScreen({super.key, required this.houseId});

  @override
  State<FeesByHouseScreen> createState() => _FeesByHouseScreenState();
}

class _FeesByHouseScreenState extends State<FeesByHouseScreen> {
  List<Map<String, dynamic>> _bills = [];
  bool _loading = true;
  String houseNumber = '-';

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;
    try {
      final data = await client
          .from('bill_area')
          .select('*, house(house_number), service(name)')
          .eq('house_id', widget.houseId)
          .order('bill_date', ascending: false);

      final List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(data);
      final String hn = result.isNotEmpty ? (result.first['house']?['house_number'] ?? '-') : '-';

      setState(() {
        _bills = result;
        houseNumber = hn;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ loadBills error: $e');
      setState(() => _loading = false);
    }
  }

  String _formatStatus(int? status) => status == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ';

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final moneyFmt = NumberFormat('#,##0', 'th_TH');

    return Scaffold(
      appBar: AppBar(title: Text('รายการบิลบ้านเลขที่ $houseNumber')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
          ? const Center(child: Text('ไม่พบบิล'))
          : ListView.builder(
        itemCount: _bills.length,
        itemBuilder: (_, i) {
          final b = _bills[i];
          final billDateStr = b['bill_date'] != null
              ? fmt.format(DateTime.tryParse(b['bill_date']) ?? DateTime(2000))
              : '-';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('วันที่บิล: $billDateStr'),
              subtitle: Text(
                'ยอดรวม: ${moneyFmt.format(b['amount'])} บาท\nบริการ: ${b['service']?['name'] ?? '-'}',
              ),
              trailing: Text(_formatStatus(b['paid_status'])),
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeesBillDetailScreen(billId: b['bill_id']),
                  ),
                );
                if (updated == true) _loadBills();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FeesBillAddScreen(houseId: widget.houseId),
            ),
          );
          if (added == true) _loadBills();
        },
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มบิล'),
      ),
    );
  }
}
