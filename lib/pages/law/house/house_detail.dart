import 'package:flutter/material.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/models/animal_model.dart';
import 'package:fullproject/models/vehicle_model.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/domains/animal_domain.dart';
import 'package:fullproject/domains/vehicle_domain.dart';
import 'package:fullproject/services/image_service.dart';
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

  // Navigation methods for Single Edit Pages (แก้ไข/เพิ่มทีละรายการ)
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
          vehicle: vehicle, // ส่งเฉพาะ vehicle เท่านั้น
        ),
      ),
    );



  }

  // Quick delete methods
  Future<void> _deleteAnimal(AnimalModel animal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 28),
            const SizedBox(width: 12),
            const Text('ยืนยันการลบ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('คุณแน่ใจหรือไม่ว่าต้องการลบ'),
            Text(
              animal.name ?? 'สัตว์เลี้ยง',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          loadAnimals();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบ'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
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
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 28),
            const SizedBox(width: 12),
            const Text('ยืนยันการลบ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('คุณแน่ใจหรือไม่ว่าต้องการลบ'),
            Text(
              '${vehicle.brand ?? ''} ${vehicle.model ?? ''}'.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          loadVehicles();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบ'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('บ้านเลขที่ ${house?.houseNumber ?? widget.houseId}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          // เปลี่ยนปุ่ม edit house ให้ง่ายขึ้น
          if (house != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditHousePage(house: house!),
                    ),
                  );

                  if (result is HouseModel && mounted) {
                    setState(() => house = result);
                  }
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('แก้ไข'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
        ],
        bottom: loading
            ? null
            : TabBar(
          controller: _tabController,
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
          ? const Center(child: CircularProgressIndicator())
          : house == null
          ? const Center(child: Text('ไม่พบข้อมูล'))
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
      // ลบ FloatingActionButton ออก
      // floatingActionButton: loading ? null : _buildFloatingActionButton(),
    );
  }

  Widget _buildHouseInfoTab() {
    return RefreshIndicator(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BuildImage(
                    imagePath: house!.img!,
                    tablePath: 'house',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('ไม่สามารถโหลดรูปภาพได้'),
                      ),
                    ),
                  ),
                ),
              ),

            // House Details
            _buildDetailCard('ข้อมูลพื้นฐาน', [
              _buildDetailRow('บ้านเลขที่', house!.houseNumber),
              _buildDetailRow('เจ้าของ', house!.owner),
              _buildDetailRow('เบอร์โทร', house!.phone),
              _buildDetailRow('สถานะ', house!.status),
            ]),

            const SizedBox(height: 16),

            _buildDetailCard('รายละเอียดบ้าน', [
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
                      builder: (_) => EditHousePage(house: house!),
                    ),
                  );

                  if (result is HouseModel && mounted) {
                    setState(() => house = result);
                  }
                },
                icon: const Icon(Icons.edit, size: 20),
                label: const Text(
                  'แก้ไขข้อมูลบ้าน',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.blue.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
          color: Colors.white,
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
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '${animals.length} รายการ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // เปลี่ยนเป็นปุ่มเพิ่มข้อมูล
              ElevatedButton.icon(
                onPressed: _navigateToAnimalAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มข้อมูล'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Animals content
        Expanded(
          child: animalsLoading
              ? const Center(child: CircularProgressIndicator())
              : animals.isEmpty
              ? _buildEmptyAnimalsState()
              : RefreshIndicator(
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
          color: Colors.white,
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
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '${vehicles.length} คัน',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // เปลี่ยนเป็นปุ่มเพิ่มข้อมูล
              ElevatedButton.icon(
                onPressed: _navigateToVehicleAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มข้อมูล'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Vehicles content
        Expanded(
          child: vehiclesLoading
              ? const Center(child: CircularProgressIndicator())
              : vehicles.isEmpty
              ? _buildEmptyVehiclesState()
              : RefreshIndicator(
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
          Icon(Icons.pets_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'ไม่มีสัตว์เลี้ยงในบ้านนี้',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่ม "เพิ่มข้อมูล" เพื่อเพิ่มสัตว์เลี้ยง',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAnimalAdd,
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มสัตว์เลี้ยง'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'ไม่มียานพาหนะในบ้านนี้',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่ม "เพิ่มข้อมูล" เพื่อเพิ่มยานพาหนะ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToVehicleAdd,
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มยานพาหนะ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(AnimalModel animal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Animal Image/Icon - ขนาดใหญ่ขึ้น
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
                      color: Colors.white,
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
                    color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  const SizedBox(height: 6),
                  Text(
                    'ID: ${animal.animalId}',
                    style: TextStyle(
                      color: Colors.grey[500],
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
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                    onPressed: () => _navigateToAnimalEdit(animal: animal),
                    tooltip: 'แก้ไข',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Vehicle Image/Icon - ขนาดใหญ่ขึ้น
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 2,
                ),
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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1976D2),
                          Color(0xFF1565C0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                )
                    : Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1976D2),
                        Color(0xFF1565C0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 36,
                    color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (vehicle.number != null && vehicle.number!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber[100]!,
                            Colors.amber[50]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.2),
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
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vehicle.number!,
                            style: TextStyle(
                              color: Colors.amber[800],
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
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ไม่มีทะเบียน',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'ID: ${vehicle.vehicleId}',
                    style: TextStyle(
                      color: Colors.grey[500],
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
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                    onPressed: () => _navigateToVehicleEdit(vehicle: vehicle),
                    tooltip: 'แก้ไข',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
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
      default:
        return Icons.pets;
    }
  }

  Color _getAnimalTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'dog':
      case 'สุนัข':
        return Colors.brown;
      case 'cat':
      case 'แมว':
        return Colors.purple;
      case 'bird':
      case 'นก':
        return Colors.blue;
      case 'fish':
      case 'ปลา':
        return Colors.cyan;
      case 'rabbit':
      case 'กระต่าย':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}