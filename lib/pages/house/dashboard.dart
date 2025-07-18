import 'package:flutter/material.dart';
 
class HouseDashboardPage extends StatefulWidget {
  const HouseDashboardPage({super.key});

  @override
  State<HouseDashboardPage> createState() => _HouseDashboardPageState();
}

class _HouseDashboardPageState extends State<HouseDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ลูกบ้านหัวค')),
      body: Text("ลูกบัวหัวค้าน"),
    );
  }
}
