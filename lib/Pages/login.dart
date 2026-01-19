import 'package:dakara_weighbridge/Services/auth_service.dart';
import 'package:dakara_weighbridge/Services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/dashboard.dart';
import 'package:dakara_weighbridge/Exception/auth_exception.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/Entities/Supervisor/supervisor.dart';
import 'package:dakara_weighbridge/Pages/spv_pages/dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isNightTime() {
    final now = DateTime.now();
    final hour = now.hour;
    // Night time: 18:00 (6 PM) to 06:00 (6 AM)
    return hour >= 18 || hour < 6;
  }

  Color _getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF1E2126) : const Color(0xFFF5F5F5);
  }

  Color _getCardColor(bool isDark) {
    return isDark ? const Color(0xFF2B2E33) : const Color(0xFFFFFFFF);
  }

  Color _getTextColor(bool isDark) {
    return isDark ? const Color(0xFFBFC9D6) : const Color(0xFF383C42);
  }

  Color _getInputColor(bool isDark) {
    return isDark ? const Color(0xFF383C42) : const Color(0xFFF0F0F0);
  }

  Color _getPrimaryCyan() => const Color(0xFF00E5FF);

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan password harus diisi')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final authService = AuthService();
      await authService.login(username: username, password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login berhasil')));
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const Dashboard()));
    } on InvalidCredentialException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username atau password salah')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal login: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine theme based on time of day
    final isDark = _isNightTime();

    final bgColor = _getBackgroundColor(isDark);
    final cardBgColor = _getCardColor(isDark);
    final textColor = _getTextColor(isDark);
    final inputColor = _getInputColor(isDark);
    final primaryCyan = _getPrimaryCyan();

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [
                            cardBgColor.withAlpha((0.95 * 255).round()),
                            cardBgColor.withAlpha((0.6 * 255).round()),
                            Colors.black.withAlpha((0.25 * 255).round()),
                          ]
                          : [
                            cardBgColor.withAlpha((0.95 * 255).round()),
                            cardBgColor.withAlpha((0.7 * 255).round()),
                            Colors.white.withAlpha((0.1 * 255).round()),
                          ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDark
                          ? textColor.withAlpha((0.06 * 255).round())
                          : Colors.black.withAlpha((0.1 * 255).round()),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.black.withAlpha((0.65 * 255).round())
                            : Colors.grey.withAlpha((0.3 * 255).round()),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left column: title, form, instructions
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top bar with language toggle (keep original style)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'EN',
                                style: TextStyle(
                                  color: textColor.withAlpha(
                                    (0.7 * 255).round(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 44,
                                height: 24,
                                child: Switch(
                                  value: true,
                                  onChanged: (_) {},
                                  activeColor: const Color(0xFF00E5FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Welcome',
                            style: TextStyle(
                              color: textColor.withAlpha((0.7 * 255).round()),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dakara Weighbridge',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Instructions block
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.black.withAlpha(
                                        (0.06 * 255).round(),
                                      )
                                      : Colors.black.withAlpha(
                                        (0.03 * 255).round(),
                                      ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Testing: please sign in using your operator account. This build is for testing only.',
                              style: TextStyle(
                                color: textColor.withAlpha((0.7 * 255).round()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Form
                          SizedBox(
                            width: 420,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _usernameController,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle: TextStyle(color: textColor),
                                    filled: true,
                                    fillColor: inputColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(color: textColor),
                                    filled: true,
                                    fillColor: inputColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E5FF),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child:
                                      _loading
                                          ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                ),
                                const SizedBox(height: 18),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Version text bottom-left
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              color: textColor.withAlpha((0.5 * 255).round()),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color:
                        isDark
                            ? Colors.black26
                            : Colors.black.withAlpha((0.1 * 255).round()),
                  ),

                  // Right column: image/illustration placeholder
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.grey.shade700.withAlpha(
                                    (0.18 * 255).round(),
                                  )
                                  : Colors.grey.shade300.withAlpha(
                                    (0.3 * 255).round(),
                                  ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isDark
                                    ? Colors.black12
                                    : Colors.black.withAlpha(
                                      (0.1 * 255).round(),
                                    ),
                          ),
                        ),
                        child: Icon(
                          Icons.image,
                          size: 96,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
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
