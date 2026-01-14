import 'package:flutter/material.dart';
import '../../Entities/Supervisor/supervisor.dart';

class ExportReportPage extends StatelessWidget {
  final Supervisor supervisor;
  const ExportReportPage({super.key, required this.supervisor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Laporan')),
      body: Center(
        child: const Text('Fitur export laporan akan mengambil data dari DbHelper'),
      ),
    );
  }
}
