import 'package:dakara_weighbridge/Entities/Supervisor/supervisor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dakara_weighbridge/Entities/Manager/manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenGeneratorPage extends StatefulWidget {
  const TokenGeneratorPage({super.key});

  @override
  State<TokenGeneratorPage> createState() => _TokenGeneratorPageState();
}

class _TokenGeneratorPageState extends State<TokenGeneratorPage> {
  String _generatedToken = "---";
  bool _isLoading = false;

  Future<void> _generateToken() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      String newToken = '';
      prefs.getString('role') == 'manager'
          ? newToken = await Manager().createTokenForManualWeight()
          : newToken = await Supervisor().createTokenForManualWeight();

      // Gunakan mounted check sebelum setState
      if (!mounted) return;

      setState(() {
        _generatedToken = newToken;
      });
    } catch (e) {
      // Gunakan mounted check sebelum menggunakan context
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal generate: $e")));
    }

    // Pindahkan setState isLoading ke sini, di luar finally block
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: 500, // Lebar fixed agar rapi di desktop
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.vpn_key, size: 50, color: Colors.amber),
              const SizedBox(height: 20),
              const Text(
                "Manual Weight Override Token",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Token ini digunakan oleh Supervisor untuk melakukan bypass/input manual pada timbangan saat kondisi darurat.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _generatedToken,
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedToken));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Token disalin!")),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _generateToken,
                  child: Text(
                    _isLoading ? "Memproses..." : "GENERATE NEW TOKEN",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
