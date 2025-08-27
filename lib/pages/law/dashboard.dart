// File: lib/pages/law/dashboard.dart
// Purpose: Wire dashboard cards to named routes for Guard/Fund/Committee.

import 'package:flutter/material.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/pages/law/bill/bill_page.dart';
import 'package:fullproject/services/auth_service.dart';

class LawDashboardPage extends StatefulWidget {
  const LawDashboardPage({super.key});

  @override
  State<LawDashboardPage> createState() => _LawDashboardPageState();
}

class _LawDashboardPageState extends State<LawDashboardPage> {
  LawModel? lawModel;
  bool isLoading = true;

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
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user is LawModel) {
        setState(() {
          lawModel = user;
          isLoading = false;
        });
      } else {
        if (mounted) AppNavigation.navigateTo(AppRoutes.login);
      }
    } catch (_) {
      if (mounted) AppNavigation.navigateTo(AppRoutes.login);
    }
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
      AppNavigation.navigateTo(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _ivoryWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_softBrown),
              ),
              SizedBox(height: 16),
              Text(
                'กำลังโหลดข้อมูล...',
                style: TextStyle(color: _earthClay, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (lawModel == null) {
      return const Scaffold(
        backgroundColor: _ivoryWhite,
        body: Center(
          child: Text(
            'ไม่พบข้อมูลผู้ใช้',
            style: TextStyle(color: _earthClay, fontSize: 16),
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
          if (mounted) setState(() {});
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
        icon: Icons.pets,
        label: 'สัตว์เลี้ยง',
        color: _oliveGreen,
        onTap: () => AppNavigation.navigateTo(AppRoutes.notFound),
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
      // --- NEW WIRED ROUTES ---
      _DashboardItem(
        icon: Icons.person_pin,
        label: 'เจ้าหน้าที่',
        color: _softBrown,
        onTap: () => AppNavigation.navigateTo(
          AppRoutes.lawGuard,
          arguments: {
            'villageId': lawModel!.villageId,
          }, // why: list depends on village
        ),
      ),

      _DashboardItem(
        icon: Icons.account_balance_wallet,
        label: 'กองทุน',
        color: _oliveGreen,
        onTap: () => AppNavigation.navigateTo(
          AppRoutes.lawFund,
          arguments: {
            'villageId': lawModel!.villageId,
          }, // why: list depends on village
        ),
      ),
      _DashboardItem(
        icon: Icons.people_alt,
        label: 'คณะกรรมการ',
        color: _burntOrange,
        onTap: () => AppNavigation.navigateTo(
          AppRoutes.committeeList,
          arguments: {
            'villageId': lawModel!.villageId,
          }, // why: list depends on village
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
          IconButton(icon: const Icon(Icons.person), onPressed: () {}),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadCurrentUser,
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
              const Text(
                'เมนูหลัก',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _softBrown,
                ),
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
        onPressed: () {},
        backgroundColor: _burntOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.person),
      ),
    );
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
                      errorBuilder: (context, error, stackTrace) => Text(
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
                    lawModel!.firstName != null ? lawModel!.firstName! : 'N',
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
                  lawModel!.firstName!,
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
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.location_on,
            title: 'หมู่บ้าน',
            value: 'ID: ${lawModel!.villageId}',
            color: _oliveGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.badge,
            title: 'รหัสผู้ใช้',
            value: 'ID: ${lawModel!.userId}',
            color: _softTerracotta,
          ),
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
    return Container(
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
          Text(title, style: const TextStyle(fontSize: 12, color: _warmStone)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _earthClay,
            ),
          ),
        ],
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
