import 'package:flutter/material.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/pages/law/profile/profile_page.dart';
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
        if (mounted) {
          AppNavigation.navigateTo(AppRoutes.login);
        }
      }
    } catch (e) {
      if (mounted) {
        AppNavigation.navigateTo(AppRoutes.login);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // เพิ่ม logout logic ตรงนี้
      AppNavigation.navigateTo(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('กำลังโหลดข้อมูล...'),
            ],
          ),
        ),
      );
    }

    if (lawModel == null) {
      return const Scaffold(
        body: Center(child: Text('ไม่พบข้อมูลผู้ใช้')),
      );
    }

    final List<_DashboardItem> items = [
      _DashboardItem(
        icon: Icons.receipt_long,
        label: 'ค่าส่วนกลาง',
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BillPage()),
          );
        },
      ),
      _DashboardItem(
        icon: Icons.report_problem,
        label: 'คำร้องเรียน',
        color: Colors.red,
        onTap: () {
          AppNavigation.navigateTo(AppRoutes.notFound);
        },
      ),
      _DashboardItem(
        icon: Icons.announcement,
        label: 'ข่าวสาร',
        color: Colors.orange,
        onTap: () {
          AppNavigation.navigateTo(AppRoutes.notion);
        },
      ),
      _DashboardItem(
        icon: Icons.pets,
        label: 'สัตว์เลี้ยง',
        color: Colors.green,
        onTap: () {
          AppNavigation.navigateTo(AppRoutes.notFound);
        },
      ),
      _DashboardItem(
        icon: Icons.people,
        label: 'ลูกบ้าน',
        color: Colors.purple,
        onTap: () async {
          if (lawModel != null) {
            AppNavigation.navigateTo(
              AppRoutes.resident,
              arguments: {'villageId': lawModel!.villageId},
            );
          }
        },
      ),
      _DashboardItem(
        icon: Icons.meeting_room,
        label: 'ประชุม',
        color: Colors.teal,
        onTap: () {
          AppNavigation.navigateTo(AppRoutes.notFound);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('แดชบอร์ดนิติ'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LawProfilePage(lawId: lawModel!.lawId),
                    ),
                  );
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('โปรไฟล์'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadCurrentUser,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildWelcomeCard(),
                const SizedBox(height: 20),

                // Quick Stats
                _buildQuickStats(),
                const SizedBox(height: 20),

                // Menu Grid
                const Text(
                  'เมนูหลัก',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildDashboardCard(item);
                  },
                ),
                const SizedBox(height: 100), // เผื่อ scroll
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LawProfilePage(lawId: lawModel!.lawId),
            ),
          );
        },
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.person, color: Colors.white),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: lawModel!.hasProfileImage
                      ? ClipOval(
                    child: Image.network(
                      lawModel!.profileImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Text(
                            lawModel!.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  )
                      : Text(
                    lawModel!.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        lawModel!.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'นิติบุคคลหมู่บ้าน',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LawProfilePage(lawId: lawModel!.lawId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
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
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.badge,
            title: 'รหัสผู้ใช้',
            value: 'ID: ${lawModel!.userId}',
            color: Colors.orange,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(_DashboardItem item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                item.color.withValues(alpha: 0.1),
                item.color.withValues(alpha: 0.05),
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
                  color: item.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  item.icon,
                  size: 40,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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