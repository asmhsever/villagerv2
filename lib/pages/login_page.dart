import 'package:flutter/material.dart';
import 'package:fullproject/extensions/context_extensions.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/pages/admin/admin_form_page.dart';
import 'package:fullproject/pages/welcome_page.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/services/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '้login',
      home: Scaffold(
        //      appBar: AppBar(title: Text("--"), backgroundColor: Color(0xFFBFA18F)),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                // Color(0xFF3C82F6), // Sky Blue
                Color(0xFFA47551), // Royal Blue
                Color(0xFFBFA18F),
                Color(0xFFA47551),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 50),
              Center(
                child: Text(
                  "ยินดีต้อนรับ",
                  style: TextStyle(fontSize: 50, color: Colors.white),
                ),
              ),
              Center(
                child: Text(
                  "Nivilla",
                  style: TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
              SizedBox(height: 10),
              Image.asset('assets/images/shared/logo2.png', scale: 1.2),
              SizedBox(height: 10),
              Container(
                height: context.heightPercent(0.30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: Color(0xFFF5F7FA),
                ),
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.all(40),
                child: Column(children: [LoginForm()]),
              ),
              Container(
                height: 150,
                child: OverflowBox(
                  maxHeight: 500,
                  alignment: Alignment.topCenter,

                  child: Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      'assets/images/login/login_bg.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
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
            AppNavigation.navigateTo(AppRoutes.adminList);
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
                borderSide: BorderSide(color: Color(0xFFD0C4B0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Color(0xFF916846)),
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
                borderSide: BorderSide(color: Color(0xFFD0C4B0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Color(0xFF916846)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,

            child: _isLoading
                ? CircularProgressIndicator(color: Colors.amberAccent)
                : Text("เข้าสู่ระบบ"),

            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 105, vertical: 12),
              backgroundColor: Color(0xFFD48B5C),
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
