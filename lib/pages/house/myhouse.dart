import 'package:flutter/material.dart';
import 'package:fullproject/pages/house/house_detail/animal/animal.dart';
import 'package:fullproject/pages/house/house_detail/house.dart';
import 'package:fullproject/pages/house/house_detail/vehicle/vehicle.dart';
import 'package:fullproject/pages/house/house_detail/village/village.dart';

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
      backgroundColor: const Color(0xFFFFFDF6), // Ivory White background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF6), // Ivory White
              Color(0xFFF5F0E1), // Beige
            ],
          ),
        ),
        child: Column(
          children: [
            // Custom TabBar with themed styling
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F3), // Input Fill
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD0C4B0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFD0C4B0), // Soft Border
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFDB8142), // Softer Burnt Orange
                      Color(0xFFDA9856), // Warm Amber
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC7633).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: const Color(0xFFFFFDF6),
                // Ivory White
                unselectedLabelColor: const Color(0xFFA47551),
                // Soft Brown
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  _buildCustomTab(icon: Icons.home_rounded, text: 'ข้อมูลบ้าน'),
                  _buildCustomTab(
                    icon: Icons.holiday_village_outlined,
                    text: 'หมู่บ้าน',
                  ),
                  _buildCustomTab(
                    icon: Icons.pets_rounded,
                    text: 'สัตว์เลี้ยง',
                  ),
                  _buildCustomTab(
                    icon: Icons.directions_car_rounded,
                    text: 'ยานพาหนะ',
                  ),
                ],
              ),
            ),

            // TabBar Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF6), // Ivory White
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBFA18F).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTab({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
