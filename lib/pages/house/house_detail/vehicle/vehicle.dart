import 'package:flutter/material.dart';
import 'package:fullproject/domains/vehicle_domain.dart';
import 'package:fullproject/pages/house/house_detail/vehicle/vehicle_add.dart';
import 'package:fullproject/pages/house/house_detail/vehicle/vehicle_edit.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/theme/Color.dart';

class HouseVehicleDetailPage extends StatefulWidget {
  final int? houseId;

  const HouseVehicleDetailPage({super.key, this.houseId});

  @override
  State<HouseVehicleDetailPage> createState() => _HouseVehicleDetailPageState();
}

class _HouseVehicleDetailPageState extends State<HouseVehicleDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // เพิ่ม key สำหรับ FutureBuilder เพื่อให้ rebuild ได้
  Key _futureBuilderKey = UniqueKey();

  // Theme Colors

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addVehicle({required int houseId}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseAddVehiclePage(houseId: houseId),
      ),
    );

    // ถ้า result เป็น true ให้ refresh page
    if (result == true) {
      _refreshPage();
    }
  }

  void _editVehicle(dynamic vehicleId) async {
    // TODO: Navigate to edit vehicle page และรอรับ result

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseVehicleEditPage(vehicle: vehicleId!),
      ),
    );

    // ถ้า result เป็น true ให้ refresh page
    if (result == true) {
      _refreshPage();
    }

    // ชั่วคราวแสดง SnackBar (ลบออกเมื่อมีหน้าแก้ไขแล้ว)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('แก้ไขรถยนต์ ID: $vehicleId'),
        backgroundColor: ThemeColors.burntOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ฟังก์ชันสำหรับ refresh page
  void _refreshPage() {
    setState(() {
      _futureBuilderKey =
          UniqueKey(); // สร้าง key ใหม่เพื่อให้ FutureBuilder rebuild
      _animationController.reset(); // รีเซ็ต animation
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.beige,
      body: Column(
        children: [
          // Header Section
          _buildHeaderSection(),

          // Content
          Expanded(
            child: FutureBuilder(
              key: _futureBuilderKey, // ใช้ key เพื่อให้ rebuild ได้
              future: VehicleDomain.getByHouse(houseId: widget.houseId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final vehicles = snapshot.data!;
                _animationController.forward();

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildVehicleList(vehicles),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAddVehicleFAB(),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeColors.softBrown.withOpacity(0.1),
            ThemeColors.burntOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeColors.burntOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.directions_car_rounded,
                color: ThemeColors.burntOrange,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รถยนต์ประจำบ้าน',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.softBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'บ้านเลขที่ ${widget.houseId}',
                    style: TextStyle(
                      fontSize: 16,
                      color: ThemeColors.earthClay,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: ThemeColors.ivoryWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.earthClay.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'กำลังโหลดข้อมูลรถยนต์...',
              style: TextStyle(
                color: ThemeColors.earthClay,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeColors.ivoryWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.earthClay.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeColors.clayOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: ThemeColors.clayOrange,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeColors.softBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: ThemeColors.earthClay, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshPage, // เปลี่ยนเป็นใช้ _refreshPage
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.burntOrange,
                foregroundColor: ThemeColors.ivoryWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: ThemeColors.ivoryWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.earthClay.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeColors.warmStone.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 64,
                color: ThemeColors.warmStone,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ไม่พบรถยนต์',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeColors.softBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ยังไม่มีรถยนต์ลงทะเบียนในบ้านหมายเลข ${widget.houseId}',
              textAlign: TextAlign.center,
              style: TextStyle(color: ThemeColors.earthClay, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _addVehicle(houseId: widget.houseId!),
              // แก้ไขให้เรียกฟังก์ชันถูกต้อง
              icon: const Icon(Icons.add_rounded),
              label: const Text('เพิ่มรถยนต์'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.oliveGreen,
                foregroundColor: ThemeColors.ivoryWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList(List vehicles) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(0.3, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 1.0),
                    ((index + 1) * 0.1).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
          child: _buildVehicleCard(vehicle, index),
        );
      },
    );
  }

  Widget _buildVehicleCard(dynamic vehicle, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Vehicle Image Container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ThemeColors.sandyTan, ThemeColors.beige],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeColors.earthClay.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: vehicle.img != null && vehicle.img != "null"
                      ? BuildImage(imagePath: vehicle.img, tablePath: "vehicle")
                      : Icon(
                          Icons.directions_car_rounded,
                          size: 40,
                          color: ThemeColors.earthClay,
                        ),
                ),

                const SizedBox(width: 20),

                // Vehicle Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand & Model
                      Text(
                        '${vehicle.brand} ${vehicle.model}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.softBrown,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // License Plate
                      _buildInfoChip(
                        Icons.confirmation_number_rounded,
                        vehicle.number.toString(),
                        ThemeColors.burntOrange,
                      ),
                      const SizedBox(height: 6),

                      // House ID
                      _buildInfoChip(
                        Icons.home_rounded,
                        'บ้านเลขที่ ${vehicle.houseId}',
                        ThemeColors.oliveGreen,
                      ),
                    ],
                  ),
                ),

                // Actions Column
                Column(
                  children: [
                    // Vehicle ID Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeColors.softTerracotta.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ThemeColors.softTerracotta.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'ID: ${vehicle.vehicleId}',
                        style: TextStyle(
                          fontSize: 11,
                          color: ThemeColors.softTerracotta,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Edit Button
                    Container(
                      decoration: BoxDecoration(
                        color: ThemeColors.clayOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => _editVehicle(vehicle),
                        icon: Icon(
                          Icons.edit_rounded,
                          color: ThemeColors.clayOrange,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: ThemeColors.earthClay,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddVehicleFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ThemeColors.oliveGreen, ThemeColors.softTerracotta],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.oliveGreen.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _addVehicle(houseId: widget.houseId!),
        backgroundColor: ThemeColors.burntOrange,
        foregroundColor: ThemeColors.ivoryWhite,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: ThemeColors.ivoryWhite),
        label: Text(
          'เพิ่มรถยนต์',
          style: TextStyle(
            color: ThemeColors.ivoryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
