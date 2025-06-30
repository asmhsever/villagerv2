import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? username;
  String? villageName;
  List<dynamic> villagers = [];
  List<dynamic> filteredVillagers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    if (args != null) {
      _loadData(args);
    }
  }

  Future<void> _loadData(String user) async {
    final client = Supabase.instance.client;
    final admin = await client
        .from('admin')
        .select()
        .eq('username', user)
        .maybeSingle();

    final villageId = admin?['village_id'];
    String? fetchedVillageName;

    if (villageId != null) {
      final village = await client
          .from('village')
          .select()
          .eq('village_id', villageId)
          .maybeSingle();
      fetchedVillageName = village?['name'];

      final villagerList = await client
          .from('villager')
          .select()
          .eq('village_id', villageId);
      villagers = villagerList;
      filteredVillagers = List.from(villagers);
    }

    setState(() {
      username = admin?['username'] ?? 'ไม่ทราบชื่อ';
      villageName = fetchedVillageName ?? 'ไม่ทราบหมู่บ้าน';
    });
  }

  void _filterVillagers(String keyword) {
    final lower = keyword.toLowerCase();
    setState(() {
      filteredVillagers = villagers.where((v) {
        final fullName = '${v['first_name']} ${v['last_name']}'.toLowerCase();
        final house = v['house_id'].toString();
        return fullName.contains(lower) || house.contains(lower);
      }).toList();
    });
  }

  void _logout(BuildContext context) {
    Supabase.instance.client.auth.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ดผู้ดูแลระบบ'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: (username == null || villageName == null)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชื่อผู้ใช้: $username'),
            Text('หมู่บ้าน: $villageName'),
            const SizedBox(height: 20),
            const Text('รายชื่อลูกบ้าน:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'ค้นหาชื่อหรือลำดับบ้าน',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterVillagers,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredVillagers.length,
                itemBuilder: (context, index) {
                  final v = filteredVillagers[index];
                  return ListTile(
                    title: Text('${v['first_name']} ${v['last_name']}'),
                    subtitle: Text('บ้านเลขที่: ${v['house_id']}'),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
