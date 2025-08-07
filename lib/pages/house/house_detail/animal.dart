import 'package:flutter/material.dart';
import 'package:fullproject/domains/animal_domain.dart';

class HouseAnimalDetailPage extends StatefulWidget {
  final int? houseId;

  const HouseAnimalDetailPage({super.key, this.houseId});

  @override
  State<HouseAnimalDetailPage> createState() => _HouseAnimalDetailPageState();
}

class _HouseAnimalDetailPageState extends State<HouseAnimalDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: AnimalDomain.getByHouse(houseId: widget.houseId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
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
                  Icon(Icons.pets_outlined, color: Colors.grey[400], size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่พบสัตว์เลี้ยงในบ้านหมายเลข ${widget.houseId}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final animals = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: animals.length,
              itemBuilder: (context, index) {
                final animal = animals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: animal.img != null && animal.img != "null"
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/images/${animal.img}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        _getAnimalIcon(animal.type.toString()),
                                        size: 40,
                                        color: Colors.grey[400],
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  _getAnimalIcon(animal.type.toString()),
                                  size: 40,
                                  color: Colors.grey[400],
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _getAnimalIcon(animal.type.toString()),
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    animal.type.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.home,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'บ้านหมายเลข: ${animal.houseId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Animal Type Badge with color
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(animal.type.toString()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ID: ${animal.animalId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
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
        return Icons.flutter_dash; // or use a custom bird icon
      case 'fish':
        return Icons.set_meal; // closest to fish icon available
      case 'rabbit':
        return Icons.cruelty_free; // rabbit-like icon
      default:
        return Icons.pets;
    }
  }

  // Helper method to get color for each animal type
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'dog':
        return Colors.brown[600]!;
      case 'cat':
        return Colors.purple[600]!;
      case 'bird':
        return Colors.blue[600]!;
      case 'fish':
        return Colors.cyan[600]!;
      case 'rabbit':
        return Colors.pink[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
