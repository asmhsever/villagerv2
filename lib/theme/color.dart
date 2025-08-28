import 'package:flutter/material.dart';

class ThemeColors {
  // ห้ามสร้าง instance
  ThemeColors._();

  // สีหลัก (8 สี)
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);

  // สำหรับ Form & UI (6 สี)
  static const Color softBorder = Color(0xFFD0C4B0);
  static const Color focusedBrown = Color(0xFF916846);
  static const Color inputFill = Color(0xFFFBF9F3);
  static const Color clickHighlight = Color(0xFFDC7633);
  static const Color hoverButton = Color(0xFFF3A664);
  static const Color disabledGrey = Color(0xFFDCDCDC);

  // สีเสริมเดิม (5 สี)
  static const Color softTerracotta = Color(0xFFD48B5C);
  static const Color clayOrange = Color(0xFFCC7748);
  static const Color mutedBurntSienna = Color(0xFFC8755A);
  static const Color warmAmber = Color(0xFFDA9856);
  static const Color softerBurntOrange = Color(0xFFDB8142);

  // === สีใหม่เพิ่มเติม (6 สี) ===

  // โทนน้ำตาลเข้ม/อ่อน
  static const Color deepMahogany = Color(
    0xFF8B4513,
  ); // น้ำตาลแก่เข้ม - สำหรับ header/accent
  static const Color lightTaupe = Color(
    0xFFE6D7C3,
  ); // น้ำตาลอ่อมครีม - card background
  static const Color dustyBrown = Color(
    0xFFB8956A,
  ); // น้ำตาลฝุ่น - borders/dividers

  // โทนเขียวธรรมชาติ
  static const Color sageGreen = Color(
    0xFF9CAF88,
  ); // เขียวปราชญ์ - success states
  static const Color mossGreen = Color(
    0xFF8D9F7A,
  ); // เขียวตะไคร่น้ำ - secondary actions
  static const Color paleGreen = Color(
    0xFFB8C5A6,
  ); // เขียวอ่อน - subtle highlights

  // โทนส้ม/แดงธรรมชาติ
  static const Color rustOrange = Color(0xFFB87333); // ส้มสนิม - warning/alerts
  static const Color apricot = Color(0xFFE6B88A); // ส้มอ่อน - gentle accents
  static const Color copperRose = Color(
    0xFFD2B48C,
  ); // ทองแดงอ่อน - premium elements

  // โทนครีม/ขาว
  static const Color creamWhite = Color(
    0xFFF8F6F0,
  ); // ครีมขาว - clean backgrounds
  static const Color antiqueWhite = Color(0xFFFAEBD7); // ขาวโบราณ - soft cards
  static const Color parchment = Color(
    0xFFF1E5D0,
  ); // กระดาษโบราณ - document themes

  // สีเน้น/Accent
  static const Color goldenHoney = Color(
    0xFFD4AF37,
  ); // ทองผึ้ง - premium/VIP features
  static const Color terracottaRed = Color(
    0xFFCD853F,
  ); // แดงดินเหนียว - important actions
  static const Color caramel = Color(
    0xFFCD853F,
  ); // คาราเมล - sweet interactions

  // สีสำหรับ Status/States
  static const Color successGreen = Color(
    0xFF8FBC8F,
  ); // เขียวสำเร็จ - ใช้แทน default green
  static const Color warningAmber = Color(0xFFDAA520); // เหลืองเตือน - warnings
  static const Color errorRust = Color(
    0xFFCD5C5C,
  ); // แดงผิดพลาด - errors ที่นุ่มตา
  static const Color infoBlue = Color(
    0xFF87CEEB,
  ); // ฟ้าข้อมูล - information (ผสมกับธีม)

  // สีเสริมพิเศษ
  static const Color darkChocolate = Color(
    0xFF654321,
  ); // ช็อกโกแลตเข้ม - text/headers
  static const Color lightCinnamon = Color(
    0xFFD2B48C,
  ); // อบเชยอ่อน - subtle accents
  static const Color wheatGold = Color(0xFFF5DEB3); // ทองข้าวสาลี - highlights
  static const Color mushroom = Color(0xFFC3B091); // เห็ด - neutral elements
  static const Color sandstone = Color(
    0xFFE6D0B0,
  ); // หินทราย - structural elements
  static const Color driftwood = Color(0xFFAF9B7A); // ไม้ไผล - borders/frames
}
