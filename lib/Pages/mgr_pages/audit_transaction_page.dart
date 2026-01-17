import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:dakara_weighbridge/Entities/Manager/manager.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';

class AuditTransactionPage extends StatefulWidget {
  const AuditTransactionPage({super.key});

  @override
  State<AuditTransactionPage> createState() => _AuditTransactionPageState();
}

class _AuditTransactionPageState extends State<AuditTransactionPage> {
  final Manager _manager = Manager();
  late Future<List<ListTransactionJson>> _trxFuture;
  final TextEditingController _searchController = TextEditingController();

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

  // Helper Format Tanggal (Menghilangkan angka aneh di belakang detik)
  String _formatDate(dynamic date) {
    if (date == null) return "-";
    try {
      DateTime parsedDate;
      if (date is DateTime) {
        parsedDate = date;
      } else {
        parsedDate = DateTime.parse(date.toString());
      }
      // Format menjadi: 17/01/2026 14:30
      return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
    } catch (e) {
      return date.toString(); // Fallback jika gagal parse
    }
  }

  // Filter Pencarian
  List<ListTransactionJson> _filterTransactions(List<ListTransactionJson> allTrx, String query) {
    if (query.isEmpty) return allTrx;
    return allTrx.where((trx) {
      return trx.noTicket.toLowerCase().contains(query.toLowerCase()) ||
             trx.vehiclePlate.toLowerCase().contains(query.toLowerCase()) ||
             trx.driverName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  void _confirmDelete(int id, String ticketNo) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              const Text(
                "Hapus Data Permanen?",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                "Anda akan menghapus tiket #$ticketNo. Data yang dihapus tidak bisa dikembalikan.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF475569)),
                        foregroundColor: const Color(0xFF94A3B8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _manager.deleteTransaction(transactionId: id);
                        
                        if (!mounted) return;
                        Navigator.pop(dialogContext); // Tutup Dialog
                        
                        if (!mounted) return;
                        _refreshData(); // Refresh Tabel
                        
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Data transaksi berhasil dihapus", style: TextStyle(color: Colors.white)),
                            backgroundColor: const Color(0xFF1E293B),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text("Hapus"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Warna Tema Gelap (Sama dengan User Management)
    const bgDark = Color(0xFF0F172A);
    const cardDark = Color(0xFF1E293B);
    const surfaceDark = Color(0xFF2D3748);
    const textPrimary = Color(0xFFF1F5F9);
    const textSecondary = Color(0xFF94A3B8);

    // Style Header Tabel
    const TextStyle headerStyle = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: bgDark,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section (Jarak Aman dari Top Bar)
            const SizedBox(height: 40), 
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Audit Transactions",
                  style: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  "Pantau dan kelola data transaksi penimbangan",
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search, color: textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Cari No Tiket / Plat / Supir...",
                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data Table Content
            Expanded(
              child: FutureBuilder<List<ListTransactionJson>>(
                future: _trxFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blue));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: textSecondary)));
                  }
                  
                  final filteredData = _filterTransactions(snapshot.data ?? [], _searchController.text);

                  if (filteredData.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text("Tidak ada data transaksi", style: TextStyle(color: textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: surfaceDark, width: 1),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceDark.withValues(alpha: 0.3),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Expanded(flex: 2, child: Text("NO TIKET", style: headerStyle)),
                              Expanded(flex: 2, child: Text("TANGGAL", style: headerStyle)),
                              Expanded(flex: 2, child: Text("PLAT NOMOR", style: headerStyle)),
                              Expanded(flex: 2, child: Text("SUPIR", style: headerStyle)), // <-- KEMBALI ADA
                              Expanded(flex: 2, child: Text("BERAT BERSIH", style: headerStyle)),
                              Expanded(flex: 2, child: Text("STATUS", style: headerStyle, textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text("AKSI", style: headerStyle, textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        
                        // Table Body (List)
                        Expanded(
                          child: ListView.separated(
                            itemCount: filteredData.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: surfaceDark),
                            itemBuilder: (context, index) {
                              final trx = filteredData[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    // 1. No Tiket
                                    Expanded(flex: 2, child: Text(trx.noTicket, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    
                                    // 2. Tanggal (Sudah diformat rapi tanpa mikrodetik)
                                    Expanded(flex: 2, child: Text(_formatDate(trx.inTime), style: TextStyle(color: textSecondary, fontSize: 13))),
                                    
                                    // 3. Plat
                                    Expanded(flex: 2, child: Text(trx.vehiclePlate, style: const TextStyle(color: Colors.white))),
                                    
                                    // 4. Supir (KEMBALI ADA)
                                    Expanded(flex: 2, child: Text(trx.driverName, style: const TextStyle(color: Colors.white))),
                                    
                                    // 5. Berat
                                    Expanded(flex: 2, child: Text("${trx.netto} Kg", style: const TextStyle(color: Colors.white))),
                                    
                                    // 6. Status Badge
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: trx.isDrafted == 0 
                                                ? const Color(0xFF10B981).withValues(alpha: 0.2) // Hijau
                                                : const Color(0xFFF59E0B).withValues(alpha: 0.2), // Kuning
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: trx.isDrafted == 0 
                                                  ? const Color(0xFF10B981) 
                                                  : const Color(0xFFF59E0B),
                                              width: 1
                                            )
                                          ),
                                          child: Text(
                                            trx.isDrafted == 0 ? "Completed" : "Draft",
                                            style: TextStyle(
                                              color: trx.isDrafted == 0 
                                                  ? const Color(0xFF10B981) 
                                                  : const Color(0xFFF59E0B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // 7. Action Button (TOMBOL HAPUS)
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: SizedBox(
                                          width: 72,
                                          height: 32,
                                          child: ElevatedButton(
                                            onPressed: () => _confirmDelete(trx.transactionId, trx.noTicket),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFEF4444), // Merah
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: const Text("Hapus", style: TextStyle(fontSize: 12)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}