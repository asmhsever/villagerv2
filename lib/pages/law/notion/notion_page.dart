import 'package:flutter/material.dart';
import 'package:fullproject/pages/law/notion/notion_edit_page.dart';
import 'package:intl/intl.dart';
import 'package:fullproject/models/notion_model.dart';
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/notion/notion_add_page.dart';

class LawNotionPage extends StatefulWidget {
  const LawNotionPage({super.key});

  @override
  State<LawNotionPage> createState() => _LawNotionPageState();
}

class _LawNotionPageState extends State<LawNotionPage> {
  Future<List<NotionModel>>? _notions;
  LawModel? law;

  @override
  void initState() {
    super.initState();
    _loadNotions();
  }

  Future<void> _loadNotions() async {
    final user = await AuthService.getCurrentUser();
    if (user is LawModel) {
      setState(() => law = user);
      final results = await NotionDomain.getByVillage(user.villageId);
      setState(() {
        _notions = Future.value(results);
      });
    } else {
      _notions = Future.value([]);
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
    if (result == true) _loadNotions();
  }

  Future<void> _navigateToEdit(NotionModel notion) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LawNotionEditPage(notion: notion)),
    );
    if (result == true) _loadNotions();
  }

  Future<void> _confirmDelete(NotionModel notion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFFFDF6),
        title: const Text(
          "ยืนยันการลบ",
          style: TextStyle(
            color: Color(0xFFA47551),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "คุณต้องการลบข่าว '${notion.header}' ใช่หรือไม่?",
          style: const TextStyle(color: Color(0xFFBFA18F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFBFA18F),
            ),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE08E45),
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
      await NotionDomain.delete(notion.notionId);
      _loadNotions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ลบข่าวสารเรียบร้อยแล้ว'),
            backgroundColor: const Color(0xFFA3B18A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Widget _buildNotionImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8CAB8), width: 1),
        ),
        child: const Icon(
          Icons.article_outlined,
          color: Color(0xFFBFA18F),
          size: 32,
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33BFA18F), // Using direct hex with alpha
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              color: const Color(0xFFF5F0E1),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA47551)),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFF5F0E1),
              child: const Icon(
                Icons.broken_image_outlined,
                color: Color(0xFFBFA18F),
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
        chipColor = const Color(0xFFCC7748); // Clay Orange - เร่งด่วน
        textColor = Colors.white;
        displayText = 'ความปลอดภัย';
        break;
      case 'MAINTENANCE':
        chipColor = const Color(0xFFA3B18A); // Olive Green - ดูแลรักษา
        textColor = Colors.white;
        displayText = 'ซ่อมบำรุง';
        break;
      case 'GENERAL':
        chipColor = const Color(0xFFC7B9A5); // Warm Stone - ทั่วไป
        textColor = Colors.white;
        displayText = 'ข้อมูลทั่วไป';
        break;
      case 'SOCIAL':
        chipColor = const Color(0xFFD48B5C); // Soft Terracotta - สังคม
        textColor = Colors.white;
        displayText = 'กิจกรรม';
        break;
      default:
        chipColor = const Color(0xFFBFA18F);
        textColor = Colors.white;
        displayText = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0x26000000),
            blurRadius: 3,
            offset: const Offset(0, 1),
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: MaterialColor(0xFFA47551, const {
          50: Color(0xFFF5F2EF),
          100: Color(0xFFE5DDD6),
          200: Color(0xFFD4C5BB),
          300: Color(0xFFC2ADA0),
          400: Color(0xFFB5998B),
          500: Color(0xFFA47551),
          600: Color(0xFF9C6D4A),
          700: Color(0xFF926240),
          800: Color(0xFF885837),
          900: Color(0xFF764627),
        }),
        scaffoldBackgroundColor: const Color(0xFFFFFDF6),
        cardColor: const Color(0xFFD8CAB8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFA47551),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Color(0xFFBFA18F),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE08E45),
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFFFFDF6),
          elevation: 3,
          shadowColor: Color(0x4DBFA18F), // Using direct hex with alpha
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(
              color: Color(0x4DD8CAB8), // Using direct hex with alpha
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFDF6),
                Color(0xFFF5F0E1),
              ],
            ),
          ),
          child: FutureBuilder<List<NotionModel>>(
            future: _notions,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA47551)),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: const Color(0xFFE08E45),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'เกิดข้อผิดพลาด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFA47551),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: TextStyle(color: const Color(0xFFBFA18F)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 64,
                        color: const Color(0xFFBFA18F),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่มีข่าวสารในขณะนี้',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFA47551),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'แตะปุ่ม + เพื่อเพิ่มข่าวสารใหม่',
                        style: TextStyle(color: const Color(0xFFBFA18F)),
                      ),
                    ],
                  ),
                );
              }

              final notions = snapshot.data!;
              return ListView.builder(
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
                            // รูปภาพ
                            _buildNotionImage(notion.img),
                            const SizedBox(width: 16),

                            // เนื้อหา
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // หัวข้อและประเภท
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notion.header ?? 'ไม่มีหัวข้อ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFFA47551),
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

                                  // รายละเอียด
                                  if (notion.description != null && notion.description!.isNotEmpty)
                                    Text(
                                      notion.description!,
                                      style: const TextStyle(
                                        color: Color(0xFFBFA18F),
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 12),

                                  // วันที่และปุ่มจัดการ
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: const Color(0xFFBFA18F),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _formatDate(notion.createDate),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFBFA18F),
                                          ),
                                        ),
                                      ),

                                      // ปุ่มแก้ไข
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () => _navigateToEdit(notion),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: const Icon(
                                              Icons.edit_outlined,
                                              color: Color(0xFFE08E45),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ปุ่มลบ
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () => _confirmDelete(notion),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              color: Color(0xFFD48B5C),
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
              );
            },
          ),
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