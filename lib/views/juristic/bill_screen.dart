
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class BillScreen extends StatefulWidget {
  final int villageId;
  const BillScreen({super.key, required this.villageId});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  List<Map<String, dynamic>> bills = [];
  List<Map<String, dynamic>> filteredBills = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterStatus = 'ทั้งหมด';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th').then((_) => _fetchBills());
  }

  Future<void> _fetchBills() async {
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('bill_area')
          .select('''
            *,
            house!inner(house_number, village_id),
            bill_item(amount)
          ''')
          .order('bill_date', ascending: false);

      final List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(data)
          .where((bill) => bill['house']['village_id'] == widget.villageId)
          .toList();

      setState(() {
        bills = filtered;
        filteredBills = filtered;
        isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('🔴 Fetch bill error: $e');
      debugPrint('🔍 Stacktrace: $stack');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterBills() {
    setState(() {
      filteredBills = bills.where((bill) {
        final houseNumber = bill['house']['house_number']?.toString() ?? '';
        final statusText = bill['status'] == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย';
        final matchSearch = houseNumber.contains(searchQuery);
        final matchStatus = filterStatus == 'ทั้งหมด' || filterStatus == statusText;
        return matchSearch && matchStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการค่าส่วนกลาง')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'ค้นหาบ้านเลขที่',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                searchQuery = value;
                _filterBills();
              },
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: filterStatus,
              onChanged: (value) {
                if (value != null) {
                  filterStatus = value;
                  _filterBills();
                }
              },
              items: const [
                DropdownMenuItem(value: 'ทั้งหมด', child: Text('ทั้งหมด')),
                DropdownMenuItem(value: 'จ่ายแล้ว', child: Text('จ่ายแล้ว')),
                DropdownMenuItem(value: 'ยังไม่จ่าย', child: Text('ยังไม่จ่าย')),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredBills.length,
                itemBuilder: (context, index) {
                  final bill = filteredBills[index];
                  final house = bill['house'];
                  final date = DateTime.parse(bill['bill_date']);
                  final formattedDate = DateFormat.yMMMMd('th').format(date);
                  final itemList = bill['bill_item'] as List<dynamic>;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('บ้านเลขที่ ${house['house_number']}'),
                          Text('วันที่: $formattedDate'),
                          const Divider(),
                          ...itemList.map((item) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('บริการ'),
                                Text('฿${item['amount']}'),
                              ],
                            );
                          }),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('รวมทั้งหมด', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('฿${bill['total_amount']}'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Chip(
                              label: Text(
                                bill['status'] == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: bill['status'] == 1 ? Colors.green : Colors.red,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
