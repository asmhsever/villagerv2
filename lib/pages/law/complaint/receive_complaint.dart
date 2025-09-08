// lib/pages/law/complaint/pending_complaints_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/complaint_domain.dart';
import 'package:fullproject/domains/complaint_type_domain.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/complaint/complaint_detail.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:intl/intl.dart';

// Future<void> _acceptComplaint() async {
//   final confirm = await showDialog<bool>(
//     context: context,
//     builder: (context) => AlertDialog(
//       backgroundColor: ThemeColors.ivoryWhite,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: ThemeColors.oliveGreen.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               Icons.check_circle_outline,
//               color: ThemeColors.oliveGreen,
//               size: 28,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'รับคำร้องเรียน',
//               style: TextStyle(
//                 color: ThemeColors.softBrown,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ),
//         ],
//       ),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: ThemeColors.oliveGreen.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: ThemeColors.oliveGreen.withValues(alpha: 0.3),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.info_outline,
//                       color: ThemeColors.oliveGreen,
//                       size: 18,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'การรับคำร้องเรียน',
//                       style: TextStyle(
//                         color: ThemeColors.oliveGreen,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'สถานะจะเปลี่ยนเป็น "กำลังดำเนินการ"',
//                   style: TextStyle(color: ThemeColors.earthClay, fontSize: 13),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'ยืนยันการรับคำร้องเรียนนี้?',
//             style: TextStyle(color: ThemeColors.earthClay, fontSize: 16),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: ThemeColors.beige,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               'หัวข้อ: ${currentComplaint.header}',
//               style: TextStyle(
//                 color: ThemeColors.softBrown,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context, false),
//           style: TextButton.styleFrom(
//             foregroundColor: ThemeColors.warmStone,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//           ),
//           child: const Text(
//             'ยกเลิก',
//             style: TextStyle(fontWeight: FontWeight.w600),
//           ),
//         ),
//         ElevatedButton(
//           onPressed: () => Navigator.pop(context, true),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: ThemeColors.oliveGreen,
//             foregroundColor: ThemeColors.ivoryWhite,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.check_circle, size: 18),
//               const SizedBox(width: 6),
//               const Text(
//                 'รับคำร้องเรียน',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
//
//   if (confirm == true) {
//     await _performAcceptComplaint();
//   }
// }
