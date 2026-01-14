import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Entities/Supervisor/supervisor.dart';

class ReportPageSpv extends StatelessWidget {
  final Supervisor supervisor;
  const ReportPageSpv({super.key, required this.supervisor});

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF1E2126);
    const cardBg = Color(0xFF2B2E33);
    const accent = Color(0xFF00E5FF);

    // Dummy data laporan
    final laporan = [
      {"tanggal": "2026-01-14", "operator": "Operator A", "berat": "1200 kg"},
      {"tanggal": "2026-01-13", "operator": "Operator B", "berat": "980 kg"},
      {"tanggal": "2026-01-12", "operator": "Operator C", "berat": "1500 kg"},
    ];

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text("Laporan Supervisor"),
        backgroundColor: cardBg,
        foregroundColor: accent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: laporan.length,
                itemBuilder: (context, index) {
                  final item = laporan[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.assignment, color: accent),
                      title: Text(
                        "Tanggal: ${item['tanggal']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Operator: ${item['operator']} | Berat: ${item['berat']}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: sambungkan ke fungsi export PDF/Excel
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Export laporan berhasil (dummy)")),
                );
              },
              icon: const Icon(Icons.file_download),
              label: const Text("Export Laporan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
