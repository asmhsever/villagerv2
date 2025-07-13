// 📁 lib/views/juristic/house/house_search_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'animal_model.dart';
import 'car_model.dart';
import 'house_model.dart';
import 'villager_model.dart';
import 'animal_detail_screen.dart';
import 'car_detail_screen.dart';
import 'house_detail_screen.dart';
import 'villager_detail_screen.dart';

class HouseSearchScreen extends StatefulWidget {
  const HouseSearchScreen({super.key});

  @override
  State<HouseSearchScreen> createState() => _HouseSearchScreenState();
}

class _HouseSearchScreenState extends State<HouseSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  List<dynamic> _results = [];

  Future<void> _performSearch() async {
    final keyword = _controller.text.trim().toLowerCase();
    if (keyword.isEmpty) return;

    setState(() => _loading = true);
    final client = Supabase.instance.client;

    final List<List<dynamic>> responses = await Future.wait([
      client
          .from('house')
          .select()
          .ilike('username', '%$keyword%')
          .then((res) => List<Map<String, dynamic>>.from(res)
          .map((e) => House.fromMap(e)).toList()),

      client
          .from('villager')
          .select()
          .or('first_name.ilike.%$keyword%,last_name.ilike.%$keyword%')
          .then((res) => List<Map<String, dynamic>>.from(res)
          .map((e) => Villager.fromMap(e)).toList()),

      client
          .from('car')
          .select()
          .ilike('number', '%$keyword%')
          .then((res) => List<Map<String, dynamic>>.from(res)
          .map((e) => Car.fromMap(e)).toList()),

      client
          .from('animal')
          .select()
          .ilike('name', '%$keyword%')
          .then((res) => List<Map<String, dynamic>>.from(res)
          .map((e) => Animal.fromMap(e)).toList()),
    ]);

    final all = <dynamic>[];
    for (final list in responses) {
      all.addAll(list);
    }

    setState(() {
      _results = all;
      _loading = false;
    });
  }

  void _openDetail(dynamic item) {
    if (item is House) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => HouseDetailScreen(houseId: item.houseId),
      ));
    } else if (item is Villager) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => VillagerDetailScreen(villager: item),
      ));
    } else if (item is Car) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CarDetailScreen(car: item),
      ));
    } else if (item is Animal) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(animal: item),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ค้นหาบ้าน')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'ค้นหาด้วยชื่อ, ทะเบียนรถ, ชื่อสัตว์เลี้ยง',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading && _results.isEmpty) const Text('ไม่พบข้อมูล'),
            if (!_loading && _results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final item = _results[i];
                    String title = '';
                    String subtitle = '';

                    if (item is House) {
                      title = 'บ้านเลขที่: ${item.houseNumber ?? '-'}';
                      subtitle = 'เจ้าของ: ${item.username ?? '-'}';
                    } else if (item is Villager) {
                      title = 'ชื่อ: ${item.firstName ?? '-'}';
                      subtitle = 'เบอร์: ${item.phone ?? '-'}';
                    } else if (item is Car) {
                      title = 'ทะเบียน: ${item.number ?? '-'}';
                      subtitle = 'ยี่ห้อ: ${item.brand ?? '-'}';
                    } else if (item is Animal) {
                      title = 'ชื่อสัตว์เลี้ยง: ${item.name ?? '-'}';
                      subtitle = 'ประเภท: ${item.type ?? '-'}';
                    }

                    return ListTile(
                      title: Text(title),
                      subtitle: Text(subtitle),
                      onTap: () => _openDetail(item),
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
