import 'package:flutter/material.dart';
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/models/notion_model.dart';
import 'package:fullproject/pages/house/widgets/appbar.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/theme/Color.dart';

class HouseNotionsPage extends StatefulWidget {
  final HouseModel? houseData;

  const HouseNotionsPage({super.key, this.houseData});

  @override
  State<HouseNotionsPage> createState() => _HouseNotionsPageState();
}

class _HouseNotionsPageState extends State<HouseNotionsPage>
    with TickerProviderStateMixin {
  List<NotionModel> _allNotions = [];
  List<NotionModel> _filteredNotions = [];
  String _selectedFilter = 'ALL';
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    print(widget.houseData!.toJson());
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadNotions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotions() async {
    // print('🔍 Loading notions for village: ${widget.villageId}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> data;

      if (_selectedFilter == 'ALL') {
        data = await NotionDomain.getRecentNotions(
          villageId: widget.houseData?.villageId,
        );
      } else {
        data = await NotionDomain.getRecentNotionsFilter(
          villageId: widget.houseData?.villageId,
          type: _selectedFilter,
        );
      }

      if (data['success'] == true && data['notions'] != null) {
        final rawNotions = data['notions'] as List;

        setState(() {
          _allNotions = rawNotions
              .where((item) {
                if (item == null) {
                  print('⚠️ Found null item');
                  return false;
                }
                if (item is! NotionModel) {
                  print('⚠️ Item is not NotionModel: ${item.runtimeType}');
                  return false;
                }
                final notion = item as NotionModel;
                if (notion.type == null || notion.header == null) {
                  print(
                    '⚠️ Notion has null required fields - Type: ${notion.type}, Header: ${notion.header}',
                  );
                  return false;
                }
                return true;
              })
              .map((item) => item as NotionModel)
              .toList();

          _applyFilterSafe();
          _isLoading = false;
          _animationController.forward();
        });
      } else {
        print('❌ Failed to load notions: ${data}');
        setState(() {
          _allNotions = [];
          _filteredNotions = [];
          _isLoading = false;
          _errorMessage = 'ไม่สามารถโหลดข้อมูลได้';
        });
      }
    } catch (e, stackTrace) {
      print('💥 Error loading notions: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() {
        _allNotions = [];
        _filteredNotions = [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _applyFilterSafe() {
    // Filter out any null notions and notions with null required fields
    _filteredNotions = _allNotions.where((notion) {
      return notion.type != null &&
          notion.header != null &&
          notion.description != null;
    }).toList();

    // Sort by creation date (newest first) with null safety
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
    });
    _loadNotions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HouseAppBar(house: widget.houseData?.houseNumber),

      backgroundColor: ThemeColors.beige,
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_filteredNotions.isEmpty) {
      return _buildEmptyState();
    }

    return _buildNotionsList();
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
                // Icon(Icons.filter_list_rounded, color: ThemeColors.softBrown, size: 20),
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

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'ALL':
        return Icons.all_inclusive_rounded;
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
        return Icons.filter_list_rounded;
    }
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'ALL':
        return ThemeColors.softBrown;
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
        return ThemeColors.softBrown;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'กำลังโหลดข่าวสาร...',
            style: TextStyle(color: ThemeColors.earthClay, fontSize: 16),
          ),
        ],
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.earthClay.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: ThemeColors.clayOrange,
            ),
            const SizedBox(height: 16),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeColors.softBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: ThemeColors.earthClay, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotions,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.burntOrange,
                foregroundColor: ThemeColors.ivoryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ลองอีกครั้ง'),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeColors.ivoryWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.earthClay.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 48,
              color: ThemeColors.warmStone,
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่พบข่าวสาร',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeColors.softBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'ALL'
                  ? 'ยังไม่มีข่าวสารในระบบ'
                  : 'ไม่พบข่าวสารในหมวดหมู่ที่เลือก',
              style: TextStyle(color: ThemeColors.earthClay, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotionsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        color: ThemeColors.softBrown,
        backgroundColor: ThemeColors.ivoryWhite,
        onRefresh: _loadNotions,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          itemCount: _filteredNotions.length,
          itemBuilder: (context, index) {
            // Debug each item before building
            // print('🔨 Building item $index of ${_filteredNotions.length}');

            final notion = _filteredNotions[index];
            // print('📋 Notion $index details:');
            // print('  - notionId: ${notion.notionId}');
            // print('  - villageId: ${notion.villageId}');
            // print('  - type: ${notion.type}');
            // print('  - header: ${notion.header}');
            // print('  - description: ${notion.description}');
            // print('  - createDate: ${notion.createDate}');
            // print('  - img: ${notion.img}');

            try {
              return SlideTransition(
                position: Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
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
                child: CardNotion(notion: notion),
              );
            } catch (e, stackTrace) {
              print('💥 Error building item $index: $e');
              print('📍 Stack trace: $stackTrace');

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error at index $index',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Error: $e',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    Text(
                      'Type: ${notion.type ?? "null"}',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    Text(
                      'Header: ${notion.header ?? "null"}',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class CardNotion extends StatelessWidget {
  final NotionModel notion;

  const CardNotion({super.key, required this.notion});

  // Theme Colors

  Color _getTypeColor(String? type) {
    if (type == null) return ThemeColors.warmStone;

    switch (type) {
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

    switch (type) {
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

    switch (type) {
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

  String _formatDateFromDateTime(DateTime? date) {
    if (date == null) return '';

    const monthNames = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${date.day} ${monthNames[date.month]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    // Add comprehensive null safety check
    if (notion.type == null) {
      print('⚠️ Notion type is null');
      return const SizedBox.shrink();
    }

    if (notion.header == null) {
      print('⚠️ Notion header is null');
      return const SizedBox.shrink();
    }

    if (notion.description == null) {
      print('⚠️ Notion description is null');
      return const SizedBox.shrink();
    }

    try {
      final typeColor = _getTypeColor(notion.type!);
      // print('✅ Type color for ${notion.type}: $typeColor');

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type badge and date
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: typeColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTypeIcon(notion.type!),
                              size: 14,
                              color: typeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getTypeText(notion.type!),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDateFromDateTime(notion.createDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeColors.earthClay,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    notion.header ?? 'ไม่มีหัวข้อ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.softBrown,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Image
            if (notion.img != null && notion.img!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 200, // ความสูงขั้นต่ำ 200
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.earthClay.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9, // อัตราส่วน 16:9 ให้ดูสวยงาม
                    child: BuildImage(
                      imagePath: notion.img!,
                      tablePath: 'notion',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Text(
                notion.description ?? 'ไม่มีรายละเอียด',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: ThemeColors.earthClay,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('💥 Error building CardNotion: $e');
      print('📍 Stack trace: $stackTrace');
      print('📦 Notion data: type=${notion.type}, header=${notion.header}');

      // Return a simple error card instead of crashing
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Text(
          'Error loading notion: ${e.toString()}',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }
}
