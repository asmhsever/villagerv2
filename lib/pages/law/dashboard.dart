// lib/pages/law/law_dashboard_page.dart

import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class LawDashboardPage extends StatelessWidget {
  final int lawId;
  final int villageId;

  const LawDashboardPage({super.key, required this.lawId, required this.villageId});

  @override
  Widget build(BuildContext context) {
    final items = [
      _DashboardItem('จัดการลูกบ้าน', Icons.people, AppRoutes.houseDashboard),
      _DashboardItem('จัดการร้องเรียน', Icons.report_problem, AppRoutes.lawComplaintList),
      _DashboardItem('ข่าวสาร/ประกาศ', Icons.campaign, AppRoutes.lawNews),
      _DashboardItem('ข้อมูลสัตว์เลี้ยง', Icons.pets, AppRoutes.lawAnimal),
      _DashboardItem('ประชุมลูกบ้าน', Icons.meeting_room, AppRoutes.lawMeeting),
      _DashboardItem('ค่าส่วนกลาง', Icons.receipt_long, AppRoutes.lawFee),
      _DashboardItem('สถานะค้างชำระ', Icons.warning, AppRoutes.lawDebtStatus),
      _DashboardItem('รายงานสรุป', Icons.insert_chart, AppRoutes.lawReport),
      _DashboardItem('ข้อมูลส่วนตัว', Icons.person, AppRoutes.lawProfile),
      _DashboardItem('เปลี่ยนรหัสผ่าน', Icons.lock_reset, AppRoutes.lawChangePassword),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('แดชบอร์ด - ฝ่ายนิติบุคคล')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: items
                  .map((item) => _buildCard(context, item.title, item.icon, item.route))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route, arguments: {
          'lawId': lawId,
          'villageId': villageId,
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final String route;
  const _DashboardItem(this.title, this.icon, this.route);
}
