// lib/views/resident/resident_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({super.key});

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  int? villagerId;
  int? houseId;
  int? villageId;
  String? fullName;
  String? phone;
  String? villageName;
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      villagerId = args;
      _loadData(args);
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadData(int id) async {
    final client = Supabase.instance.client;
    final villager = await client
        .from('villager')
        .select()
        .eq('villager_id', id)
        .maybeSingle();

    if (villager != null) {
      final house = await client
          .from('house')
          .select()
          .eq('house_id', villager['house_id'])
          .maybeSingle();

      final village = await client
          .from('village')
          .select()
          .eq('village_id', house?['village_id'])
          .maybeSingle();

      setState(() {
        fullName = '${villager['first_name']} ${villager['last_name']}';
        phone = villager['phone'];
        houseId = villager['house_id'];
        villageId = house?['village_id'];
        villageName = village?['name'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แดชบอร์ดลูกบ้าน')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชื่อ: ${fullName ?? '-'}'),
            Text('เบอร์: ${phone ?? '-'}'),
            Text('หมู่บ้าน: ${villageName ?? '-'}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.report),
              label: const Text('แจ้งปัญหา'),
              onPressed: () {
                Navigator.pushNamed(context, '/resident/complaint', arguments: {
                  'villager_id': villagerId,
                  'house_id': houseId,
                  'village_id': villageId,
                });
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.campaign),
              label: const Text('ดูประกาศข่าวสาร'),
              onPressed: () {
                Navigator.pushNamed(context, '/resident/notion', arguments: villageId);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_money),
              label: const Text('ดูค่าส่วนกลาง'),
              onPressed: () {
                Navigator.pushNamed(context, '/resident/bill', arguments: houseId);
              },
            ),
          ],
        ),
      ),
    );
  }
}
