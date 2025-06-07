// lib/views/juristic/juristic_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JuristicDashboard extends StatefulWidget {
  const JuristicDashboard({super.key});

  @override
  State<JuristicDashboard> createState() => _JuristicDashboardState();
}

class _JuristicDashboardState extends State<JuristicDashboard> {
  int? lawId;
  String? fullName;
  String? phone;
  String? villageName;
  bool isLoading = true;
  bool hasArgument = true;
  int? villageId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      lawId = args;
      _loadData(args);
    } else {
      setState(() {
        isLoading = false;
        hasArgument = false;
      });
    }
  }

  Future<void> _loadData(int id) async {
    final client = Supabase.instance.client;
    final law = await client.from('law').select().eq('law_id', id).maybeSingle();
    if (law != null) {
      final village = await client
          .from('village')
          .select()
          .eq('village_id', law['village_id'])
          .maybeSingle();

      setState(() {
        fullName = '${law['first_name']} ${law['last_name']}';
        phone = law['phone'];
        villageName = village?['name'];
        villageId = law['village_id'];
        isLoading = false;
        hasArgument = true;
      });
    } else {
      setState(() {
        isLoading = false;
        hasArgument = false;
      });
    }
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ดผู้นิติ'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชื่อ: ${fullName ?? '-'}'),
            Text('เบอร์โทร: ${phone ?? '-'}'),
            Text('หมู่บ้าน: ${villageName ?? '-'}'),
            if (!hasArgument)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  '⚠️ ไม่ได้ส่งรหัสผู้นิติมา กรุณาเข้าสู่ระบบใหม่',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            if (hasArgument)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.campaign),
                    label: const Text('จัดการประกาศข่าวสาร'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/juristic/notion',
                        arguments: {
                          'law_id': lawId,
                          'village_id': villageId,
                        },
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.report_problem),
                    label: const Text('จัดการปัญหา/คำร้องเรียน'),
                    onPressed: () {
                      // Implement navigation when screen is ready
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_money),
                    label: const Text('จัดการค่าส่วนกลาง'),
                    onPressed: () {
                      // Implement navigation when screen is ready
                    },
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
