// 📁 lib/views/juristic/house_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_villager_screen.dart';
import 'edit_house_screen.dart';
import 'villager_detail_screen.dart';
import 'car_detail_screen.dart';
import 'animal_detail_screen.dart';
import 'edit_car_screen.dart';
import 'edit_animal_screen.dart';

class HouseDetailScreen extends StatefulWidget {
  final int houseId;
  const HouseDetailScreen({super.key, required this.houseId});

  @override
  State<HouseDetailScreen> createState() => _HouseDetailScreenState();
}

class _HouseDetailScreenState extends State<HouseDetailScreen> {
  Map<String, dynamic>? house;
  List<Map<String, dynamic>> villagers = [];
  List<Map<String, dynamic>> cars = [];
  List<Map<String, dynamic>> animals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final client = Supabase.instance.client;
    try {
      final h = await client
          .from('house')
          .select()
          .eq('house_id', widget.houseId)
          .maybeSingle();

      final v = await client
          .from('villager')
          .select()
          .eq('house_id', widget.houseId);

      final c = await client
          .from('car')
          .select()
          .eq('house_id', widget.houseId);

      final a = await client
          .from('animal')
          .select()
          .eq('house_id', widget.houseId);

      setState(() {
        house = h;
        villagers = List<Map<String, dynamic>>.from(v);
        cars = List<Map<String, dynamic>>.from(c);
        animals = List<Map<String, dynamic>>.from(a);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load house details: $e');
      setState(() => isLoading = false);
    }
  }

  void _editVillager(Map<String, dynamic> villager) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VillagerDetailScreen(villager: villager),
      ),
    ).then((_) => _loadData());
  }

  void _viewCar(Map<String, dynamic> car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarDetailScreen(car: car),
      ),
    );
  }

  void _viewAnimal(Map<String, dynamic> animal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(animal: animal),
      ),
    );
  }

  void _addVillager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditVillagerScreen(houseId: widget.houseId),
      ),
    ).then((_) => _loadData());
  }

  void _addCar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCarScreen(houseId: widget.houseId),
      ),
    ).then((_) => _loadData());
  }

  void _addAnimal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAnimalScreen(houseId: widget.houseId),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดบ้าน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditHouseScreen(house: house!),
              ),
            ).then((_) => _loadData()),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add-villager',
            onPressed: _addVillager,
            child: const Icon(Icons.person_add),
            tooltip: 'เพิ่มลูกบ้าน',
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add-car',
            onPressed: _addCar,
            child: const Icon(Icons.directions_car),
            tooltip: 'เพิ่มรถ',
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add-animal',
            onPressed: _addAnimal,
            child: const Icon(Icons.pets),
            tooltip: 'เพิ่มสัตว์เลี้ยง',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏠 เจ้าของบ้าน: ${house?['username'] ?? '-'}'),
            Text('📏 ขนาด: ${house?['size'] ?? '-'}'),
            Text('🏡 หมู่บ้าน: ${house?['village_id'] ?? '-'}'),
            const Divider(height: 30),

            const Text('ลูกบ้านในบ้านนี้:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...villagers.map((v) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text('${v['first_name']} ${v['last_name']}'),
              subtitle: Text('เบอร์: ${v['phone']}'),
              onTap: () => _editVillager(v),
            )),

            const Divider(height: 30),
            const Text('รถในบ้านนี้:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...cars.map((c) => ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text('${c['brand']} ${c['model']}'),
              subtitle: Text('ทะเบียน: ${c['number']}'),
              onTap: () => _viewCar(c),
            )),

            const Divider(height: 30),
            const Text('สัตว์เลี้ยงในบ้านนี้:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...animals.map((a) => ListTile(
              leading: const Icon(Icons.pets),
              title: Text('${a['type']}'),
              subtitle: Text('${a['name']}'),
              onTap: () => _viewAnimal(a),
            )),
          ],
        ),
      ),
    );
  }
}
