import 'package:flutter/material.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/pages/house/house_detail/animal/animal.dart';
import 'package:fullproject/pages/house/house_detail/house.dart';
import 'package:fullproject/pages/house/house_detail/vehicle/vehicle.dart';
import 'package:fullproject/pages/house/house_detail/village/village.dart';
import 'package:fullproject/pages/house/widgets/appbar.dart';
import 'package:fullproject/theme/Color.dart';

class HouseMyHousePage extends StatefulWidget {
  final HouseModel? houseData;

  const HouseMyHousePage({super.key, this.houseData});

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
      appBar: HouseAppBar(house: widget.houseData?.houseNumber),
      backgroundColor: ThemeColors.ivoryWhite, // Ivory White background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ThemeColors.ivoryWhite, // Ivory White
              ThemeColors.beige, // Beige
            ],
          ),
        ),
        child: Column(
          children: [
            // Custom TabBar with themed styling
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeColors.inputFill, // Input Fill
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.softBorder.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: ThemeColors.softBorder, // Soft Border
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
                      color: ThemeColors.clickHighlight.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: ThemeColors.ivoryWhite,
                // Ivory White
                unselectedLabelColor: ThemeColors.softBrown,
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
                  color: ThemeColors.ivoryWhite, // Ivory White
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.earthClay.withOpacity(0.2),
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
                      HouseDetailPage(houseId: widget.houseData?.houseId),
                      HouseVillageDetailPage(
                        houseId: widget.houseData?.houseId,
                      ),
                      HouseAnimalDetailPage(houseId: widget.houseData?.houseId),
                      HouseVehicleDetailPage(
                        houseId: widget.houseData?.houseId,
                      ),
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
