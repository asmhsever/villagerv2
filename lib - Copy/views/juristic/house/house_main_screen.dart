// lib/views/juristic/house/house_main_screen.dart

import 'package:flutter/material.dart';
import 'house_dashboard_screen.dart';
import 'house_search_screen.dart';

class HouseMainScreen extends StatelessWidget {
  final int villageId;
  const HouseMainScreen({super.key, required this.villageId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการบ้านทั้งหมด')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dashboard_customize_outlined),
            title: const Text('แดชบอร์ดบ้าน'),
            subtitle: const Text('ดูข้อมูลบ้านทั้งหมดในหมู่บ้าน'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HouseDashboardScreen(villageId: villageId),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('ค้นหาบ้าน'),
            subtitle: const Text('ค้นหาบ้านจากชื่อเจ้าของ ลูกบ้าน ทะเบียนรถ หรือสัตว์เลี้ยง'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HouseSearchScreen(),

              ),
            ),
          ),
        ],
      ),
    );
  }
}
