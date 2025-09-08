// lib/pages/law/notion/notion_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/pages/law/notion/notion_edit_page.dart';
import 'package:intl/intl.dart';
import 'package:fullproject/models/notion_model.dart';
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/notion/notion_add_page.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/theme/Color.dart';

class LawNotionPage extends StatefulWidget {
  const LawNotionPage({super.key});

  @override
  State<LawNotionPage> createState() => _LawNotionPageState();
}

class _LawNotionPageState extends State<LawNotionPage>
    with TickerProviderStateMixin {
  Future<List<NotionModel>>? _notions;
  LawModel? law;
  bool _isRefreshing = false;

  // Filter states
  List<NotionModel> _allNotions = [];
  List<NotionModel> _filteredNotions = [];
  String _selectedFilter = 'ALL';

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _notions = _fetchNotions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<NotionModel>> _fetchNotions() async {
    final user = await AuthService.getCurrentUser();
    if (user is LawModel) {
      if (mounted) setState(() => law = user);
      final notions = await NotionDomain.getByVillage(user.villageId);

      // Apply filter
      setState(() {
        _allNotions = notions;
        _applyFilter();
        _animationController.forward();
      });

      return notions;
    }
    return [];
  }

  void _applyFilter() {
    if (_selectedFilter == 'ALL') {
      _filteredNotions = _allNotions;
    } else {
      _filteredNotions = _allNotions.where((notion) {
        return notion.type?.toUpperCase() == _selectedFilter;
      }).toList();
    }

    // Sort by creation date (newest first)
    _filteredNotions.sort((a, b) {
      if (a.createDate == null && b.createDate == null) return 0;
      if (a.createDate == null) return 1;
      if (b.createDate == null) return -1;
      return b.createDate!.compareTo(a.createDate!);
    });
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  Future<void> _loadNotions() async {
    setState(() {
      _notions = _fetchNotions();
    });
    await _notions;
  }

  Future<void> _refreshWithOverlay() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadNotions();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LawNotionAddPage()),
    );
    if (result == true) {
      await _refreshWithOverlay();
    }
  }

  Future<void> _navigateToEdit(NotionModel notion) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LawNotionEditPage(notion: notion)),
    );
    if (result == true) {
      await _refreshWithOverlay();
    }
  }

  Future<void> _confirmDelete(NotionModel notion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: ThemeColors.ivoryWhite,
        title: const Text(
          "ยืนยันการลบ",
          style: TextStyle(
            color: ThemeColors.softBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "คุณต้องการลบข่าว '${notion.header}' ใช่หรือไม่?",
          style: const TextStyle(color: ThemeColors.earthClay),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: ThemeColors.earthClay),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.burntOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("ลบ"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isRefreshing = true;
      });

      try {
        await NotionDomain.delete(notion.notionId);
        await _loadNotions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ลบข่าวสารเรียบร้อยแล้ว'),
              backgroundColor: ThemeColors.oliveGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      }
    }
  }

  Color _getTypeColor(String? type) {
    if (type == null) return ThemeColors.warmStone;

    switch (type.toUpperCase()) {
      case 'GENERAL':
        return ThemeColors.softBrown;
      case 'MAINTENANCE':
        return ThemeColors.burntOrange;
      case 'SECURITY':
        return ThemeColors.clayOrange;
      case 'FINANCE':
        return ThemeColors.oliveGreen;
      case 'SOCIAL':
        return ThemeColors.softTerracotta;
      default:
        return ThemeColors.warmStone;
    }
  }

  String _getTypeText(String? type) {
    if (type == null) return 'อื่นๆ';

    switch (type.toUpperCase()) {
      case 'GENERAL':
        return 'ข่าวสารทั่วไป';
      case 'MAINTENANCE':
        return 'การบำรุงรักษา';
      case 'SECURITY':
        return 'ความปลอดภัย';
      case 'FINANCE':
        return 'การเงิน';
      case 'SOCIAL':
        return 'กิจกรรมสังคม';
      default:
        return 'อื่นๆ';
    }
  }

  IconData _getTypeIcon(String? type) {
    if (type == null) return Icons.article_rounded;

    switch (type.toUpperCase()) {
      case 'GENERAL':
        return Icons.info_rounded;
      case 'MAINTENANCE':
        return Icons.build_rounded;
      case 'SECURITY':
        return Icons.security_rounded;
      case 'FINANCE':
        return Icons.account_balance_wallet_rounded;
      case 'SOCIAL':
        return Icons.groups_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.earthClay.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  'หมวดหมู่ข่าวสาร',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeColors.softBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredNotions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.softBrown,
                    ),
                  ),
                ),
                const Spacer(),
                if (_selectedFilter != 'ALL')
                  TextButton(
                    onPressed: () => _changeFilter('ALL'),
                    child: Text(
                      'ล้างตัวกรอง',
                      style: TextStyle(
                        color: ThemeColors.clayOrange,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Filter Dropdown
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                filled: true,
                fillColor: ThemeColors.sandyTan,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeColors.warmStone),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeColors.warmStone),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeColors.softBrown,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              dropdownColor: ThemeColors.ivoryWhite,
              style: TextStyle(
                color: ThemeColors.softBrown,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: [
                DropdownMenuItem(
                  value: 'ALL',
                  child: Row(
                    children: [
                      Icon(
                        Icons.all_inclusive_rounded,
                        size: 18,
                        color: ThemeColors.softBrown,
                      ),
                      const SizedBox(width: 8),
                      const Text('ทั้งหมด'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'GENERAL',
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        size: 18,
                        color: ThemeColors.softBrown,
                      ),
                      const SizedBox(width: 8),
                      const Text('ข่าวสารทั่วไป'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'MAINTENANCE',
                  child: Row(
                    children: [
                      Icon(
                        Icons.build_rounded,
                        size: 18,
                        color: ThemeColors.burntOrange,
                      ),
                      const SizedBox(width: 8),
                      const Text('การบำรุงรักษา'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'SECURITY',
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        size: 18,
                        color: ThemeColors.clayOrange,
                      ),
                      const SizedBox(width: 8),
                      const Text('ความปลอดภัย'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'FINANCE',
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 18,
                        color: ThemeColors.oliveGreen,
                      ),
                      const SizedBox(width: 8),
                      const Text('การเงิน'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'SOCIAL',
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 18,
                        color: ThemeColors.softTerracotta,
                      ),
                      const SizedBox(width: 8),
                      const Text('กิจกรรมสังคม'),
                    ],
                  ),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _changeFilter(newValue);
                }
              },
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ThemeColors.earthClay,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotionImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: ThemeColors.beige,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeColors.sandyTan, width: 1),
        ),
        child: const Icon(
          Icons.article_outlined,
          color: ThemeColors.earthClay,
          size: 32,
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33BFA18F),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BuildImage(
          imagePath: imagePath,
          tablePath: 'notion',
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          placeholder: Container(
            color: ThemeColors.beige,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ThemeColors.softBrown,
                ),
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: Container(
            color: ThemeColors.beige,
            child: const Icon(
              Icons.broken_image_outlined,
              color: ThemeColors.earthClay,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String? type) {
    if (type == null || type.isEmpty) return const SizedBox.shrink();

    final typeColor = _getTypeColor(type);
    final displayText = _getTypeText(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: typeColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ThemeColors.softBrown,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'กำลังอัพเดทข้อมูล...',
                  style: TextStyle(
                    color: ThemeColors.softBrown,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: const MaterialColor(0xFFA47551, {
          50: Color(0xFFF5F2EF),
          100: Color(0xFFE5DDD6),
          200: Color(0xFFD4C5BB),
          300: Color(0xFFC2ADA0),
          400: Color(0xFFB5998B),
          500: ThemeColors.softBrown,
          600: Color(0xFF9C6D4A),
          700: Color(0xFF926240),
          800: Color(0xFF885837),
          900: Color(0xFF764627),
        }),
        scaffoldBackgroundColor: ThemeColors.ivoryWhite,
        cardColor: ThemeColors.sandyTan,
        appBarTheme: const AppBarTheme(
          backgroundColor: ThemeColors.softBrown,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: ThemeColors.earthClay,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: ThemeColors.burntOrange,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: ThemeColors.ivoryWhite,
          elevation: 3,
          shadowColor: Color(0x4DBFA18F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0x4DD8CAB8), width: 1),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'ข่าวสารหมู่บ้าน',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ThemeColors.ivoryWhite, ThemeColors.beige],
                ),
              ),
              child: Column(
                children: [
                  // Filter Section
                  _buildFilterSection(),

                  // Content
                  Expanded(
                    child: FutureBuilder<List<NotionModel>>(
                      future: _notions,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            _notions == null) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ThemeColors.softBrown,
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: ThemeColors.burntOrange,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'เกิดข้อผิดพลาด',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ThemeColors.softBrown,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  style: const TextStyle(
                                    color: ThemeColors.earthClay,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        } else if (_filteredNotions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.article_outlined,
                                  size: 64,
                                  color: ThemeColors.earthClay,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedFilter == 'ALL'
                                      ? 'ไม่มีข่าวสารในขณะนี้'
                                      : 'ไม่พบข่าวสารในหมวดหมู่ที่เลือก',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeColors.softBrown,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'แตะปุ่ม + เพื่อเพิ่มข่าวสารใหม่',
                                  style: TextStyle(
                                    color: ThemeColors.earthClay,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: RefreshIndicator(
                            color: ThemeColors.softBrown,
                            backgroundColor: ThemeColors.ivoryWhite,
                            onRefresh: () async {
                              await _loadNotions();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredNotions.length,
                              itemBuilder: (context, index) {
                                final notion = _filteredNotions[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildNotionImage(notion.img),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notion.header ??
                                                            'ไม่มีหัวข้อ',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: ThemeColors
                                                              .softBrown,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildTypeChip(notion.type),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                if (notion.description !=
                                                        null &&
                                                    notion
                                                        .description!
                                                        .isNotEmpty)
                                                  Text(
                                                    notion.description!,
                                                    style: const TextStyle(
                                                      color:
                                                          ThemeColors.earthClay,
                                                      fontSize: 14,
                                                      height: 1.3,
                                                    ),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),

                                                // Large image display
                                                if (notion.img != null &&
                                                    notion.img!.isNotEmpty) ...[
                                                  const SizedBox(height: 12),
                                                  Container(
                                                    width: double.infinity,
                                                    constraints:
                                                        const BoxConstraints(
                                                          minHeight: 200,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: ThemeColors
                                                              .earthClay
                                                              .withOpacity(0.1),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: AspectRatio(
                                                        aspectRatio: 16 / 9,
                                                        child: BuildImage(
                                                          imagePath:
                                                              notion.img!,
                                                          tablePath: 'notion',
                                                          fit: BoxFit.cover,
                                                          placeholder: Container(
                                                            color: ThemeColors
                                                                .beige,
                                                            child: const Center(
                                                              child: CircularProgressIndicator(
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                      Color
                                                                    >(
                                                                      ThemeColors
                                                                          .softBrown,
                                                                    ),
                                                                strokeWidth: 2,
                                                              ),
                                                            ),
                                                          ),
                                                          errorWidget: Container(
                                                            color: ThemeColors
                                                                .beige,
                                                            child: const Icon(
                                                              Icons
                                                                  .broken_image_outlined,
                                                              color: ThemeColors
                                                                  .earthClay,
                                                              size: 48,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],

                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.schedule,
                                                      size: 14,
                                                      color:
                                                          ThemeColors.earthClay,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        _formatDate(
                                                          notion.createDate,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: ThemeColors
                                                              .earthClay,
                                                        ),
                                                      ),
                                                    ),
                                                    Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        onTap: () =>
                                                            _navigateToEdit(
                                                              notion,
                                                            ),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8,
                                                              ),
                                                          child: const Icon(
                                                            Icons.edit_outlined,
                                                            color: ThemeColors
                                                                .burntOrange,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        onTap: () =>
                                                            _confirmDelete(
                                                              notion,
                                                            ),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8,
                                                              ),
                                                          child: const Icon(
                                                            Icons
                                                                .delete_outline,
                                                            color: ThemeColors
                                                                .softTerracotta,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Loading overlay
            if (_isRefreshing) _buildLoadingOverlay(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToAdd,
          icon: const Icon(Icons.add),
          label: const Text('เพิ่มข่าวสาร'),
          tooltip: 'เพิ่มข่าวสารใหม่',
        ),
      ),
    );
  }
}
