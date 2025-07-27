// lib/pages/law/bill/bill_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/bill/bill_form_page.dart';
import 'package:fullproject/pages/law/bill/bill_detail_page.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  final BillDomain _domain = BillDomain();
  Future<List<BillModel>>? _bills;
  LawModel? law;
  Map<int, String> houseMap = {};
  int? filterStatus;

  @override
  void initState() {
    super.initState();
    _bills = null;
    _loadLawAndBills();
  }

  Future<void> _loadLawAndBills() async {
    final user = await AuthService.getCurrentUser();
    if (user is LawModel) {
      setState(() => law = user);
      await _loadHouseMap(user.villageId);
      setState(() {
        _bills = _domain.fetchBillsForLaw(user.villageId);
      });
    } else {
      _bills = Future.value([]);
    }
  }

  Future<void> _loadHouseMap(int villageId) async {
    final response = await SupabaseConfig.client
        .from('house')
        .select('house_id, house_number')
        .eq('village_id', villageId);

    final List list = response as List;
    houseMap = {
      for (var item in list)
        item['house_id'] as int: item['house_number'] as String
    };
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _refreshBills() async {
    if (law != null) {
      setState(() {
        _bills = _domain.fetchBillsForLaw(law!.villageId);
      });
    }
  }

  Future<void> _navigateToAddForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BillFormPage()),
    );
    if (result == true) {
      _refreshBills();
    }
  }

  void _navigateToDetail(BillModel bill) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillDetailPage(bill: bill, houseNumber: houseMap[bill.houseId] ?? '-'),
      ),
    );
    _refreshBills();
  }

  List<BillModel> _filterBills(List<BillModel> bills) {
    if (filterStatus == null) return bills;
    return bills.where((b) => b.paidStatus == filterStatus).toList();
  }

  Future<void> _exportToPdf(List<BillModel> bills) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('รายงานค่าส่วนกลาง', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: ['บ้านเลขที่', 'จำนวนเงิน', 'ครบกำหนด', 'สถานะ'],
                data: bills.map((bill) {
                  final houseNumber = houseMap[bill.houseId] ?? 'ไม่ทราบ';
                  final status = bill.paidStatus == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ';
                  final due = formatDate(bill.dueDate);
                  return [houseNumber, '${bill.amount}', due, status];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการค่าส่วนกลาง')),
      body: _bills == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<BillModel>>(
        future: _bills,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีข้อมูลค่าส่วนกลาง'));
          } else {
            final filtered = _filterBills(snapshot.data!);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text('กรองสถานะ: '),
                      DropdownButton<int?>(
                        value: filterStatus,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('ทั้งหมด')),
                          DropdownMenuItem(value: 0, child: Text('ยังไม่ชำระ')),
                          DropdownMenuItem(value: 1, child: Text('ชำระแล้ว')),
                        ],
                        onChanged: (value) => setState(() => filterStatus = value),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _exportToPdf(filtered),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final bill = filtered[index];
                      final houseNumber = houseMap[bill.houseId] ?? 'ไม่ทราบเลขที่';
                      return ListTile(
                        title: Text('บ้านเลขที่ $houseNumber - ${bill.amount} บาท'),
                        subtitle: Text(
                            'ครบกำหนด: ${formatDate(bill.dueDate)} | สถานะ: ${bill.paidStatus == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ'}'),
                        onTap: () => _navigateToDetail(bill),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addBill',
            onPressed: _navigateToAddForm,
            tooltip: 'เพิ่มค่าส่วนกลาง',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'back',
            onPressed: () => Navigator.pop(context),
            tooltip: 'กลับ',
            child: const Icon(Icons.arrow_back),
          ),
        ],
      ),
    );
  }
}