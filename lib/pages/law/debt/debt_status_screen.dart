// lib/pages/law/debt/debt_status_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DebtStatusScreen extends StatelessWidget {
  final int villageId;

  const DebtStatusScreen({super.key, required this.villageId});

  Future<List<Map<String, dynamic>>> _fetchDebtHouses() async {
    final response = await Supabase.instance.client
        .from('bill_area')
        .select('house_id, amount, due_date, paid_status, house!inner(house_number, owner, village_id)')
        .eq('paid_status', 0)
        .eq('house.village_id', villageId);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สถานะค้างชำระ')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchDebtHouses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: \${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่พบข้อมูลบ้านที่ค้างชำระ'));
          }

          final data = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final house = data[index];
              final info = house['house'];
              return ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text('บ้านเลขที่: ${info['house_number']}'),
                subtitle: Text('เจ้าของ: ${info['owner']}\nครบกำหนด: ${house['due_date']}'),
                trailing: Text(
                  '฿${house['amount']}',
                  style: const TextStyle(color: Colors.red),
                ),
              );

            },
          );
        },
      ),
    );
  }
}
