import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'house_detail_screen.dart';

class HouseSearchScreen extends StatefulWidget {
  const HouseSearchScreen({super.key});

  @override
  State<HouseSearchScreen> createState() => _HouseSearchScreenState();
}

class _HouseSearchScreenState extends State<HouseSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];

  Future<void> _performSearch() async {
    final keyword = _controller.text.trim().toLowerCase();
    if (keyword.isEmpty) return;

    setState(() => _loading = true);
    final client = Supabase.instance.client;

    final List<List<Map<String, dynamic>>> responses = await Future.wait([
      client
          .from('house')
          .select()
          .ilike('username', '%$keyword%')
          .then((res) => List<Map<String, dynamic>>.from(res).map((e) => {...e, 'type': 'house'}).toList()),

      client
          .from('villager')
          .select()
          .or('first_name.ilike.%$keyword%,last_name.ilike.%$keyword%')
          .then((res) => List<Map<String, dynamic>>.from(res).map((e) => {...e, 'type': 'villager'}).toList()),

      client
          .from('car')
          .select()
          .ilike('number', '%$keyword%')
          .then((res) => List<Map<String, dynamic>>.from(res).map((e) => {...e, 'type': 'car'}).toList()),

      client
          .from('animal')
          .select()
          .ilike('name', '%$keyword%')
          .then((res) => List<Map<String, dynamic>>.from(res).map((e) => {...e, 'type': 'animal'}).toList()),
    ]);


    final all = <Map<String, dynamic>>[];
    for (final list in responses) {
      for (final row in list) {
        final houseId = row['house_id'];
        if (houseId != null) {
          all.add({...row, 'house_id': houseId});
        }
      }
    }

    setState(() {
      _results = all;
      _loading = false;
    });
  }

  Icon getIconByType(String type) {
    switch (type) {
      case 'house':
        return const Icon(Icons.home, color: Colors.blue);
      case 'villager':
        return const Icon(Icons.person, color: Colors.green);
      case 'car':
        return const Icon(Icons.directions_car, color: Colors.orange);
      case 'animal':
        return const Icon(Icons.pets, color: Colors.purple);
      default:
        return const Icon(Icons.help_outline);
    }
  }

  String getLabelByType(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'house':
        return 'เจ้าของ: ${data['username'] ?? ''}';
      case 'villager':
        return 'ลูกบ้าน: ${data['first_name']} ${data['last_name']}';
      case 'car':
        return 'ทะเบียน: ${data['number']}';
      case 'animal':
        return 'สัตว์เลี้ยง: ${data['name']} (${data['type']})';
      default:
        return '';
    }
  }

  void _openHouse(int houseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HouseDetailScreen(houseId: houseId),
      ),
    );
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
                prefixIcon: const Icon(Icons.search),
                hintText: 'ค้นหาจากชื่อเจ้าของ/ลูกบ้าน/สัตว์เลี้ยง/ทะเบียนรถ',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const CircularProgressIndicator()
            else if (_results.isEmpty)
              const Text('ไม่พบข้อมูล')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    return ListTile(
                      leading: getIconByType(r['type']),
                      title: Text('บ้านเลขที่ ${r['house_id']}'),
                      subtitle: Text(getLabelByType(r)),
                      onTap: () => _openHouse(r['house_id']),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
