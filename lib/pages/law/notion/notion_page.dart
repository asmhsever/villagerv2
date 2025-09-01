// lib/pages/law/notion/notion_page.dart
// Future loading ถูกต้อง: ให้ FutureBuilder แสดงสถานะรอจริง, reload หลัง add/edit/delete + loading overlay

import 'package:flutter/material.dart';
import 'package:fullproject/pages/law/notion/notion_edit_page.dart';
import 'package:intl/intl.dart';
import 'package:fullproject/models/notion_model.dart';
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/notion/notion_add_page.dart';
import 'package:fullproject/theme/Color.dart';

class LawNotionPage extends StatefulWidget {
  const LawNotionPage({super.key});

  @override
  State<LawNotionPage> createState() => _LawNotionPageState();
}

class _LawNotionPageState extends State<LawNotionPage> {
  Future<List<NotionModel>>? _notions; // ชี้ไปยัง future ปัจจุบันเสมอ
  LawModel? law;
  bool _isRefreshing = false; // สถานะ loading สำหรับ

  @override
  void initState() {
    super.initState();
    // สำคัญ: ผูก future ตั้งแต่เริ่ม เพื่อให้ FutureBuilder ได้ state = waiting
    _notions = _fetchNotions();
  }

  /// แยกเป็นฟังก์ชันคืน Future เพื่อให้ FutureBuilder จัดการ state ได้เอง
  Future<List<NotionModel>> _fetchNotions() async {
    final user = await AuthService.getCurrentUser();
    if (user is LawModel) {
      if (mounted) setState(() => law = user);
      return NotionDomain.getByVillage(user.villageId);
    }
    return [];
  }

  /// ใช้รีโหลด: เซ็ต _notions = _fetchNotions() ใหม่เสมอ ให้ FutureBuilder เข้าสถานะ waiting
  Future<void> _loadNotions() async {
    setState(() {
      _notions = _fetchNotions();
    });
    await _notions;
  }

  /// รีโหลดพร้อม loading overlay สำหรับเมื่อกลับจากหน้า add/edit
  Future<void> _refreshWithOverlay() async {
    if (_isRefreshing) return; // ป้องกัน multiple calls

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
      await _refreshWithOverlay(); // ใช้ loading overlay
    }
  }

  Future<void> _navigateToEdit(NotionModel notion) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LawNotionEditPage(notion: notion)),
    );
    if (result == true) {
      await _refreshWithOverlay(); // ใช้ loading overlay
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
      // แสดง loading ระหว่างลบ
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

  Widget _buildNotionImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
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
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: ThemeColors.beige,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: ThemeColors.beige,
              child: const Icon(
                Icons.broken_image_outlined,
                color: ThemeColors.earthClay,
                size: 32,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeChip(String? type) {
    if (type == null || type.isEmpty) return const SizedBox.shrink();

    Color chipColor;
    Color textColor;
    String displayText;

    switch (type.toUpperCase()) {
      case 'SECURITY':
        chipColor = ThemeColors.clayOrange;
        textColor = Colors.white;
        displayText = 'ความปลอดภัย';
        break;
      case 'MAINTENANCE':
        chipColor = ThemeColors.oliveGreen;
        textColor = Colors.white;
        displayText = 'ซ่อมบำรุง';
        break;
      case 'GENERAL':
        chipColor = ThemeColors.warmStone;
        textColor = Colors.white;
        displayText = 'ข้อมูลทั่วไป';
        break;
      case 'SOCIAL':
        chipColor = ThemeColors.softTerracotta;
        textColor = Colors.white;
        displayText = 'กิจกรรม';
        break;
      default:
        chipColor = ThemeColors.earthClay;
        textColor = Colors.white;
        displayText = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
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
        style: TextStyle(
          color: textColor,
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
                  valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
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
            side: BorderSide(
              color: Color(0x4DD8CAB8),
              width: 1,
            ),
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
              child: FutureBuilder<List<NotionModel>>(
                future: _notions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting || _notions == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.softBrown),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: ThemeColors.burntOrange),
                          const SizedBox(height: 16),
                          const Text(
                            'เกิดข้อผิดพลาด',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeColors.softBrown),
                          ),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}', style: const TextStyle(color: ThemeColors.earthClay), textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.article_outlined, size: 64, color: ThemeColors.earthClay),
                          SizedBox(height: 16),
                          Text(
                            'ไม่มีข่าวสารในขณะนี้',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: ThemeColors.softBrown),
                          ),
                          SizedBox(height: 8),
                          Text('แตะปุ่ม + เพื่อเพิ่มข่าวสารใหม่', style: TextStyle(color: ThemeColors.earthClay)),
                        ],
                      ),
                    );
                  }

                  final notions = snapshot.data!;
                  return RefreshIndicator(
                    color: ThemeColors.softBrown,
                    backgroundColor: ThemeColors.ivoryWhite,
                    onRefresh: () async {
                      await _loadNotions();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notions.length,
                      itemBuilder: (context, index) {
                        final notion = notions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildNotionImage(notion.img),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notion.header ?? 'ไม่มีหัวข้อ',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: ThemeColors.softBrown,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildTypeChip(notion.type),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (notion.description != null && notion.description!.isNotEmpty)
                                          Text(
                                            notion.description!,
                                            style: const TextStyle(
                                              color: ThemeColors.earthClay,
                                              fontSize: 14,
                                              height: 1.3,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule, size: 14, color: ThemeColors.earthClay),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _formatDate(notion.createDate),
                                                style: const TextStyle(fontSize: 12, color: ThemeColors.earthClay),
                                              ),
                                            ),
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(20),
                                                onTap: () => _navigateToEdit(notion),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  child: const Icon(Icons.edit_outlined, color: ThemeColors.burntOrange, size: 20),
                                                ),
                                              ),
                                            ),
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(20),
                                                onTap: () => _confirmDelete(notion),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  child: const Icon(Icons.delete_outline, color: ThemeColors.softTerracotta, size: 20),
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
                  );
                },
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