// lib/views/juristic/house/house_detail_screen.dart

import 'package:flutter/material.dart';
import 'house_model.dart';
import 'house_service.dart';
import 'villager_model.dart';
import 'car_model.dart';
import 'animal_model.dart';

class HouseDetailScreen extends StatefulWidget {
  final int houseId;
  const HouseDetailScreen({super.key, required this.houseId});

  @override
  State<HouseDetailScreen> createState() => _HouseDetailScreenState();
}

class _HouseDetailScreenState extends State<HouseDetailScreen> {
  final HouseService service = HouseService();
  House? house;
  List<Villager> villagers = [];
  List<Car> cars = [];
  List<Animal> animals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    house = await service.getById(widget.houseId);
    villagers = await service.getVillagers(widget.houseId);
    cars = await service.getCars(widget.houseId);
    animals = await service.getAnimals(widget.houseId);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          house?.houseNumber != null
              ? 'บ้านเลขที่: ${house!.houseNumber}'
              : 'บ้านเลขที่: -',
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ผู้อยู่อาศัย', style: TextStyle(fontWeight: FontWeight.bold)),
            ...villagers.map((v) => ListTile(
              title: Text('${v.firstName} ${v.lastName}'),
              subtitle: Text('เบอร์โทร: ${v.phone ?? '-'}'),
            )),
            const Divider(),
            const Text('รถยนต์', style: TextStyle(fontWeight: FontWeight.bold)),
            ...cars.map((c) => ListTile(
              title: Text('${c.brand} ${c.model}'),
              subtitle: Text('ทะเบียน: ${c.number}'),
            )),
            const Divider(),
            const Text('สัตว์เลี้ยง', style: TextStyle(fontWeight: FontWeight.bold)),
            ...animals.map((a) => ListTile(
              title: Text('ชื่อ: ${a.name ?? '-'}'),
              subtitle: Text('ประเภท: ${a.type ?? '-'}'),
            )),
          ],
        ),
      ),
    );
  }
}
