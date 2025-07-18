// lib/pages/law/law_dashboard_page.dart

import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class LawDashboardPage extends StatelessWidget {
  const LawDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ด - นิติบุคคล'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: [
          _buildCard(context, 'จัดการลูกบ้าน', Icons.people, AppRoutes.houseDashboard),
          _buildCard(context, 'จัดการร้องเรียน', Icons.report_problem, AppRoutes.lawComplaintList),
          _buildCard(context, 'ข่าวสาร/ประกาศ', Icons.campaign, AppRoutes.lawNews),
          _buildCard(context, 'ข้อมูลสัตว์เลี้ยง', Icons.pets, AppRoutes.lawAnimal),
          _buildCard(context, 'ประชุมลูกบ้าน', Icons.meeting_room, AppRoutes.lawMeeting),
          _buildCard(context, 'ค่าส่วนกลาง', Icons.receipt_long, AppRoutes.lawFee),
          _buildCard(context, 'รายงานสรุป', Icons.insert_chart, AppRoutes.lawReport),
          _buildCard(context, 'ข้อมูลส่วนตัว', Icons.person, AppRoutes.lawProfile),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center)
            ],
          ),
        ),
      ),
    );
  }
}