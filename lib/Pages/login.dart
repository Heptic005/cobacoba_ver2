import 'package:dakara_weighbridge/Services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/dashboard.dart';
import 'package:dakara_weighbridge/Exception/auth_exception.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';

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

  Future<void> _registerOperator() async {
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
      final newAccount = ListAccountJson(
        accountUsername: username,
        accountPassword: password,
        accountPosition: 'operator',
      );
      await DbHelper.instance.addUser(newAccount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operator berhasil didaftarkan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mendaftar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
    // Theme colors consistent with the app
    const bgDark = Color(0xFF1E2126);
    const cardBg = Color(0xFF2B2E33);
    const primaryCyan = Color(0xFF00E5FF);
    const textGrey = Color(0xFFBFC9D6);

    return Scaffold(
      backgroundColor: bgDark,
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
                  colors: [
                    cardBg.withAlpha((0.95 * 255).round()),
                    cardBg.withAlpha((0.6 * 255).round()),
                    Colors.black.withAlpha((0.25 * 255).round()),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: textGrey.withAlpha((0.06 * 255).round()),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.65 * 255).round()),
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
                          // top bar with optional language toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'EN',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 44,
                                height: 24,
                                child: Switch(value: true, onChanged: (_) {}),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Welcome',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Dakara Weighbridge',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // instructions block
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(
                                (0.06 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Testing: please register first using "Register as Operator" to create an operator account, then sign in. This build is for testing only.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // form
                          SizedBox(
                            width: 420,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _usernameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle: TextStyle(color: textGrey),
                                    filled: true,
                                    fillColor: const Color(0xFF383C42),
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
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(color: textGrey),
                                    filled: true,
                                    fillColor: const Color(0xFF383C42),
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
                                    backgroundColor: primaryCyan,
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
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed:
                                      _loading ? null : _registerOperator,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: primaryCyan),
                                    foregroundColor: primaryCyan,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Register as Operator'),
                                ),
                                const SizedBox(height: 18),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Need help? Contact Customer Services',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // version text bottom-left
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(color: textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.black26,
                  ),

                  // Right column: image/illustration placeholder
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700.withAlpha(
                            (0.18 * 255).round(),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 96,
                          color: Colors.white24,
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
