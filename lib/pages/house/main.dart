import 'package:flutter/material.dart';
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/extensions/context_extensions.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/models/notion_model.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/pages/house/bill.dart';
import 'package:fullproject/pages/house/complaint/complaint.dart';
import 'package:fullproject/pages/house/house.dart';
import 'package:fullproject/pages/house/notion.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/services/image_service.dart';

class HouseMainPage extends StatefulWidget {
  const HouseMainPage({super.key});

  @override
  State<HouseMainPage> createState() => _HouseMainPageState();
}

class _HouseMainPageState extends State<HouseMainPage> {
  HouseModel? houseModel;
  bool isLoading = true;
  int _currentIndex = 0;

  // สร้าง screens หลังจากได้ข้อมูล houseModel แล้ว
  List<Widget> _getScreens() {
    if (houseModel == null) {
      return [
        Center(child: CircularProgressIndicator()),
        Center(child: CircularProgressIndicator()),
        Center(child: CircularProgressIndicator()),
        Center(child: CircularProgressIndicator()),
      ];
    }

    return [
      HouseNotionsPage(villageId: houseModel!.villageId),
      HouseBillPage(houseId: houseModel!.houseId),
      HouseComplaintPage(houseId: houseModel!.houseId),
      HouseDetailPage(),
    ];
  }

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();

      if (user is HouseModel) {
        setState(() {
          houseModel = user;
          isLoading = false;
        });
      } else {
        // ไม่ใช่ admin หรือไม่มีข้อมูล
        AppNavigation.navigateTo(AppRoutes.login);
      }
    } catch (e) {
      AppNavigation.navigateTo(AppRoutes.login);
    }
  }

  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      final _screens = _getScreens();
      return Scaffold(
        // appBar: AppBar(title: Text("ssss")),
        backgroundColor: Color(0xFFD8CAB8),
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color(0xFFA47551),
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.circle_notifications_outlined),
              label: 'ข่าวสาร',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on_outlined),
              label: 'บิล',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_add_outlined),
              label: 'ร้องเรียน',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'ข้อมูลบ้าน',
            ),
          ],
        ),
      );
    }
  }
}
