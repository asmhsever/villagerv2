// lib/views/resident/bill_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentBillScreen extends StatefulWidget {
  const ResidentBillScreen({super.key});

  @override
  State<ResidentBillScreen> createState() => _ResidentBillScreenState();
}

class _ResidentBillScreenState extends State<ResidentBillScreen> {
  List<Map<String, dynamic>> bills = [];
  bool isLoading = true;
  int? houseId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    houseId = ModalRoute.of(context)?.settings.arguments as int?;
    if (houseId != null) {
      _loadBills(houseId!);
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadBills(int houseId) async {
    final client = Supabase.instance.client;
    final data = await client
        .from('bill_area')
        .select()
        .eq('house_id', houseId)
        .order('bill_date', ascending: false);

    setState(() {
      bills = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
  }

  String formatStatus(int? status) {
    if (status == 1) return '✅ ชำระแล้ว';
    return '🕒 รอชำระ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการค่าส่วนกลาง')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bills.isEmpty
          ? const Center(child: Text('ไม่พบรายการ'))
          : ListView.builder(
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          return ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text('วันที่: ${bill['bill_date'] ?? ''}'),
            subtitle: Text('ยอดรวม: ${bill['total_amount']} บาท'),
            trailing: Text(formatStatus(bill['status'])),
          );
        },
      ),
    );
  }
}
