// 📁 lib/views/juristic/house_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'house_detail_screen.dart';
import 'edit_house_screen.dart';
import 'house_service.dart';
import 'house_model.dart';

class HouseDashboardScreen extends StatefulWidget {
  final int villageId;
  const HouseDashboardScreen({super.key, required this.villageId});

  @override
  State<HouseDashboardScreen> createState() => _HouseDashboardScreenState();
}

class _HouseDashboardScreenState extends State<HouseDashboardScreen> {
  final HouseService houseService = HouseService();
  List<House> houses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    final results = await houseService.getByVillage(widget.villageId);
    setState(() {
      houses = results;
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
            title: Text('บ้านเลขที่: \${h.houseNumber ?? "-"}'),
            subtitle: Text('เจ้าของ: \${h.username ?? "-"}'),
            onTap: () => _openHouse(h.houseId),
          );
        },
      ),
    );
  }
}
