import 'package:flutter/material.dart';
import 'package:fullproject/extensions/context_extensions.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/pages/welcome_page.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/theme/Color.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '้login',
      home: Scaffold(
        //      appBar: AppBar(title: Text("--"), backgroundColor: ThemeColors.earthClay),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                // Color(0xFF3C82F6), // Sky Blue
                ThemeColors.softBrown, // Royal Blue
                ThemeColors.earthClay,
                ThemeColors.softBrown,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Background Image Layer (optional - if you want to add background)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: OverflowBox(
                    alignment: Alignment.bottomCenter,
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        'assets/images/login/login_bg.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              // Main Content Layer
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(height: 50),

                    // Welcome Text
                    Center(
                      child: Text(
                        "ยินดีต้อนรับ",
                        style: TextStyle(fontSize: 50, color: Colors.white),
                      ),
                    ),

                    // App Name
                    Center(
                      child: Text(
                        "Nivilla",
                        style: TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),

                    SizedBox(height: 10),

                    // Logo
                    Image.asset('assets/images/shared/logo2.png', scale: 1.2),

                    // Login Form Container
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Color(0xFFF5F7FA),
                      ),
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.all(40),
                      child: Column(children: [LoginForm()]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formkey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      print("login");
    });

    try {
      final result = await AuthService.login(
        _userController.text.trim(),
        _passController.text,
      );

      if (result['success']) {
        print(result['role']);
        switch (result['role']) {
          case 'admin':
            AppNavigation.navigateTo(AppRoutes.adminDashboard);
            break;
          case 'house':
            AppNavigation.navigateTo(AppRoutes.houseDashboard);
            break;
          case 'law':
            AppNavigation.navigateTo(AppRoutes.lawDashboard);
            break;
          default:
            AppNavigation.navigateTo(AppRoutes.notFound);
        }
      } else {
        _showErrorDialog(result['message']);
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการเข้าสู่ระบบ');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('เกิดข้อผิดพลาด'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _forgetPassword() {}

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formkey,
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text("เข้าสู่ระบบ"),
          SizedBox(height: 20),
          TextFormField(
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกชื่อผู้ใช้';
              }
              return null;
            },
            controller: _userController,
            decoration: InputDecoration(
              labelText: 'ชื่อผู้ใช้',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: ThemeColors.softBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: ThemeColors.focusedBrown),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 15),
          TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "กรุณากรอกรหัส";
              }
              return null;
            },
            controller: _passController,
            decoration: InputDecoration(
              labelText: 'รหัสผ่าน',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: ThemeColors.softBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: ThemeColors.focusedBrown),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,

            child: _isLoading
                ? CircularProgressIndicator(color: Colors.amberAccent)
                : Text("เข้าสู่ระบบ"),

            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 105, vertical: 12),
              backgroundColor: ThemeColors.softTerracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          SizedBox(height: 5),
          Text("ลืมรหัสผ่าน"),
        ],
      ),
    );
  }
}
