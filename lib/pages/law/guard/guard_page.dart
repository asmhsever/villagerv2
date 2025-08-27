import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/domains/guard_domain.dart';
import 'package:fullproject/models/guard_model.dart';
import 'package:fullproject/pages/law/guard/add_guard_page.dart';
import 'package:fullproject/pages/law/guard/edit_guard_page.dart';
import 'package:fullproject/config/supabase_config.dart';

class LawGuardListPage extends StatefulWidget {
  final int villageId;

  const LawGuardListPage({super.key, required this.villageId});

  @override
  State<LawGuardListPage> createState() => _LawGuardListPageState();
}

class _LawGuardListPageState extends State<LawGuardListPage> {
  // Theme Colors - เหมือน Committee Page
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
  static const Color mutedBurntSienna = Color(0xFFC8755A);
  static const Color danger = Color(0xFFDC3545);

  static const String _bucketName = 'guard';
  bool _isRefreshing = false;

  Future<void> _navigateToAddGuard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGuardPage(villageId: widget.villageId),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _navigateToEditGuard(GuardModel guard) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGuardPage(guard: guard),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmDelete(GuardModel guard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ivoryWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber, color: danger, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'ยืนยันการลบ',
                style: TextStyle(
                  color: earthClay,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'ต้องการลบเจ้าหน้าที่ ${_getDisplayName(guard)} ใช่หรือไม่?',
            style: TextStyle(color: warmStone, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'ยกเลิก',
                style: TextStyle(color: warmStone),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: danger,
                foregroundColor: ivoryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmed) return;

    setState(() => _isRefreshing = true);
    try {
      await GuardDomain.delete(guard.guardId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: ivoryWhite, size: 20),
              const SizedBox(width: 8),
              Text('ลบเจ้าหน้าที่สำเร็จ'),
            ],
          ),
          backgroundColor: oliveGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: ivoryWhite, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('ลบไม่สำเร็จ: $e')),
            ],
          ),
          backgroundColor: danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        setState(() {});
      }
    }
  }

  String _getDisplayName(GuardModel guard) {
    final full = '${guard.firstName ?? ''} ${guard.lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : (guard.nickname ?? 'ไม่ระบุชื่อ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivoryWhite,
      appBar: AppBar(
        title: const Text(
          'รายชื่อเจ้าหน้าที่รักษาความปลอดภัย',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: softBrown,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToAddGuard,
            tooltip: 'เพิ่มเจ้าหน้าที่ใหม่',
          ),
        ],
      ),
      body: FutureBuilder<List<GuardModel>>(
        future: GuardDomain.getByVillageId(widget.villageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(softBrown),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูลเจ้าหน้าที่...',
                    style: TextStyle(color: earthClay, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: mutedBurntSienna, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      color: clayOrange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: mutedBurntSienna, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: burntOrange,
                      foregroundColor: ivoryWhite,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: sandyTan.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: warmStone.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.security, size: 64, color: earthClay),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีข้อมูลเจ้าหน้าที่',
                    style: TextStyle(
                      color: earthClay,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ยังไม่มีเจ้าหน้าที่ในหมู่บ้านนี้',
                    style: TextStyle(color: warmStone, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddGuard,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มเจ้าหน้าที่ใหม่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: oliveGreen,
                      foregroundColor: ivoryWhite,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final guards = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info with Add Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: beige.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: warmStone.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.security, color: softBrown, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'จำนวนเจ้าหน้าที่: ${guards.length} คน',
                              style: TextStyle(
                                color: earthClay,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: oliveGreen.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isRefreshing ? null : _navigateToAddGuard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: oliveGreen,
                          foregroundColor: ivoryWhite,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 4),
                            Text('เพิ่ม', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Guards List
                Expanded(
                  child: ListView.builder(
                    itemCount: guards.length,
                    itemBuilder: (context, index) {
                      final guard = guards[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _buildGuardCard(guard, index),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuardCard(GuardModel guard, int index) {
    // สีสำหรับแต่ละ card ที่หมุนเวียน
    final cardColors = [
      softBrown,
      burntOrange,
      oliveGreen,
      softTerracotta,
      clayOrange,
      mutedBurntSienna,
    ];
    final cardColor = cardColors[index % cardColors.length];

    return Card(
      elevation: 4,
      shadowColor: cardColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ivoryWhite, cardColor.withOpacity(0.1)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Avatar, Title and Action Buttons
              Row(
                children: [
                  _buildGuardAvatar(guard, cardColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayName(guard),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: oliveGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: oliveGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: oliveGreen,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ปฏิบัติงาน',
                                style: TextStyle(
                                  color: oliveGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ปุ่ม Edit
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: burntOrange.withOpacity(0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: burntOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _isRefreshing ? null : () => _navigateToEditGuard(guard),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.edit,
                            color: burntOrange,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ปุ่ม Delete
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: danger.withOpacity(0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _isRefreshing ? null : () => _confirmDelete(guard),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.delete_outline,
                            color: danger,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Guard Details แบบ horizontal
              Row(
                children: [
                  // รหัสเจ้าหน้าที่
                  Expanded(
                    child: _buildCompactDetailItem(
                      label: 'รหัส',
                      value: guard.guardId.toString(),
                      color: cardColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // เบอร์โทร
                  Expanded(
                    child: _buildCompactDetailItem(
                      label: 'เบอร์โทร',
                      value: guard.phone ?? 'ไม่ระบุ',
                      color: cardColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ชื่อเล่น
                  Expanded(
                    child: _buildCompactDetailItem(
                      label: 'ชื่อเล่น',
                      value: guard.nickname ?? 'ไม่ระบุ',
                      color: cardColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuardAvatar(GuardModel guard, Color cardColor) {
    final url = _resolveImageUrl(_bucketName, guard.img);
    final initials = _getInitials(_getDisplayName(guard));

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: url == null
          ? Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';

    String getFirstChar(String s) {
      final it = s.runes.iterator;
      return it.moveNext() ? String.fromCharCode(it.current).toUpperCase() : '?';
    }

    String getLastChar(String s) {
      int? last;
      for (final r in s.runes) {
        last = r;
      }
      return String.fromCharCode(last ?? 63).toUpperCase();
    }

    return parts.length == 1
        ? getFirstChar(parts.first)
        : '${getFirstChar(parts.first)}${getLastChar(parts.last)}';
  }

  String? _resolveImageUrl(String bucket, String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;
    final s = pathOrUrl.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final client = SupabaseConfig.client;
    return client.storage.from(bucket).getPublicUrl(s);
  }

  // Helper Widget สำหรับแสดงข้อมูลแบบกะทัดรัด
  Widget _buildCompactDetailItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: earthClay,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}