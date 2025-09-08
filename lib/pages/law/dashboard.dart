// File: lib/pages/law/dashboard.dart
// Purpose: Wire dashboard cards to named routes for Guard/Fund/Committee and Law management.

import 'package:flutter/material.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/pages/law/profile/law_page.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/pages/law/bill/bill_page.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/domains/law_domain.dart';

class LawDashboardPage extends StatefulWidget {
  const LawDashboardPage({super.key});

  @override
  State<LawDashboardPage> createState() => _LawDashboardPageState();
}

class _LawDashboardPageState extends State<LawDashboardPage> {
  LawModel? lawModel;
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic> dashboardStats = {};

  // Theme
  static const Color _softBrown = Color(0xFFA47551);
  static const Color _ivoryWhite = Color(0xFFFFFDF6);
  static const Color _sandyTan = Color(0xFFD8CAB8);
  static const Color _earthClay = Color(0xFFBFA18F);
  static const Color _warmStone = Color(0xFFC7B9A5);
  static const Color _oliveGreen = Color(0xFFA3B18A);
  static const Color _burntOrange = Color(0xFFE08E45);
  static const Color _softTerracotta = Color(0xFFD48B5C);

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load current user
      await _loadCurrentUser();

      // Load dashboard statistics if user is loaded
      if (lawModel != null) {
        await _loadDashboardStats();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}';
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (!mounted) return;

      if (user is LawModel) {
        // Get full user data from database
        print(user.toJson());
        final fullUserData = await LawDomain.getById(user.lawId!);
        setState(() {
          lawModel = fullUserData;
        });
      } else {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'ไม่สามารถโหลดข้อมูลผู้ใช้ได้';
        });
        // Navigate to login after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) AppNavigation.navigateTo(AppRoutes.login);
        });
      }
      rethrow;
    }
  }

  Future<void> _loadDashboardStats() async {
    if (lawModel == null) return;

    try {
      // Load village statistics
      final villageStats = await LawDomain.getVillageStats(lawModel!.villageId);
      final totalPeople = await LawDomain.countPeopleInVillage(
        lawModel!.villageId,
      );
      final genderCount = await LawDomain.getCountByGender(lawModel!.villageId);

      setState(() {
        dashboardStats = {
          'village_stats': villageStats,
          'total_people': totalPeople,
          'gender_count': genderCount,
          'last_updated': DateTime.now(),
        };
      });
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      // ไม่ throw error เพราะไม่ต้องการให้ขัดขวางการแสดง dashboard หลัก
    }
  }

  Future<void> _refreshDashboard() async {
    await _initializeDashboard();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ยืนยันการออกจากระบบ',
          style: TextStyle(color: _softBrown, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'คุณต้องการออกจากระบบใช่หรือไม่?',
          style: TextStyle(color: _earthClay),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _warmStone),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.logout();
      if (mounted) AppNavigation.navigateTo(AppRoutes.login);
    }
  }

  void _navigateToLawPage() async {
    if (lawModel != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LawPage(villageId: lawModel!.villageId),
        ),
      );
      // Refresh after returning
      if (mounted) {
        _refreshDashboard();
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'เกิดข้อผิดพลาด',
          style: TextStyle(color: _softBrown, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(color: _earthClay)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง', style: TextStyle(color: _burntOrange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading State
    if (isLoading) {
      return Scaffold(
        backgroundColor: _ivoryWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_softBrown),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                'กำลังโหลดแดชบอร์ด...',
                style: TextStyle(
                  color: _earthClay,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'โปรดรอสักครู่',
                style: TextStyle(color: _warmStone, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Error State
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: _ivoryWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 24),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: _earthClay,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _initializeDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _burntOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No User State
    if (lawModel == null) {
      return const Scaffold(
        backgroundColor: _ivoryWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: _warmStone),
              SizedBox(height: 16),
              Text(
                'ไม่พบข้อมูลผู้ใช้',
                style: TextStyle(color: _earthClay, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final List<_DashboardItem> items = [
      _DashboardItem(
        icon: Icons.receipt_long,
        label: 'ค่าส่วนกลาง',
        color: _burntOrange,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BillPage()),
          );
          if (mounted) _refreshDashboard();
        },
      ),
      _DashboardItem(
        icon: Icons.report_problem,
        label: 'คำร้องเรียน',
        color: Colors.red.shade400,
        onTap: () => AppNavigation.navigateTo(AppRoutes.lawComplaint),
      ),
      _DashboardItem(
        icon: Icons.announcement,
        label: 'ข่าวสาร',
        color: _softTerracotta,
        onTap: () => AppNavigation.navigateTo(AppRoutes.lawNotion),
      ),
      _DashboardItem(
        icon: Icons.people,
        label: 'ลูกบ้าน',
        color: _softBrown,
        onTap: () => AppNavigation.navigateTo(
          AppRoutes.lawVillage,
          arguments: {'villageId': lawModel!.villageId},
        ),
      ),
      _DashboardItem(
        icon: Icons.meeting_room,
        label: 'ประชุม',
        color: _warmStone,
        onTap: () => AppNavigation.navigateTo(AppRoutes.notFound),
      ),
      _DashboardItem(
        icon: Icons.person_pin,
        label: 'เจ้าหน้าที่',
        color: _softBrown,
        onTap: () => AppNavigation.navigateTo(
          AppRoutes.lawGuard,
          arguments: {'villageId': lawModel!.villageId},
        ),
      ),
      _DashboardItem(
        icon: Icons.account_balance_wallet,
        label: 'กองทุน',
        color: _oliveGreen,
        onTap: () => AppNavigation.navigateTo(
          AppRoutes.lawFund,
          arguments: {'villageId': lawModel!.villageId},
        ),
      ),
      _DashboardItem(
        icon: Icons.people_alt,
        label: 'คณะกรรมการ',
        color: _burntOrange,
        onTap: () => AppNavigation.navigateTo(
          AppRoutes.committeeList,
          arguments: {'villageId': lawModel!.villageId},
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: _ivoryWhite,
      appBar: AppBar(
        title: const Text(
          'แดชบอร์ดนิติ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _softBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToLawPage,
            tooltip: 'ข้อมูลส่วนตัว',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'ออกจากระบบ',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: _softBrown,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildQuickStats(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'เมนูหลัก',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _softBrown,
                    ),
                  ),
                  if (dashboardStats.isNotEmpty &&
                      dashboardStats['last_updated'] != null)
                    Text(
                      'อัพเดต: ${_formatLastUpdated(dashboardStats['last_updated'])}',
                      style: const TextStyle(fontSize: 12, color: _warmStone),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildDashboardCard(items[index]),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToLawPage,
        backgroundColor: _burntOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'ข้อมูลส่วนตัว',
        child: const Icon(Icons.person),
      ),
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else {
      return '${difference.inDays} วันที่แล้ว';
    }
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [_softBrown, _burntOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _warmStone.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: lawModel!.img != null && lawModel!.img!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      lawModel!.img!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Text(
                        lawModel!.firstName != null &&
                                lawModel!.firstName!.isNotEmpty
                            ? lawModel!.firstName!.substring(0, 1).toUpperCase()
                            : 'N',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Text(
                    lawModel!.firstName != null &&
                            lawModel!.firstName!.isNotEmpty
                        ? lawModel!.firstName!.substring(0, 1).toUpperCase()
                        : 'N',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สวัสดี',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  lawModel!.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'นิติบุคคลหมู่บ้าน',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _navigateToLawPage,
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              tooltip: 'ดูข้อมูลส่วนตัว',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.location_on,
          title: 'หมู่บ้าน',
          value: 'ID: ${lawModel!.villageId}',
          color: _oliveGreen,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.people,
          title: 'ประชากร',
          value: dashboardStats['total_people'] != null
              ? '${dashboardStats['total_people']} คน'
              : 'กำลังโหลด...',
          color: _softTerracotta,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _sandyTan.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: _warmStone.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: _warmStone),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _earthClay,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(_DashboardItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sandyTan.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _warmStone.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  item.color.withValues(alpha: 0.05),
                  item.color.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(item.icon, size: 36, color: item.color),
                ),
                const SizedBox(height: 12),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _earthClay,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _DashboardItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
