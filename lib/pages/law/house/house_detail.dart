import 'package:flutter/material.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/models/animal_model.dart';
import 'package:fullproject/models/vehicle_model.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/domains/animal_domain.dart';
import 'package:fullproject/domains/vehicle_domain.dart';
import 'package:fullproject/services/image_service.dart';
import 'house_edit.dart';

class HouseDetailPage extends StatefulWidget {
  final int houseId;
  const HouseDetailPage({super.key, required this.houseId});

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('บ้านเลขที่ ${house?.houseNumber ?? widget.houseId}'),
        actions: [
          if (house != null)
            IconButton(
              icon: const Icon(Icons.edit),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalsTab() {
    if (animalsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (animals.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadAnimals,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'ไม่มีสัตว์เลี้ยงในบ้านนี้',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'ดึงลงเพื่อรีเฟรช',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadAnimals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: animals.length,
        itemBuilder: (context, index) {
          final animal = animals[index];
          return _buildAnimalCard(animal);
        },
      ),
    );
  }

  Widget _buildVehiclesTab() {
    if (vehiclesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehicles.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadVehicles,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'ไม่มียานพาหนะในบ้านนี้',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'ดึงลงเพื่อรีเฟรช',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadVehicles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          return _buildVehicleCard(vehicle);
        },
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Animal Image/Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getAnimalTypeColor(animal.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: animal.img != null && animal.img!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BuildImage(
                  imagePath: animal.img!,
                  tablePath: 'animal',
                  fit: BoxFit.cover,
                  errorWidget: Icon(
                    _getAnimalIcon(animal.type),
                    size: 30,
                    color: _getAnimalTypeColor(animal.type),
                  ),
                ),
              )
                  : Icon(
                _getAnimalIcon(animal.type),
                size: 30,
                color: _getAnimalTypeColor(animal.type),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getAnimalIcon(animal.type),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        animal.type ?? 'ไม่ระบุประเภท',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Animal ID Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getAnimalTypeColor(animal.type),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ID: ${animal.animalId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Vehicle Image/Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: vehicle.img != null && vehicle.img!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BuildImage(
                  imagePath: vehicle.img!,
                  tablePath: 'vehicle',
                  fit: BoxFit.cover,
                  errorWidget: const Icon(
                    Icons.directions_car,
                    size: 30,
                    color: Colors.blue,
                  ),
                ),
              )
                  : const Icon(
                Icons.directions_car,
                size: 30,
                color: Colors.blue,
              ),
            ),

            const SizedBox(width: 16),

            // Vehicle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.brand ?? ''} ${vehicle.model ?? ''}'.trim(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (vehicle.number != null && vehicle.number!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.number!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Vehicle ID Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ID: ${vehicle.vehicleId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
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