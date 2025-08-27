import 'package:flutter/material.dart';
import 'package:fullproject/domains/animal_domain.dart';
import 'package:fullproject/pages/house/house_detail/animal/animal_add.dart';
import 'package:fullproject/pages/house/house_detail/animal/animal_edit.dart';
import 'package:fullproject/services/image_service.dart';

class HouseAnimalDetailPage extends StatefulWidget {
  final int? houseId;

  const HouseAnimalDetailPage({super.key, this.houseId});

  @override
  State<HouseAnimalDetailPage> createState() => _HouseAnimalDetailPageState();
}

class _HouseAnimalDetailPageState extends State<HouseAnimalDetailPage> {
  // Theme Colors
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);
  static const Color softTerracotta = Color(0xFFD48B5C);
  static const Color clayOrange = Color(0xFFCC7748);
  static const Color warmAmber = Color(0xFFDA9856);

  void _addAnimal({required int houseId}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseAddAnimalPage(houseId: houseId),
      ),
    );

    // ถ้า result เป็น true ให้ refresh page
    if (result == true) {
      setState(() {});
    }
  }

  void _editAnimal({required int animalId}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseEditAnimalPage(animalId: animalId),
      ),
    );

    // ถ้า result เป็น true ให้ refresh page
    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivoryWhite,
      body: FutureBuilder(
        future: AnimalDomain.getByHouse(houseId: widget.houseId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(softBrown),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: clayOrange, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: const TextStyle(
                      color: clayOrange,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets_outlined, color: warmStone, size: 80),
                  const SizedBox(height: 20),
                  Text(
                    'ยังไม่มีสัตว์เลี้ยงในบ้านหมายเลข ${widget.houseId}',
                    style: const TextStyle(
                      color: earthClay,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _addAnimal(houseId: widget.houseId!);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มสัตว์เลี้ยงคนแรก'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: burntOrange,
                      foregroundColor: ivoryWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            );
          }

          final animals = snapshot.data!;

          return Column(
            children: [
              // Header with count
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: beige,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sandyTan, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pets, color: softBrown, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'พบสัตว์เลี้ยง ${animals.length} ตัว',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: softBrown,
                      ),
                    ),
                  ],
                ),
              ),
              // Animal List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.builder(
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animal = animals[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: ivoryWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: sandyTan, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: warmStone.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Animal Image
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: beige,
                                  border: Border.all(color: sandyTan, width: 1),
                                ),
                                child:
                                    animal.img != null && animal.img != "null"
                                    ? BuildImage(
                                        imagePath: animal.img!,
                                        tablePath: "animal",
                                      )
                                    : Icon(
                                        _getAnimalIcon(animal.type.toString()),
                                        size: 40,
                                        color: warmStone,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              // Animal Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      animal.name.toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: softBrown,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          _getAnimalIcon(
                                            animal.type.toString(),
                                          ),
                                          size: 16,
                                          color: earthClay,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          animal.type.toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: earthClay,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.tag,
                                          size: 16,
                                          color: earthClay,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ID: ${animal.animalId}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: earthClay,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Action Buttons
                              Column(
                                children: [
                                  // Edit Button
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: IconButton(
                                      onPressed: () {
                                        _editAnimal(animalId: animal.animalId);
                                      },
                                      icon: const Icon(Icons.edit_outlined),
                                      style: IconButton.styleFrom(
                                        backgroundColor: oliveGreen,
                                        foregroundColor: ivoryWhite,
                                        shape: const CircleBorder(),
                                        padding: const EdgeInsets.all(8),
                                      ),
                                      tooltip: 'แก้ไขข้อมูล',
                                    ),
                                  ),
                                  // Type Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(
                                        animal.type.toString(),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      animal.type.toString(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: ivoryWhite,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // Floating Action Button for quick add
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _addAnimal(houseId: widget.houseId!);
        },
        backgroundColor: burntOrange,
        foregroundColor: ivoryWhite,
        elevation: 0,
        tooltip: 'เพิ่มสัตว์เลี้ยง',
        icon: const Icon(Icons.add_rounded, color: ivoryWhite),
        label: Text("เพิ่มสัตว์เลี้ยง"),
      ),
    );
  }

  // Helper method to get appropriate icon for each animal type
  IconData _getAnimalIcon(String type) {
    switch (type.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      case 'rabbit':
        return Icons.cruelty_free;
      default:
        return Icons.pets;
    }
  }

  // Helper method to get color for each animal type using theme colors
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'dog':
        return clayOrange;
      case 'cat':
        return softTerracotta;
      case 'bird':
        return oliveGreen;
      case 'rabbit':
        return softBrown;
      default:
        return warmStone;
    }
  }
}
