import 'package:flutter/material.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/services/image_service.dart';

import 'house_add.dart';
import 'house_detail.dart';

class LawHouseManagePage extends StatefulWidget {
  final int villageId;

  const LawHouseManagePage({super.key, required this.villageId});

  @override
  State<LawHouseManagePage> createState() => _LawHouseManagePageState();
}

class _LawHouseManagePageState extends State<LawHouseManagePage> {
  List<HouseModel> _houses = [];
  List<HouseModel> _filteredHouses = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all'; // all, owned, vacant, rented

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHouses() async {
    setState(() => _loading = true);
    try {
      final houses = await HouseDomain.getAllInVillage(
        villageId: widget.villageId,
      );
      setState(() {
        _houses = houses;
        _filteredHouses = houses;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        );
      }
    }
  }

  void _filterHouses() {
    setState(() {
      _filteredHouses = _houses.where((house) {
        // Filter by search query
        bool matchesSearch = _searchQuery.isEmpty ||
            (house.houseNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (house.owner?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        // Filter by status
        bool matchesStatus = _selectedStatus == 'all' ||
            (house.status?.toLowerCase() == _selectedStatus);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _deleteHouse(int houseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบบ้านนี้?\nการดำเนินการนี้ไม่สามารถยกเลิกได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await HouseDomain.delete(houseId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบข้อมูลสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadHouses();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบ'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Map<String, int> _getStatistics() {
    int total = _houses.length;
    int owned = _houses.where((h) => h.status?.toLowerCase() == 'owned').length;
    int vacant = _houses.where((h) => h.status?.toLowerCase() == 'vacant').length;
    int rented = _houses.where((h) => h.status?.toLowerCase() == 'rented').length;

    return {
      'total': total,
      'owned': owned,
      'vacant': vacant,
      'rented': rented,
    };
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'owned':
        return Colors.green;
      case 'vacant':
        return Colors.orange;
      case 'rented':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'owned':
        return 'มีเจ้าของ';
      case 'vacant':
        return 'ว่าง';
      case 'rented':
        return 'ให้เช่า';
      default:
        return 'ไม่ระบุ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStatistics();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Custom Header (แทน AppBar)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'จัดการลูกบ้าน',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Statistics Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('ทั้งหมด', stats['total']!, Colors.blue),
                  _buildStatItem('มีเจ้าของ', stats['owned']!, Colors.green),
                  _buildStatItem('ว่าง', stats['vacant']!, Colors.orange),
                  _buildStatItem('ให้เช่า', stats['rented']!, Colors.purple),
                ],
              ),
            ),

            // Search and Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Search TextField
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ค้นหาเลขที่บ้านหรือชื่อเจ้าของ...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _filterHouses();
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        _searchQuery = value;
                        _filterHouses();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Status Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        icon: const Icon(Icons.filter_alt, size: 20),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('ทั้งหมด')),
                          DropdownMenuItem(value: 'owned', child: Text('มีเจ้าของ')),
                          DropdownMenuItem(value: 'vacant', child: Text('ว่าง')),
                          DropdownMenuItem(value: 'rented', child: Text('ให้เช่า')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                          _filterHouses();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'พบ ${_filteredHouses.length} รายการ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Houses List
            Expanded(
              child: _filteredHouses.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty || _selectedStatus != 'all'
                          ? 'ไม่พบข้อมูลที่ค้นหา'
                          : 'ยังไม่มีข้อมูลบ้าน',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadHouses,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _filteredHouses.length,
                  itemBuilder: (context, index) {
                    final house = _filteredHouses[index];
                    return _buildHouseCard(house);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Refresh Button
          FloatingActionButton(
            heroTag: "refresh",
            mini: true,
            onPressed: _loadHouses,
            child: const Icon(Icons.refresh),
            backgroundColor: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          // Add Button
          FloatingActionButton.extended(
            heroTag: "add",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HouseCreatePage()),
              );
              if (result != null && mounted) _loadHouses();
            },
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มบ้าน'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHouseCard(HouseModel house) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: InkWell(
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HouseDetailPage(houseId: house.houseId),
              ),
            );
            if (updated == true && mounted) _loadHouses();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // House Image or Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getStatusColor(house.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.home,
                    color: _getStatusColor(house.status),
                    size: 30,
                  ),
                ),

                const SizedBox(width: 16),

                // House Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'บ้านเลขที่ ${house.houseNumber ?? "-"}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(house.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(house.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (house.owner != null && house.owner!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  house.owner!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (house.phone != null && house.phone!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  house.phone!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (house.houseType != null && house.houseType!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.home_work, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                house.houseType!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action Buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Call Button
                    if (house.phone != null && house.phone!.isNotEmpty)
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green, size: 20),
                          onPressed: () {
                            // TODO: Implement call functionality
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('โทร: ${house.phone}')),
                              );
                            }
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),

                    // Delete Button
                    Container(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _deleteHouse(house.houseId),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}