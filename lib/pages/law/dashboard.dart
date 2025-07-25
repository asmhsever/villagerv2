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
        AppNavigation.navigateTo(AppRoutes.login);
      }
    } catch (e) {
      AppNavigation.navigateTo(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      final List<_DashboardItem> items = [
        _DashboardItem(Icons.receipt_long, 'ค่าส่วนกลาง', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BillPage()),
          );
        }),
        _DashboardItem(Icons.report_problem, 'คำร้องเรียน', () {
          AppNavigation.navigateTo(AppRoutes.notFound);
        }),
        _DashboardItem(Icons.announcement, 'ข่าวสาร', () {
          AppNavigation.navigateTo(AppRoutes.notFound);
        }),
        _DashboardItem(Icons.pets, 'สัตว์เลี้ยง', () {
          AppNavigation.navigateTo(AppRoutes.notFound);
        }),
        _DashboardItem(Icons.people, 'ลูกบ้าน', () {
          AppNavigation.navigateTo(AppRoutes.notFound);
        }),
        _DashboardItem(Icons.meeting_room, 'ประชุม', () {
          AppNavigation.navigateTo(AppRoutes.notFound);
        }),
      ];

      return Scaffold(
        appBar: AppBar(title: const Text('แดชบอร์ดนิติ')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("user id : \${lawModel!.userId}"),
                    Text("law id : \${lawModel!.lawId}"),
                    Text("village id : \${lawModel!.villageId}"),
                    Text("firstname : \${lawModel!.firstName}"),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: item.onTap,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.icon, size: 48),
                              const SizedBox(height: 8),
                              Text(item.label, style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      );
    }
  }
}

class _DashboardItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _DashboardItem(this.icon, this.label, this.onTap);
}
