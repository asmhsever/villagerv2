// 📁 lib/views/juristic/house_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'house_detail_screen.dart';
import 'edit_house_screen.dart';

class HouseDashboardScreen extends StatefulWidget {
  final int villageId;
  const HouseDashboardScreen({super.key, required this.villageId});

  @override
  State<HouseDashboardScreen> createState() => _HouseDashboardScreenState();
}

class _HouseDashboardScreenState extends State<HouseDashboardScreen> {
  List<Map<String, dynamic>> houses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    final response = await Supabase.instance.client
        .from('house')
        .select()
        .eq('village_id', widget.villageId);
    setState(() {
      houses = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  void _addHouse() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditHouseScreen(villageId: widget.villageId),
      ),
    ).then((_) => _loadHouses());
  }

  void _openHouse(int houseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HouseDetailScreen(houseId: houseId),
      ),
    ).then((_) => _loadHouses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการบ้าน')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHouse,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: houses.length,
        itemBuilder: (_, i) {
          final h = houses[i];
          return ListTile(
            title: Text('บ้านเลขที่: ${h['house_id']}'),
            subtitle: Text('เจ้าของ: ${h['username'] ?? '-'}'),
            onTap: () => _openHouse(h['house_id']),
          );
        },
      ),
    );
  }
}
