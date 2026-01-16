import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pastikan import ini ada untuk format tanggal
import 'package:dakara_weighbridge/Entities/Manager/manager.dart'; // Path yang sudah diperbaiki
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';

class AuditTransactionPage extends StatefulWidget {
  const AuditTransactionPage({super.key});

  @override
  State<AuditTransactionPage> createState() => _AuditTransactionPageState();
}

class _AuditTransactionPageState extends State<AuditTransactionPage> {
  final Manager _manager = Manager();
  late Future<List<ListTransactionJson>> _trxFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _trxFuture = _manager.getAllTransactions();
    });
  }

  // Helper untuk format tanggal agar rapi
  String _formatDate(dynamic date) {
    if (date == null) return "-";
    if (date is DateTime) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
    return date.toString();
  }

  void _confirmDelete(int id, String ticketNo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("HAPUS DATA?"),
        content: Text("PERINGATAN: Anda akan menghapus transaksi Tiket #$ticketNo secara permanen. Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog dulu
              
              // Lakukan penghapusan
              await _manager.deleteTransaction(transactionId: id);
              
              // Cek apakah halaman masih aktif sebelum menggunakan context (Fix Async Gap)
              if (!mounted) return;

              _refreshData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Data transaksi berhasil dihapus.")),
              );
            },
            child: const Text("Hapus Permanen", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text("Audit & Delete Transaction", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FutureBuilder<List<ListTransactionJson>>(
              future: _trxFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada data transaksi."));
                }

                final transactions = snapshot.data!;
                
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("No Tiket")),
                        DataColumn(label: Text("Tanggal Masuk")),
                        DataColumn(label: Text("Plat Nomor")),
                        DataColumn(label: Text("Supir")),
                        DataColumn(label: Text("Berat Netto")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Aksi")),
                      ],
                      rows: transactions.map((trx) {
                        return DataRow(cells: [
                          DataCell(Text(trx.noTicket, style: const TextStyle(fontWeight: FontWeight.bold))),
                          // PERBAIKAN DI SINI: Menggunakan helper _formatDate
                          DataCell(Text(_formatDate(trx.inTime))), 
                          DataCell(Text(trx.vehiclePlate)),
                          DataCell(Text(trx.driverName)),
                          DataCell(Text("${trx.netto} Kg")),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: trx.isDrafted == 0 ? Colors.green[100] : Colors.orange[100],
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Text(
                                trx.isDrafted == 0 ? "Completed" : "Draft",
                                style: TextStyle(
                                  color: trx.isDrafted == 0 ? Colors.green[800] : Colors.orange[800],
                                  fontSize: 12
                                ),
                              ),
                            )
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              tooltip: "Hapus Transaksi",
                              onPressed: () => _confirmDelete(trx.transactionId, trx.noTicket),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}