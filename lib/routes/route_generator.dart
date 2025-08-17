import 'package:flutter/material.dart';
import 'package:fullproject/pages/admin/dashboard.dart';
import 'package:fullproject/pages/house/main.dart';
import 'package:fullproject/pages/law/dashboard.dart';
import 'package:fullproject/pages/law/house/house_page.dart';
import 'package:fullproject/pages/law/notion/notion_page.dart';
import 'package:fullproject/pages/notfound_age.dart';
import 'package:fullproject/pages/splash_page.dart';
import 'package:fullproject/pages/welcome_page.dart';
import 'package:fullproject/pages/login_page.dart';
import 'package:fullproject/pages/law/profile/profile_page.dart';

import 'package:fullproject/pages/law/complaint/complant_page.dart';

import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String? routeName = settings.name;
    switch (routeName) {
      case AppRoutes.login:
        return _createRoute(const LoginPage());
      case AppRoutes.home:
        return _createRoute(const WelcomePage());
      case AppRoutes.notFound:
        return _createRoute(const NotFoundPage());
      case AppRoutes.adminDashboard:
        return _createRoute(const AdminDashboardPage());
      case AppRoutes.houseDashboard:
        return _createRoute(const HouseMainPage());
      case AppRoutes.lawDashboard:
        return _createRoute(const LawDashboardPage());
      case AppRoutes.splash:
        return _createRoute(const SplashPage());
    // case AppRoutes.lawBill:
    //   return _createRoute(const BillPage());

      case AppRoutes.notion:
        return _createRoute(const LawNotionPage());

    // ✨ เพิ่ม complaint route
      case AppRoutes.complaint:
        return _createRoute(const ComplaintPage());

      case AppRoutes.resident:
        final args = settings.arguments as Map<String, dynamic>;
        final villageId = args['villageId'] as int;
        return _createRoute(LawHouseManagePage(villageId: villageId));
      case AppRoutes.LawProfilePage:
        final args = settings.arguments as Map<String, dynamic>?;
        final lawId = args?['lawId'] as int?;

        if (lawId == null) {
          return _createRoute(const NotFoundPage());
        }

        return _createRoute(LawProfilePage(lawId: lawId));

    /*case AppRoutes.animal:
        return _createRoute(const NotFoundPage());

      case AppRoutes.meeting:
        return _createRoute(const NotFoundPage());*/
      default:
        return _createRoute(const NotFoundPage());
    }
  }

  static PageRouteBuilder _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}