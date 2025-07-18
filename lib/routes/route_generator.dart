import 'package:flutter/material.dart';
import 'package:fullproject/main.dart';
import 'package:fullproject/pages/admin/admin_form_page.dart';
import 'package:fullproject/pages/admin/admin_list_page.dart';
import 'package:fullproject/pages/house/dashboard.dart';
import 'package:fullproject/pages/law/dashboard.dart';
import 'package:fullproject/pages/notfound_age.dart';
import 'package:fullproject/pages/welcome_page.dart';
import 'package:fullproject/pages/login_page.dart';
import '../pages/law/complaint/complaint_list_page.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String? routeName = settings.name;
    final Object? arguments = settings.arguments;
    switch (routeName) {
      case AppRoutes.login:
        return _createRoute(const LoginPage());
      case AppRoutes.home:
        return _createRoute(const WelcomePage());
      case AppRoutes.notFound:
        return _createRoute(const NotFoundPage());
      case AppRoutes.adminForm:
        return _createRoute(const AdminFormPage());
      case AppRoutes.adminList:
        return _createRoute(const AdminListPage());
      case AppRoutes.houseDashboard:
        return _createRoute(const HouseDashboardPage());
      case AppRoutes.lawDashboard:
        final args = settings.arguments as Map<String, dynamic>;
        return _createRoute(
          LawDashboardPage(
            lawId: args['lawId'],
            villageId: args['villageId'],
          ),
        );

      case AppRoutes.lawComplaintList:
        return _createRoute(const ComplaintListPage());

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
