import 'package:flutter/material.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/models/animal_model.dart';
import 'package:fullproject/models/vehicle_model.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/domains/animal_domain.dart';
import 'package:fullproject/domains/vehicle_domain.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/theme/Color.dart';
import 'house_edit.dart';
import 'animal_edit.dart';
import 'animal_add.dart';
import 'vehicle_edit.dart';
import 'vehicle_add.dart';

class HouseDetailPage extends StatefulWidget {
  final int houseId;
  const HouseDetailPage({super.key, required this.houseId});

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage>
    with SingleTickerProviderStateMixin {
  HouseModel? house;
  List<AnimalModel> animals = [];
  List<VehicleModel> vehicles = [];
  bool loading = true;
  bool animalsLoading = false;
  bool vehiclesLoading = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadHouseData();

    // เมื่อเปลี่ยน tab ให้โหลดข้อมูลตาม tab
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 1: // Animal tab
            if (animals.isEmpty && !animalsLoading) {
              loadAnimals();
            }
            break;
          case 2: // Vehicle tab
            if (vehicles.isEmpty && !vehiclesLoading) {
              loadVehicles();
            }
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadHouseData() async {
    final result = await HouseDomain.getById(widget.houseId);
    if (mounted) {
      setState(() {
        house = result;
        loading = false;
      });
    }
  }

  Future<void> loadAnimals() async {
    setState(() => animalsLoading = true);
    try {
      final result = await AnimalDomain.getByHouse(houseId: widget.houseId);
      if (mounted) {
        setState(() {
          animals = result;
          animalsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => animalsLoading = false);
      }
    }
  }

  Future<void> loadVehicles() async {
    setState(() => vehiclesLoading = true);
    try {
      final result = await VehicleDomain.getByHouse(houseId: widget.houseId);
      if (mounted) {
        setState(() {
          vehicles = result;
          vehiclesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => vehiclesLoading = false);
      }
    }
  }

  Future<void> refreshAllData() async {
    await Future.wait([
      loadHouseData(),
      loadAnimals(),
      loadVehicles(),
    ]);
  }

  // Navigation to Add Pages
  Future<void> _navigateToAnimalAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimalAddPage(houseId: widget.houseId),
      ),
    );

    // Refresh animals data when returning
    if (result == true && mounted) {
      loadAnimals();
    }
  }

  Future<void> _navigateToVehicleAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleAddPage(houseId: widget.houseId),
      ),
    );

    // Refresh vehicles data when returning
    if (result == true && mounted) {
      loadVehicles();
    }
  }

  // Navigation methods for Single Edit Pages
  Future<void> _navigateToAnimalEdit({AnimalModel? animal}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimalEditSinglePage(
          houseId: widget.houseId,
          animal: animal,
        ),
      ),
    );

    // Refresh animals data when returning
    if (result == true && mounted) {
      loadAnimals();
    }
  }

  Future<void> _navigateToVehicleEdit({required VehicleModel vehicle}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleEditPage(
          vehicle: vehicle,
        ),
      ),
    );

    // Refresh vehicles data when returning
    if (result == true && mounted) {
      loadVehicles();
    }
  }

  // Quick delete methods
  Future<void> _deleteAnimal(AnimalModel animal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: ThemeColors.ivoryWhite,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ThemeColors.warningAmber, size: 28),
            const SizedBox(width: 12),
            Text(
              'ยืนยันการลบ',
              style: TextStyle(color: ThemeColors.darkChocolate),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณแน่ใจหรือไม่ว่าต้องการลบ',
              style: TextStyle(color: ThemeColors.darkChocolate),
            ),
            Text(
              animal.name ?? 'สัตว์เลี้ยง',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ThemeColors.softBrown,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors.softBrown,
            ),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.errorRust,
              foregroundColor: ThemeColors.ivoryWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AnimalDomain.delete(animal.animalId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบ ${animal.name ?? 'สัตว์เลี้ยง'} สำเร็จ'),
              backgroundColor: ThemeColors.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          loadAnimals();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('เกิดข้อผิดพลาดในการลบ'),
              backgroundColor: ThemeColors.errorRust,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteVehicle(VehicleModel vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: ThemeColors.ivoryWhite,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ThemeColors.warningAmber, size: 28),
            const SizedBox(width: 12),
            Text(
              'ยืนยันการลบ',
              style: TextStyle(color: ThemeColors.darkChocolate),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณแน่ใจหรือไม่ว่าต้องการลบ',
              style: TextStyle(color: ThemeColors.darkChocolate),
            ),
            Text(
              '${vehicle.brand ?? ''} ${vehicle.model ?? ''}'.trim(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ThemeColors.softBrown,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors.softBrown,
            ),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.errorRust,
              foregroundColor: ThemeColors.ivoryWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await VehicleDomain.delete(vehicle.vehicleId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบ ${vehicle.brand ?? ''} ${vehicle.model ?? ''} สำเร็จ'),
              backgroundColor: ThemeColors.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          loadVehicles();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('เกิดข้อผิดพลาดในการลบ'),
              backgroundColor: ThemeColors.errorRust,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.creamWhite,
      appBar: AppBar(
        title: Text(
          'บ้านเลขที่ ${house?.houseNumber ?? widget.houseId}',
          style: TextStyle(
            color: ThemeColors.darkChocolate,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ThemeColors.ivoryWhite,
        foregroundColor: ThemeColors.darkChocolate,
        elevation: 2,
        shadowColor: ThemeColors.sandyTan.withValues(alpha: 0.3),
        actions: [
          if (house != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditHousePage(
                        villageId: house!.villageId,
                        house: house,
                      ),
                    ),
                  );

                  if (!mounted) return;
                  if (result is HouseModel) {
                    setState(() => house = result);
                  } else if (result == true) {
                    await loadHouseData();
                  }
                },
                icon: Icon(Icons.edit, size: 18, color: ThemeColors.softBrown),
                label: Text(
                  'แก้ไข',
                  style: TextStyle(color: ThemeColors.softBrown),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: ThemeColors.lightTaupe,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
        ],
        bottom: loading
            ? null
            : TabBar(
          controller: _tabController,
          labelColor: ThemeColors.softBrown,
          unselectedLabelColor: ThemeColors.dustyBrown,
          indicatorColor: ThemeColors.softBrown,
          indicatorWeight: 3,
          tabs: [
            const Tab(
              icon: Icon(Icons.home),
              text: 'ข้อมูลบ้าน',
            ),
            Tab(
              icon: const Icon(Icons.pets),
              text: 'สัตว์เลี้ยง${animals.isNotEmpty ? ' (${animals.length})' : ''}',
            ),
            Tab(
              icon: const Icon(Icons.directions_car),
              text: 'ยานพาหนะ${vehicles.isNotEmpty ? ' (${vehicles.length})' : ''}',
            ),
          ],
        ),
      ),
      body: loading
          ? Center(
        child: CircularProgressIndicator(
          color: ThemeColors.softBrown,
        ),
      )
          : house == null
          ? Center(
        child: Text(
          'ไม่พบข้อมูล',
          style: TextStyle(color: ThemeColors.dustyBrown),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          // House Info Tab
          _buildHouseInfoTab(),
          // Animals Tab
          _buildAnimalsTab(),
          // Vehicles Tab
          _buildVehiclesTab(),
        ],
      ),
    );
  }

  Widget _buildHouseInfoTab() {
    return RefreshIndicator(
      color: ThemeColors.softBrown,
      backgroundColor: ThemeColors.ivoryWhite,
      onRefresh: loadHouseData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // House Image
            if (house!.img != null && house!.img!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.sandyTan.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BuildImage(
                    imagePath: house!.img!,
                    tablePath: 'house',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ThemeColors.beige, ThemeColors.lightTaupe],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_outlined,
                              size: 48,
                              color: ThemeColors.dustyBrown,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ไม่สามารถโหลดรูปภาพได้',
                              style: TextStyle(color: ThemeColors.dustyBrown),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // House Details
            _buildDetailCard('ข้อมูลพื้นฐาน', Icons.info_outline, [
              _buildDetailRow('บ้านเลขที่', house!.houseNumber),
              _buildDetailRow('เจ้าของ', house!.owner),
              _buildDetailRow('เบอร์โทร', house!.phone),
              _buildDetailRow('สถานะ', house!.status),
            ]),

            const SizedBox(height: 16),

            _buildDetailCard('รายละเอียดบ้าน', Icons.home_work, [
              _buildDetailRow('ประเภทบ้าน', house!.houseType),
              _buildDetailRow('จำนวนชั้น', house!.floors?.toString()),
              _buildDetailRow('ขนาด', house!.size),
              _buildDetailRow('พื้นที่ใช้สอย', house!.usableArea),
              _buildDetailRow('สถานะการใช้งาน', house!.usageStatus),
            ]),

            const SizedBox(height: 24),

            // ปุ่มแก้ไขข้อมูลบ้าน
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditHousePage(
                        villageId: house!.villageId,
                        house: house,
                      ),
                    ),
                  );

                  if (!mounted) return;
                  if (result is HouseModel) {
                    setState(() => house = result);
                  } else if (result == true) {
                    await loadHouseData();
                  }
                },
                icon: const Icon(Icons.edit, size: 20),
                label: const Text(
                  'แก้ไขข้อมูลบ้าน',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.softBrown,
                  foregroundColor: ThemeColors.ivoryWhite,
                  elevation: 4,
                  shadowColor: ThemeColors.softBrown.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalsTab() {
    return Column(
      children: [
        // Header with statistics and add button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeColors.ivoryWhite,
            boxShadow: [
              BoxShadow(
                color: ThemeColors.sandyTan.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สัตว์เลี้ยงทั้งหมด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.darkChocolate,
                      ),
                    ),
                    Text(
                      '${animals.length} รายการ',
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeColors.dustyBrown,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _navigateToAnimalAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มข้อมูล'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.sageGreen,
                  foregroundColor: ThemeColors.ivoryWhite,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Animals content
        Expanded(
          child: animalsLoading
              ? Center(
            child: CircularProgressIndicator(
              color: ThemeColors.softBrown,
            ),
          )
              : animals.isEmpty
              ? _buildEmptyAnimalsState()
              : RefreshIndicator(
            color: ThemeColors.softBrown,
            backgroundColor: ThemeColors.ivoryWhite,
            onRefresh: loadAnimals,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: animals.length,
              itemBuilder: (context, index) {
                final animal = animals[index];
                return _buildAnimalCard(animal);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehiclesTab() {
    return Column(
      children: [
        // Header with statistics and add button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeColors.ivoryWhite,
            boxShadow: [
              BoxShadow(
                color: ThemeColors.sandyTan.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยานพาหนะทั้งหมด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.darkChocolate,
                      ),
                    ),
                    Text(
                      '${vehicles.length} คัน',
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeColors.dustyBrown,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _navigateToVehicleAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มข้อมูล'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.infoBlue,
                  foregroundColor: ThemeColors.ivoryWhite,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Vehicles content
        Expanded(
          child: vehiclesLoading
              ? Center(
            child: CircularProgressIndicator(
              color: ThemeColors.softBrown,
            ),
          )
              : vehicles.isEmpty
              ? _buildEmptyVehiclesState()
              : RefreshIndicator(
            color: ThemeColors.softBrown,
            backgroundColor: ThemeColors.ivoryWhite,
            onRefresh: loadVehicles,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _buildVehicleCard(vehicle);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAnimalsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ThemeColors.lightTaupe,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.sandyTan.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.pets_outlined,
              size: 64,
              color: ThemeColors.dustyBrown,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'ไม่มีสัตว์เลี้ยงในบ้านนี้',
            style: TextStyle(
              fontSize: 18,
              color: ThemeColors.darkChocolate,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่ม "เพิ่มข้อมูล" เพื่อเพิ่มสัตว์เลี้ยง',
            style: TextStyle(
              fontSize: 14,
              color: ThemeColors.dustyBrown,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAnimalAdd,
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มสัตว์เลี้ยง'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.sageGreen,
              foregroundColor: ThemeColors.ivoryWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 4,
              shadowColor: ThemeColors.sageGreen.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVehiclesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ThemeColors.lightTaupe,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.sandyTan.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: ThemeColors.dustyBrown,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'ไม่มียานพาหนะในบ้านนี้',
            style: TextStyle(
              fontSize: 18,
              color: ThemeColors.darkChocolate,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่ม "เพิ่มข้อมูล" เพื่อเพิ่มยานพาหนะ',
            style: TextStyle(
              fontSize: 14,
              color: ThemeColors.dustyBrown,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToVehicleAdd,
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มยานพาหนะ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.infoBlue,
              foregroundColor: ThemeColors.ivoryWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 4,
              shadowColor: ThemeColors.infoBlue.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      shadowColor: ThemeColors.sandyTan.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: ThemeColors.ivoryWhite,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.lightTaupe,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: ThemeColors.softBrown, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: ThemeColors.dustyBrown,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                fontSize: 16,
                color: ThemeColors.darkChocolate,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(AnimalModel animal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: ThemeColors.sandyTan.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: ThemeColors.ivoryWhite,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Animal Image/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getAnimalTypeColor(animal.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getAnimalTypeColor(animal.type).withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getAnimalTypeColor(animal.type).withValues(alpha: 0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: animal.img != null && animal.img!.isNotEmpty
                    ? BuildImage(
                  imagePath: animal.img!,
                  tablePath: 'animal',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getAnimalTypeColor(animal.type).withValues(alpha: 0.7),
                          _getAnimalTypeColor(animal.type).withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getAnimalIcon(animal.type),
                      size: 36,
                      color: ThemeColors.ivoryWhite,
                    ),
                  ),
                )
                    : Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getAnimalTypeColor(animal.type).withValues(alpha: 0.7),
                        _getAnimalTypeColor(animal.type).withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getAnimalIcon(animal.type),
                    size: 36,
                    color: ThemeColors.ivoryWhite,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Animal Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name ?? 'ไม่มีชื่อ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.darkChocolate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getAnimalTypeColor(animal.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getAnimalTypeColor(animal.type).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getAnimalIcon(animal.type),
                          size: 16,
                          color: _getAnimalTypeColor(animal.type),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          animal.type ?? 'ไม่ระบุประเภท',
                          style: TextStyle(
                            color: _getAnimalTypeColor(animal.type),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${animal.animalId}',
                    style: TextStyle(
                      color: ThemeColors.dustyBrown,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.lightTaupe,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThemeColors.softBrown.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit, color: ThemeColors.softBrown, size: 22),
                    onPressed: () => _navigateToAnimalEdit(animal: animal),
                    tooltip: 'แก้ไข',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.errorRust.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThemeColors.errorRust.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: ThemeColors.errorRust, size: 22),
                    onPressed: () => _deleteAnimal(animal),
                    tooltip: 'ลบ',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: ThemeColors.sandyTan.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: ThemeColors.ivoryWhite,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Vehicle Image/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ThemeColors.infoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeColors.infoBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.infoBlue.withValues(alpha: 0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: vehicle.img != null && vehicle.img!.isNotEmpty
                    ? BuildImage(
                  imagePath: vehicle.img!,
                  tablePath: 'vehicle',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ThemeColors.infoBlue.withValues(alpha: 0.7),
                          ThemeColors.infoBlue.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      size: 36,
                      color: ThemeColors.ivoryWhite,
                    ),
                  ),
                )
                    : Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ThemeColors.infoBlue.withValues(alpha: 0.7),
                        ThemeColors.infoBlue.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    size: 36,
                    color: ThemeColors.ivoryWhite,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Vehicle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.brand ?? ''} ${vehicle.model ?? ''}'.trim().isEmpty
                        ? 'ไม่มีข้อมูลรถ'
                        : '${vehicle.brand ?? ''} ${vehicle.model ?? ''}'.trim(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.darkChocolate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (vehicle.number != null && vehicle.number!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ThemeColors.goldenHoney.withValues(alpha: 0.2),
                            ThemeColors.wheatGold.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ThemeColors.goldenHoney.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeColors.goldenHoney.withValues(alpha: 0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            size: 16,
                            color: ThemeColors.goldenHoney,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vehicle.number!,
                            style: TextStyle(
                              color: ThemeColors.darkChocolate,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ThemeColors.lightTaupe,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ThemeColors.dustyBrown.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 16,
                            color: ThemeColors.dustyBrown,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ไม่มีทะเบียน',
                            style: TextStyle(
                              color: ThemeColors.dustyBrown,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${vehicle.vehicleId}',
                    style: TextStyle(
                      color: ThemeColors.dustyBrown,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.lightTaupe,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThemeColors.softBrown.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit, color: ThemeColors.softBrown, size: 22),
                    onPressed: () => _navigateToVehicleEdit(vehicle: vehicle),
                    tooltip: 'แก้ไข',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: ThemeColors.errorRust.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThemeColors.errorRust.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: ThemeColors.errorRust, size: 22),
                    onPressed: () => _deleteVehicle(vehicle),
                    tooltip: 'ลบ',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAnimalIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'dog':
      case 'สุนัข':
        return Icons.pets;
      case 'cat':
      case 'แมว':
        return Icons.pets;
      case 'bird':
      case 'นก':
        return Icons.flutter_dash;
      case 'fish':
      case 'ปลา':
        return Icons.set_meal;
      case 'rabbit':
      case 'กระต่าย':
        return Icons.cruelty_free;
      case 'หนู':
        return Icons.mouse;
      default:
        return Icons.pets;
    }
  }

  Color _getAnimalTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'dog':
      case 'สุนัข':
        return ThemeColors.softBrown;
      case 'cat':
      case 'แมว':
        return ThemeColors.burntOrange;
      case 'bird':
      case 'นก':
        return ThemeColors.infoBlue;
      case 'fish':
      case 'ปลา':
        return ThemeColors.sageGreen;
      case 'rabbit':
      case 'กระต่าย':
        return ThemeColors.apricot;
      case 'หนู':
        return ThemeColors.dustyBrown;
      case 'อื่นๆ':
        return ThemeColors.rustOrange;
      default:
        return ThemeColors.mushroom;
    }
  }
}