// 📁 lib/views/juristic/bill/bill_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillDetailScreen extends StatefulWidget {
  final int billId;
  final int villageId;
  const BillDetailScreen({super.key, required this.billId, required this.villageId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  Map<String, dynamic>? bill;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> types = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBill();
    _loadTypes();
  }

  Future<void> _loadBill() async {
    final client = Supabase.instance.client;
    try {
      final area = await client
          .from('bill_area')
          .select()
          .eq('bill_id', widget.billId)
          .maybeSingle();

      final detail = await client
          .from('bill_item')
          .select('bill_item_id, amount, type_service')
          .eq('bill_id', widget.billId);

      setState(() {
        bill = area;
        items = List<Map<String, dynamic>>.from(detail);
        loading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading bill detail: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _loadTypes() async {
    final data = await Supabase.instance.client
        .from('service')
        .select('service_id, name');
    setState(() {
      types = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> _deleteItem(int id) async {
    await Supabase.instance.client
        .from('bill_item')
        .delete()
        .eq('bill_item_id', id);
    _loadBill();
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
    final amountCtrl = TextEditingController(text: item['amount'].toString());
    int selectedType = item['type_service'];

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขรายการบิล'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedType,
              items: types.map((t) => DropdownMenuItem<int>(
                value: t['service_id'],
                child: Text(t['name']),
              )).toList(),
              onChanged: (v) => selectedType = v!,
              decoration: const InputDecoration(labelText: 'ประเภทบริการ'),
            ),
            TextFormField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.from('bill_item').update({
                'type_service': selectedType,
                'amount': double.tryParse(amountCtrl.text) ?? 0,
              }).eq('bill_item_id', item['bill_item_id']);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (result == true) _loadBill();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('รายละเอียดบิล #${widget.billId}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📅 วันที่ออกบิล: ${bill?['bill_date'] ?? '-'}'),
            Text('🏠 บ้านเลขที่: ${bill?['house_id'] ?? '-'}'),
            const Divider(height: 30),
            const Text('📄 รายการบิล', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map((item) => ListTile(
              title: Text('ประเภท: ${item['type_service']}'),
              subtitle: Text('จำนวนเงิน: ${item['amount']} บาท'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editItem(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteItem(item['bill_item_id']),
                  ),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }
}
