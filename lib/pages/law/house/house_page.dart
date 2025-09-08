// lib/pages/law_house_manage_page.dart
// FutureBuilder-based loading + pull-to-refresh and NO refresh icon.
// Refactors state: remove manual _loading & list copies. Filtering is derived from snapshot data.

import 'package:flutter/material.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/theme/Color.dart';

import 'house_detail.dart';

class LawHouseManagePage extends StatefulWidget {
  final int villageId;

  const LawHouseManagePage({super.key, required this.villageId});

  @override
  State<LawHouseManagePage> createState() => _LawHouseManagePageState();
}

class _LawHouseManagePageState extends State<LawHouseManagePage> {
  late Future<List<HouseModel>> _housesFuture;

  String _searchQuery = '';
  String _selectedStatus = 'all'; // all, owned, vacant, rented
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _housesFuture = _fetchHouses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<HouseModel>> _fetchHouses() async {
    // WHY: Centralize domain call; safe to reuse for RefreshIndicator and on-return reloads.
    final houses = await HouseDomain.getAllInVillage(
      villageId: widget.villageId,
    );
    houses.sort((a, b) => (a.houseNumber ?? '').compareTo(b.houseNumber ?? ''));
    return houses;
  }

  Future<void> _reload() async {
    setState(() => _housesFuture = _fetchHouses());
    await _housesFuture; // makes RefreshIndicator wait for completion
  }

  // Derived statistics based on given list
  Map<String, int> _getStatistics(List<HouseModel> list) {
    final owned = list
        .where((h) => (h.status ?? '').toLowerCase() == 'owned')
        .length;
    final vacant = list
        .where((h) => (h.status ?? '').toLowerCase() == 'vacant')
        .length;
    final rented = list
        .where((h) => (h.status ?? '').toLowerCase() == 'rented')
        .length;
    return {
      'total': list.length,
      'owned': owned,
      'vacant': vacant,
      'rented': rented,
    };
  }

  Color _getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'owned':
        return ThemeColors.oliveGreen;
      case 'vacant':
        return ThemeColors.warmAmber;
      case 'rented':
        return ThemeColors.softTerracotta;
      default:
        return ThemeColors.warmStone;
    }
  }

  String _getStatusText(String? status) {
    switch ((status ?? '').toLowerCase()) {
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

  void _applyFilters() => setState(() {}); // WHY: trigger rebuild only

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.inputFill,
      body: SafeArea(
        child: FutureBuilder<List<HouseModel>>(
          future: _housesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }

            if (snapshot.hasError) {
              return _buildError(snapshot.error);
            }

            final list = snapshot.data ?? const <HouseModel>[];
            final stats = _getStatistics(list);

            // Filtering derived from inputs
            final filtered = list.where((house) {
              final q = _searchQuery.trim().toLowerCase();
              final matchesSearch =
                  q.isEmpty ||
                  ((house.houseNumber ?? '').toLowerCase().contains(q)) ||
                  ((house.owner ?? '').toLowerCase().contains(q));

              final target = _selectedStatus.toLowerCase();
              final matchesStatus =
                  target == 'all' ||
                  (house.status ?? '').toLowerCase() == target;

              return matchesSearch && matchesStatus;
            }).toList();

            return Column(
              children: [
                _buildHeader(),
                _buildStats(stats),
                _buildSearchAndFilter(),
                _buildCount(filtered.length),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: ThemeColors.softBrown,
                          backgroundColor: ThemeColors.ivoryWhite,
                          onRefresh: _reload,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildHouseCard(filtered[index]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      // NOTE: refresh FloatingActionButton intentionally removed as requested.
    );
  }

  // ===== Sections =====

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ThemeColors.softBrown, ThemeColors.focusedBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.softBrown.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 24,
                color: ThemeColors.ivoryWhite,
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
                color: ThemeColors.ivoryWhite,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              size: 24,
              color: ThemeColors.ivoryWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(Map<String, int> stats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.softBrown.withOpacity(0.15),
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
                  color: ThemeColors.sandyTan,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: ThemeColors.softBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'สรุปข้อมูลบ้าน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.softBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'ทั้งหมด',
                  stats['total'] ?? 0,
                  ThemeColors.softBrown,
                ),
              ),
              Container(width: 1, height: 60, color: ThemeColors.softBorder),
              Expanded(
                child: _buildStatItem(
                  'มีเจ้าของ',
                  stats['owned'] ?? 0,
                  ThemeColors.oliveGreen,
                ),
              ),
              Container(width: 1, height: 60, color: ThemeColors.softBorder),
              Expanded(
                child: _buildStatItem(
                  'ว่าง',
                  stats['vacant'] ?? 0,
                  ThemeColors.warmAmber,
                ),
              ),
              Container(width: 1, height: 60, color: ThemeColors.softBorder),
              Expanded(
                child: _buildStatItem(
                  'ให้เช่า',
                  stats['rented'] ?? 0,
                  ThemeColors.softTerracotta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาเลขที่บ้านหรือชื่อเจ้าของ...',
                hintStyle: TextStyle(
                  color: ThemeColors.earthClay,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.search_rounded,
                    color: ThemeColors.softBrown,
                    size: 20,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: ThemeColors.earthClay,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: ThemeColors.focusedBrown,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: ThemeColors.ivoryWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: TextStyle(
                color: ThemeColors.softBrown,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeColors.ivoryWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ThemeColors.softBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.softBrown.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                icon: const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: ThemeColors.softBrown,
                ),
                style: TextStyle(
                  color: ThemeColors.softBrown,
                  fontWeight: FontWeight.w600,
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทั้งหมด')),
                  DropdownMenuItem(value: 'owned', child: Text('มีเจ้าของ')),
                  DropdownMenuItem(value: 'vacant', child: Text('ว่าง')),
                  DropdownMenuItem(value: 'rented', child: Text('ให้เช่า')),
                ],
                onChanged: (value) {
                  _selectedStatus = value ?? 'all';
                  _applyFilters();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ThemeColors.softBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ThemeColors.softBrown.withOpacity(0.3)),
            ),
            child: Text(
              'พบ $count รายการ',
              style: TextStyle(
                color: ThemeColors.softBrown,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseCard(HouseModel house) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: ThemeColors.ivoryWhite,
        shadowColor: ThemeColors.softBrown.withOpacity(0.2),
        child: InkWell(
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HouseDetailPage(houseId: house.houseId),
              ),
            );
            if (updated == true && mounted) _reload();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: ThemeColors.clickHighlight.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // House icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(house.status),
                        _getStatusColor(house.status).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(house.status).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: ThemeColors.ivoryWhite,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                // House info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'บ้านเลขที่ ${house.houseNumber ?? '-'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.softBrown,
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
                                  _getStatusColor(
                                    house.status,
                                  ).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(
                                    house.status,
                                  ).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _getStatusText(house.status),
                              style: const TextStyle(
                                color: ThemeColors.ivoryWhite,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if ((house.owner ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: ThemeColors.inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ThemeColors.softBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: ThemeColors.earthClay,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  house.owner!,
                                  style: TextStyle(
                                    color: ThemeColors.softBrown,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if ((house.phone ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: ThemeColors.inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ThemeColors.softBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 16,
                                color: ThemeColors.earthClay,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  house.phone!,
                                  style: TextStyle(
                                    color: ThemeColors.softBrown,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if ((house.houseType ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ThemeColors.inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ThemeColors.softBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.home_work_rounded,
                                size: 16,
                                color: ThemeColors.earthClay,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  house.houseType!,
                                  style: TextStyle(
                                    color: ThemeColors.softBrown,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== States =====

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeColors.ivoryWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.softBrown.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: ThemeColors.softBrown,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'กำลังโหลดข้อมูลบ้าน...',
            style: TextStyle(
              color: ThemeColors.earthClay,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: ThemeColors.softTerracotta,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ThemeColors.warmStone.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home_outlined,
              size: 64,
              color: ThemeColors.warmStone,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ยังไม่มีข้อมูลบ้าน',
            style: TextStyle(
              fontSize: 18,
              color: ThemeColors.earthClay,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'เริ่มต้นด้วยการเพิ่มข้อมูลบ้านใหม่',
            style: TextStyle(fontSize: 14, color: ThemeColors.warmStone),
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            '$value',
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
            color: ThemeColors.earthClay,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
