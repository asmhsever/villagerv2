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

  // Enhanced Earthy Theme Colors
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);

  // New Enhanced Colors
  static const Color softBorder = Color(0xFFD0C4B0);
  static const Color focusedBrown = Color(0xFF916846);
  static const Color inputFill = Color(0xFFFBF9F3);
  static const Color clickHighlight = Color(0xFFDC7633);
  static const Color hoverButton = Color(0xFFF3A664);
  static const Color disabledGrey = Color(0xFFDCDCDC);
  static const Color softTerracotta = Color(0xFFD48B5C);
  static const Color clayOrange = Color(0xFFCC7748);
  static const Color warmAmber = Color(0xFFDA9856);

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
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: clayOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
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
        backgroundColor: ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: clayOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_forever_rounded, color: clayOrange, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'ยืนยันการลบ',
              style: TextStyle(
                color: clayOrange,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: clayOrange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: clayOrange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: clayOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'การดำเนินการนี้ไม่สามารถยกเลิกได้',
                      style: TextStyle(
                        color: clayOrange,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลบ้านนี้?',
              style: TextStyle(color: earthClay, fontSize: 15),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: warmStone,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: clayOrange,
              foregroundColor: ivoryWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_rounded, size: 16),
                const SizedBox(width: 4),
                const Text('ลบ', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await HouseDomain.delete(houseId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ลบข้อมูลสำเร็จ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              backgroundColor: oliveGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          _loadHouses();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.error_outline, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'เกิดข้อผิดพลาดในการลบ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              backgroundColor: clayOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
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
        return oliveGreen;
      case 'vacant':
        return warmAmber;
      case 'rented':
        return softTerracotta;
      default:
        return warmStone;
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
      backgroundColor: inputFill,
      body: SafeArea(
        child: _loading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ivoryWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: softBrown.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  color: softBrown,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'กำลังโหลดข้อมูลบ้าน...',
                style: TextStyle(
                  color: earthClay,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
            : Column(
          children: [
            // Enhanced Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [softBrown, focusedBrown],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: softBrown.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 24,
                            color: ivoryWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'จัดการลูกบ้าน',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ivoryWhite,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.home_work_rounded,
                          size: 24,
                          color: ivoryWhite,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Enhanced Statistics Card
            Container(
              margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ivoryWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: softBrown.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: sandyTan,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.analytics_rounded, color: softBrown, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'สรุปข้อมูลบ้าน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: softBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('ทั้งหมด', stats['total']!, softBrown)),
                      Container(width: 1, height: 60, color: softBorder),
                      Expanded(child: _buildStatItem('มีเจ้าของ', stats['owned']!, oliveGreen)),
                      Container(width: 1, height: 60, color: softBorder),
                      Expanded(child: _buildStatItem('ว่าง', stats['vacant']!, warmAmber)),
                      Container(width: 1, height: 60, color: softBorder),
                      Expanded(child: _buildStatItem('ให้เช่า', stats['rented']!, softTerracotta)),
                    ],
                  ),
                ],
              ),
            ),

            // Enhanced Search and Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Enhanced Search TextField
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: softBrown.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'ค้นหาเลขที่บ้านหรือชื่อเจ้าของ...',
                          hintStyle: TextStyle(color: earthClay, fontSize: 14),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.search_rounded, color: softBrown, size: 20),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: earthClay),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _filterHouses();
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: focusedBrown, width: 2),
                          ),
                          filled: true,
                          fillColor: ivoryWhite,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: TextStyle(color: softBrown, fontWeight: FontWeight.w500),
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterHouses();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Enhanced Status Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: ivoryWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: softBorder, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: softBrown.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        icon: Icon(Icons.tune_rounded, size: 20, color: softBrown),
                        style: TextStyle(color: softBrown, fontWeight: FontWeight.w600),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: softBrown,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('ทั้งหมด'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'owned',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: oliveGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('มีเจ้าของ'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'vacant',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: warmAmber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('ว่าง'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'rented',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: softTerracotta,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('ให้เช่า'),
                              ],
                            ),
                          ),
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

            const SizedBox(height: 20),

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: softBrown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: softBrown.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'พบ ${_filteredHouses.length} รายการ',
                      style: TextStyle(
                        color: softBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Enhanced Houses List
            Expanded(
              child: _filteredHouses.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: warmStone.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.home_outlined,
                        size: 64,
                        color: warmStone,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _searchQuery.isNotEmpty || _selectedStatus != 'all'
                          ? 'ไม่พบข้อมูลที่ค้นหา'
                          : 'ยังไม่มีข้อมูลบ้าน',
                      style: TextStyle(
                        fontSize: 18,
                        color: earthClay,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty || _selectedStatus != 'all'
                          ? 'ลองเปลี่ยนเงื่อนไขการค้นหา'
                          : 'เริ่มต้นด้วยการเพิ่มข้อมูลบ้านใหม่',
                      style: TextStyle(
                        fontSize: 14,
                        color: warmStone,
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                color: softBrown,
                backgroundColor: ivoryWhite,
                onRefresh: _loadHouses,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
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
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: FloatingActionButton(
              heroTag: "refresh",
              mini: true,
              onPressed: _loadHouses,
              backgroundColor: warmStone,
              foregroundColor: ivoryWhite,
              elevation: 4,
              child: const Icon(Icons.refresh_rounded),
            ),
          ),
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
            icon: const Icon(Icons.add_home_rounded),
            label: const Text(
              'เพิ่มบ้าน',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: oliveGreen,
            foregroundColor: ivoryWhite,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: earthClay,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHouseCard(HouseModel house) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        color: ivoryWhite,
        shadowColor: softBrown.withValues(alpha: 0.2),
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
          borderRadius: BorderRadius.circular(16),
          splashColor: clickHighlight.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced House Image or Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(house.status),
                        _getStatusColor(house.status).withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(house.status).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    color: ivoryWhite,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 20),

                // Enhanced House Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'บ้านเลขที่ ${house.houseNumber ?? "-"}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: softBrown,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getStatusColor(house.status),
                                  _getStatusColor(house.status).withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(house.status).withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _getStatusText(house.status),
                              style: const TextStyle(
                                color: ivoryWhite,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (house.owner != null && house.owner!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: softBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded, size: 16, color: earthClay),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  house.owner!,
                                  style: TextStyle(
                                    color: softBrown,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (house.phone != null && house.phone!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: softBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.phone_rounded, size: 16, color: earthClay),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  house.phone!,
                                  style: TextStyle(
                                    color: softBrown,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (house.houseType != null && house.houseType!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: softBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.home_work_rounded, size: 16, color: earthClay),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  house.houseType!,
                                  style: TextStyle(
                                    color: softBrown,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Enhanced Action Buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Call Button
                    if (house.phone != null && house.phone!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: oliveGreen,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.phone_rounded, color: Colors.white, size: 16),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'โทร: ${house.phone}',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    backgroundColor: oliveGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.phone_rounded, color: ivoryWhite, size: 20),
                            ),
                          ),
                        ),
                      ),

                    // Delete Button
                    Material(
                      color: clayOrange,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _deleteHouse(house.houseId),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.delete_rounded, color: ivoryWhite, size: 20),
                        ),
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