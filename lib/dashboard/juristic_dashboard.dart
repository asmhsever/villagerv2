// lib/views/juristic/juristic_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:superprojectv2/views/juristic/profile/profile_screen.dart';

import '../views/juristic/house/house_main_screen.dart';



class JuristicDashboard extends StatefulWidget {
  const JuristicDashboard({super.key});

  @override
  State<JuristicDashboard> createState() => _JuristicDashboardState();
}

class _JuristicDashboardState extends State<JuristicDashboard> {
  String? firstName;
  String? lastName;
  int? lawId;
  int? villageId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as int?;
    if (id != null) _loadProfile(id);
  }

  Future<void> _loadProfile(int id) async {
    final client = Supabase.instance.client;
    final result = await client
        .from('law')
        .select()
        .eq('law_id', id)
        .maybeSingle();

    if (result != null) {
      setState(() {
        lawId = result['law_id'];
        villageId = result['village_id'];
        firstName = result['first_name'] ?? 'ไม่ทราบชื่อ';
        lastName = result['last_name'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(title: const Text('แดชบอร์ดผู้นิติ')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชื่อ: ${firstName ?? ''} ${lastName ?? ''}'),
            const SizedBox(height: 32),
            _buildMenuButton(
              icon: Icons.person,
              label: 'แก้ไขข้อมูลส่วนตัว',
              onTap: () {
                if (lawId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JuristicProfileScreen(lawId: lawId!),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              icon: Icons.campaign,
              label: 'จัดการประกาศข่าวสาร',
              onTap: () {
                if (lawId != null && villageId != null) {
                  Navigator.pushNamed(
                    context,
                    '/juristic/notion',
                    arguments: {
                      'law_id': lawId,
                      'village_id': villageId,
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              icon: Icons.report_problem,
              label: 'จัดการปัญหา/คำร้องเรียน',
              onTap: () {
                if (villageId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไม่พบข้อมูลหมู่บ้าน')),
                  );
                  return;
                }
                Navigator.pushNamed(
                  context,
                  '/juristic/complaints',
                  arguments: villageId,
                );
              },
            ),

            const SizedBox(height: 16),
            _buildMenuButton(
              icon: Icons.attach_money,
              label: 'จัดการค่าส่วนกลาง',
              onTap: () {
                if (villageId != null) {
                  Navigator.pushNamed(
                    context,
                    '/juristic/fees',
                    arguments: villageId,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไม่พบข้อมูลหมู่บ้าน')),
                  );
                }
              },
            ),

            const SizedBox(height: 16),
            _buildMenuButton(
              icon: Icons.group,
              label: 'จัดการลูกบ้าน',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HouseMainScreen(villageId: villageId!),

                    settings: RouteSettings(arguments: lawId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.deepPurple),
      label: Text(label, style: const TextStyle(color: Colors.deepPurple)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple.shade50,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onTap,
    );
  }
}
