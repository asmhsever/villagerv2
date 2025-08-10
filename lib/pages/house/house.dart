import 'package:flutter/material.dart';

class HouseDetailPage extends StatefulWidget {
  const HouseDetailPage({super.key});

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("house detail")));
  }
}
