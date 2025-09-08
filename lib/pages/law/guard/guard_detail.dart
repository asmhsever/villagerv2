import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/models/guard_model.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/pages/law/guard/edit_guard_page.dart';
import 'package:fullproject/domains/guard_domain.dart';

class GuardDetailPage extends StatefulWidget {
  final GuardModel guard;

  const GuardDetailPage({super.key, required this.guard});

  @override
  State<GuardDetailPage> createState() => _GuardDetailPageState();
}

class _GuardDetailPageState extends State<GuardDetailPage> {
  // Theme Colors - เหมือน Guard List Page
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

  late GuardModel currentGuard;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    currentGuard = widget.guard;
  }

  Future<void> _navigateToEditGuard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGuardPage(guard: currentGuard),
      ),
    );

    if (result == true && mounted) {
      // รีเฟรชข้อมูลหลังจากแก้ไข
      await _refreshGuardData();
    }
  }

  Future<void> _refreshGuardData() async {
    setState(() => _isRefreshing = true);
    try {
      // ดึงข้อมูลล่าสุดจากฐานข้อมูล
      final guards = await GuardDomain.getByVillageId(currentGuard.villageId);
      final updatedGuard = guards.firstWhere(
            (g) => g.guardId == currentGuard.guardId,
        orElse: () => currentGuard,
      );

      if (mounted) {
        setState(() {
          currentGuard = updatedGuard;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการรีเฟรชข้อมูล: $e'),
            backgroundColor: danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
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
            'ต้องการลบเจ้าหน้าที่ ${_getDisplayName(currentGuard)} ใช่หรือไม่?',
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
      await GuardDomain.delete(currentGuard.guardId);
      if (!mounted) return;

      // กลับไปหน้าก่อนหน้าและส่งสัญญาณว่าได้ลบแล้ว
      Navigator.pop(context, true);

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
      }
    }
  }

  String _getDisplayName(GuardModel guard) {
    final full = '${guard.firstName ?? ''} ${guard.lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : (guard.nickname ?? 'ไม่ระบุชื่อ');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivoryWhite,
      appBar: AppBar(
        title: Text(
          'รายละเอียดเจ้าหน้าที่',
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
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _isRefreshing ? null : _navigateToEditGuard,
            tooltip: 'แก้ไขข้อมูล',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _isRefreshing ? null : _confirmDelete,
            tooltip: 'ลบเจ้าหน้าที่',
          ),
        ],
      ),
      body: _isRefreshing
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(softBrown),
            ),
            const SizedBox(height: 16),
            Text(
              'กำลังประมวลผล...',
              style: TextStyle(color: earthClay, fontSize: 14),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshGuardData,
        color: softBrown,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              _buildProfileCard(),
              const SizedBox(height: 20),

              // Contact Information
              _buildContactInfoCard(),
              const SizedBox(height: 20),

              // System Information
              _buildSystemInfoCard(),
              const SizedBox(height: 20),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Center(
        child: Card(
          elevation: 8,
          shadowColor: softBrown.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ivoryWhite, softBrown.withOpacity(0.1)],
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // รูปโปรไฟล์
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: softBrown.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: currentGuard.img != null && currentGuard.img!.isNotEmpty
                        ? BuildImage(
                      imagePath: currentGuard.img!,
                      tablePath: 'guard',
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      placeholder: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: softBrown,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: softBrown,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_getDisplayName(currentGuard)),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                        : Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: softBrown,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_getDisplayName(currentGuard)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ชื่อ-นามสกุล
                Text(
                  _getDisplayName(currentGuard),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Nickname
                if (currentGuard.nickname != null && currentGuard.nickname!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: oliveGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: oliveGreen.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'ชื่อเล่น: ${currentGuard.nickname}',
                      style: TextStyle(
                        color: oliveGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: oliveGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: oliveGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: oliveGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ปฏิบัติงานอยู่',
                        style: TextStyle(
                          color: oliveGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
    }

  Widget _buildContactInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: burntOrange.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ivoryWhite, burntOrange.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: burntOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.contact_phone, color: burntOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'ข้อมูลการติดต่อ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: earthClay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              icon: Icons.person,
              label: 'ชื่อ',
              value: currentGuard.firstName ?? 'ไม่ระบุ',
              color: burntOrange,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'นามสกุล',
              value: currentGuard.lastName ?? 'ไม่ระบุ',
              color: burntOrange,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              icon: Icons.phone,
              label: 'เบอร์โทร',
              value: currentGuard.phone ?? 'ไม่ระบุ',
              color: burntOrange,
              onTap: currentGuard.phone != null && currentGuard.phone!.isNotEmpty
                  ? () {
                // Copy to clipboard
                Clipboard.setData(ClipboardData(text: currentGuard.phone!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('คัดลอกหมายเลขโทรศัพท์แล้ว'),
                    backgroundColor: oliveGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: clayOrange.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ivoryWhite, clayOrange.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: clayOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: clayOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'ข้อมูลระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: earthClay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              icon: Icons.badge,
              label: 'รหัสเจ้าหน้าที่',
              value: currentGuard.guardId.toString(),
              color: clayOrange,
              onTap: () {
                Clipboard.setData(ClipboardData(text: currentGuard.guardId.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('คัดลอกรหัสเจ้าหน้าที่แล้ว'),
                    backgroundColor: oliveGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              icon: Icons.home,
              label: 'รหัสหมู่บ้าน',
              value: currentGuard.villageId.toString(),
              color: clayOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: warmStone,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.copy, color: color.withOpacity(0.7), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Edit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRefreshing ? null : _navigateToEditGuard,
            icon: const Icon(Icons.edit),
            label: const Text('แก้ไขข้อมูล'),
            style: ElevatedButton.styleFrom(
              backgroundColor: burntOrange,
              foregroundColor: ivoryWhite,
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Delete Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isRefreshing ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('ลบเจ้าหน้าที่'),
            style: OutlinedButton.styleFrom(
              foregroundColor: danger,
              side: BorderSide(color: danger, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}