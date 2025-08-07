import 'package:flutter/material.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/models/house_model.dart';

import 'house_add.dart';
import 'house_detail.dart';

class LawHouseManagePage extends StatefulWidget {
  final int villageId;

  const LawHouseManagePage({super.key, required this.villageId});

  @override
  State<LawHouseManagePage> createState() => _LawHouseManagePageState();
}

class _LawHouseManagePageState extends State<LawHouseManagePage> {
  List<HouseModel> _houses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    setState(() => _loading = true);
    final houses = await HouseDomain.getAllInVillage(
      villageId: widget.villageId,
    );
    setState(() {
      _houses = houses;
      _loading = false;
    });
  }

  Future<void> _deleteHouse(int houseId) async {
    final success = await HouseDomain.delete(houseId);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบข้อมูลสำเร็จ')));
      _loadHouses();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการลูกบ้าน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HouseCreatePage()),
              );
              if (result != null) _loadHouses();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _houses.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final house = _houses[index];

                return ListTile(
                  title: Text('บ้านเลขที่: ${house.houseNumber ?? "-"}'),
                  subtitle: Text(
                    'เจ้าของ: ${house.owner ?? "-"}\nเบอร์: ${house.phone ?? "-"}',
                  ),
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HouseDetailPage(houseId: house.houseId),
                      ),
                    );
                    if (updated == true) _loadHouses();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('ลบลูกบ้าน'),
                          content: const Text('คุณต้องการลบรายการนี้หรือไม่?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('ยกเลิก'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('ลบ'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _deleteHouse(house.houseId);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
