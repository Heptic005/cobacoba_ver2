import 'package:flutter/material.dart';
import '../../Entities/Supervisor/supervisor.dart';

class EmergencyTransaksiPage extends StatefulWidget {
  const EmergencyTransaksiPage({super.key});

  @override
  State<EmergencyTransaksiPage> createState() => _EmergencyTransaksiPageState();
}

class _EmergencyTransaksiPageState extends State<EmergencyTransaksiPage> {
  final tokenCtrl = TextEditingController();
  final platCtrl = TextEditingController();
  final supirCtrl = TextEditingController();
  final brutoCtrl = TextEditingController();
  final potCtrl = TextEditingController(text: '0');
  final hargaCtrl = TextEditingController(text: '0');
  final noDOCtrl = TextEditingController();
  final noContainerCtrl = TextEditingController();

  String? info;
  String? error;

  @override
  Widget build(BuildContext context) {
    final supervisor = Supervisor();

    const bgDark = Color(0xFF1E2126);
    const cardBg = Color(0xFF2B2E33);
    const accent = Color(0xFF00E5FF);
    const textGrey = Color(0xFFBFC9D6);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text('Transaksi Emergency'),
        backgroundColor: cardBg,
        foregroundColor: accent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Input Transaksi Manual',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildField(controller: tokenCtrl, label: 'Token'),
                  const SizedBox(height: 12),
                  _buildField(controller: platCtrl, label: 'Plat Mobil'),
                  const SizedBox(height: 12),
                  _buildField(controller: supirCtrl, label: 'Nama Supir'),
                  const SizedBox(height: 12),
                  _buildField(controller: brutoCtrl, label: 'Bruto (kg)', keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildField(controller: potCtrl, label: 'Potongan (kg)', keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildField(controller: hargaCtrl, label: 'Harga per Kg', keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildField(controller: noDOCtrl, label: 'No DO'),
                  const SizedBox(height: 12),
                  _buildField(controller: noContainerCtrl, label: 'No Container', keyboard: TextInputType.number),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await supervisor.addEmergencyTransaction(
                          token: tokenCtrl.text.trim(),
                          vehiclePlate: platCtrl.text.trim(),
                          driverName: supirCtrl.text.trim(),
                          supplierId: 1,
                          customerId: 1,
                          productId: 1,
                          cut: int.tryParse(potCtrl.text) ?? 0,
                          bruto: double.tryParse(brutoCtrl.text) ?? 0,
                          noDo: noDOCtrl.text,
                          noContainer: int.tryParse(noContainerCtrl.text),
                          price: double.tryParse(hargaCtrl.text),
                        );
                        setState(() {
                          info = 'Transaksi emergency berhasil disimpan';
                          error = null;
                        });
                      } catch (e) {
                        setState(() {
                          error = e.toString();
                          info = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Transaksi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  if (info != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      info!,
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w500),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, TextInputType? keyboard}) {
    const textGrey = Color(0xFFBFC9D6);
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textGrey),
        filled: true,
        fillColor: const Color(0xFF383C42),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
