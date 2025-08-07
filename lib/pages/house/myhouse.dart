import 'package:flutter/material.dart';
import 'package:fullproject/pages/house/house_detail/animal.dart';
import 'package:fullproject/pages/house/house_detail/house.dart';
import 'package:fullproject/pages/house/house_detail/vehicle.dart';
import 'package:fullproject/pages/house/house_detail/village.dart';

class HouseMyHousePage extends StatefulWidget {
  final int? houseId;

  const HouseMyHousePage({super.key, this.houseId});

  @override
  State<HouseMyHousePage> createState() => _HouseMyHousePageState();
}

class _HouseMyHousePageState extends State<HouseMyHousePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.home), text: 'ข้อมูลบ้าน'),
              Tab(icon: Icon(Icons.holiday_village_outlined), text: 'หมู่บ้าน'),
              Tab(icon: Icon(Icons.settings), text: 'สัตว์เลี้ยง'),
              Tab(icon: Icon(Icons.person), text: 'ยานพาหนะ'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                HouseDetailPage(houseId: widget.houseId),
                HouseVillageDetailPage(houseId: widget.houseId),
                HouseAnimalDetailPage(houseId: widget.houseId),
                HouseVehicleDetailPage(houseId: widget.houseId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
