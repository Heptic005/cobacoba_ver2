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

  // SharedPreferences key
  static const String _tokenKey = 'generated_manual_token';

  // Color Constants (DESAIN ASLI)
  static const Color bgDark = Color(0xFF1E2126);
  static const Color cardBg = Color(0xFF2B2E33);
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color inputBg = Color(0xFF383C42);
  static const Color textGrey = Color(0xFFBFC9D6);

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);

    if (savedToken != null && savedToken.isNotEmpty) {
      setState(() {
        _generatedToken = savedToken;
      });
    }
  }

  Future<void> _generateToken() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      final userRole = prefs.getString('role');
      if (userRole == null) {
        throw Exception('User role not found. Please login again.');
      }

      String newToken = '';
      if (userRole == 'manager') {
        newToken = await Manager().createTokenForManualWeight();
      } else if (userRole == 'supervisor') {
        newToken = await Supervisor().createTokenForManualWeight();
      } else {
        throw Exception('Invalid user role: $userRole');
      }

      if (newToken.isEmpty) {
        throw Exception('Generated token is empty');
      }

      await prefs.setString(_tokenKey, newToken);

      if (!mounted) return;
      setState(() {
        _generatedToken = newToken;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Token berhasil dibuat!"),
          backgroundColor: primaryCyan,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Gagal membuat token';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFE74C3C),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _resetToken() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      await prefs.remove(_tokenKey);

      setState(() {
        _generatedToken = "---";
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Token berhasil direset!"),
          backgroundColor: primaryCyan,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mereset token"),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: primaryCyan.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: primaryCyan.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.warning_outlined,
                    color: primaryCyan.withOpacity(0.7),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Reset Token?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Apakah Anda yakin ingin mereset token? Token yang ada saat ini akan dihapus.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: inputBg,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetToken();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryCyan,
                          foregroundColor: bgDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryCyan, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Token",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryCyan,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _generatedToken,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: primaryCyan,
                                    letterSpacing: 2,
                                    fontFamily: 'Courier New',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.content_copy,
                                  color: _generatedToken == "---"
                                      ? textGrey.withOpacity(0.5)
                                      : primaryCyan,
                                ),
                                onPressed: _generatedToken == "---"
                                    ? null
                                    : () {
                                        Clipboard.setData(
                                          ClipboardData(
                                              text: _generatedToken),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _generateToken,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryCyan,
                              foregroundColor: bgDark,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text("GENERATE NEW TOKEN"),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _showResetConfirmDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE74C3C),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("RESET TOKEN"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
