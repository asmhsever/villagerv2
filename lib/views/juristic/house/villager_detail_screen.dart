// lib/views/juristic/house/villager_detail_screen.dart

import 'package:flutter/material.dart';
import 'villager_model.dart';

class VillagerDetailScreen extends StatelessWidget {
  final Villager villager;

  const VillagerDetailScreen({super.key, required this.villager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดผู้อยู่อาศัย')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชื่อ: ${villager.firstName ?? "-"}'),
            const SizedBox(height: 8),
            Text('นามสกุล: ${villager.lastName ?? "-"}'),
            const SizedBox(height: 8),
            Text('วันเกิด: ${villager.birthDate ?? "-"}'),
            const SizedBox(height: 8),
            Text('เพศ: ${villager.gender ?? "-"}'),
            const SizedBox(height: 8),
            Text('เบอร์โทร: ${villager.phone ?? "-"}'),
            const SizedBox(height: 8),
            Text('เลขบัตรประชาชน: ${villager.cardNumber ?? "-"}'),
          ],
        ),
      ),
    );
  }
}
