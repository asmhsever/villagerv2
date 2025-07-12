// 📁 lib/views/juristic/fees/fees_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fees_by_house_screen.dart';
import 'package:intl/intl.dart';

class JuristicFeesScreen extends StatefulWidget {
  final int villageId;
  const JuristicFeesScreen({super.key, required this.villageId});

  @override
  State<JuristicFeesScreen> createState() => _JuristicFeesScreenState();
}

class _JuristicFeesScreenState extends State<JuristicFeesScreen> {
  List<Map<String, dynamic>> _houses = [];
  List<Map<String, dynamic>> _filteredHouses = [];
  bool _loading = true;
  bool _showUnpaidOnly = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGroupedHouses();
  }

  Future<void> _loadGroupedHouses() async {
    final client = Supabase.instance.client;
    try {
      final data = await client
          .from('bill_area')
          .select('house_id, amount, paid_status, house(house_number)')
          .eq('house.village_id', widget.villageId);

      final List<Map<String, dynamic>> bills = List<Map<String, dynamic>>.from(data);
      final Map<int, Map<String, dynamic>> grouped = {};

      for (var bill in bills) {
        final house = bill['house'];
        if (house == null) continue;

        final houseId = bill['house_id'];
        final houseNumber = house['house_number'] ?? '-';
        final unpaid = bill['paid_status'] == 0 ? 1 : 0;
        final amount = bill['amount'] ?? 0;

        if (!grouped.containsKey(houseId)) {
          grouped[houseId] = {
            'house_id': houseId,
            'house_number': houseNumber,
            'total_unpaid': unpaid,
            'total_amount': unpaid == 1 ? amount : 0,
          };
        } else {
          grouped[houseId]!['total_unpaid'] += unpaid;
          grouped[houseId]!['total_amount'] += unpaid == 1 ? amount : 0;
        }
      }

      _houses = grouped.values.toList();
      _applyFilter();
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('❌ loadGroupedHouses error: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredHouses = _houses.where((h) {
        final hn = h['house_number']?.toString().toLowerCase() ?? '';
        final matchesSearch = hn.contains(query);
        final matchesUnpaid = !_showUnpaidOnly || h['total_unpaid'] > 0;
        return matchesSearch && matchesUnpaid;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'th_TH');

    return Scaffold(
      appBar: AppBar(title: const Text('บ้านที่มีค่าส่วนกลาง')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาบ้านเลขที่',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => _applyFilter(),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('แสดงเฉพาะที่ยังไม่จ่าย'),
                  selected: _showUnpaidOnly,
                  onSelected: (v) {
                    setState(() => _showUnpaidOnly = v);
                    _applyFilter();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _filteredHouses.length,
              itemBuilder: (_, i) {
                final house = _filteredHouses[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('บ้านเลขที่: ${house['house_number']}'),
                    subtitle: Text('ยอดค้าง: ${fmt.format(house['total_amount'])} บาท\nยังไม่จ่าย: ${house['total_unpaid']} บิล'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeesByHouseScreen(houseId: house['house_id']),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
