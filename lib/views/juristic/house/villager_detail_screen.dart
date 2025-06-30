// 📁 lib/views/juristic/villager_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_villager_screen.dart';

class VillagerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> villager;
  const VillagerDetailScreen({super.key, required this.villager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดลูกบ้าน')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชื่อ: ${villager['first_name'] ?? '-'}'),
            Text('นามสกุล: ${villager['last_name'] ?? '-'}'),
            Text('วันเกิด: ${villager['birth_date'] ?? '-'}'),
            Text('เพศ: ${villager['gender'] ?? '-'}'),
            Text('เบอร์โทร: ${villager['phone'] ?? '-'}'),
            Text('บัตรประชาชน: ${villager['card_number'] ?? '-'}'),
            Text('บ้านเลขที่ (house_id): ${villager['house_id'] ?? '-'}'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('แก้ไขข้อมูล'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditVillagerScreen(villager: villager),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
