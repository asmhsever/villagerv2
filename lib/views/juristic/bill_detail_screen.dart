import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillDetailScreen extends StatefulWidget {
  final int billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBillItems();
  }

  Future<void> _loadBillItems() async {
    final data = await Supabase.instance.client
        .from('bill_item')
        .select('amount, type_service')
        .eq('bill_id', widget.billId);

    setState(() {
      _items = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('รายละเอียดบิล #${widget.billId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          return ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text('บริการประเภท ${item['type_service']}'),
            trailing: Text('${item['amount']} บาท'),
          );
        },
      ),
    );
  }
}
