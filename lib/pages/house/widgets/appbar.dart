import 'package:flutter/material.dart';
import 'package:fullproject/theme/Color.dart';

class HouseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic house; // หรือ House object ของคุณ

  const HouseAppBar({Key? key, required this.house}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ThemeColors.softBrown,
      // Soft Brown
      foregroundColor: ThemeColors.ivoryWhite,
      // Ivory White
      elevation: 0,
      automaticallyImplyLeading: false,
      // ไม่แสดงปุ่ม back
      centerTitle: true,

      // แสดงบ้านเลขที่แบบ minimal
      title: Text(
        'บ้านเลขที่ ${house.toString() ?? 'ไม่ระบุ'}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ThemeColors.ivoryWhite, // Ivory White
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
