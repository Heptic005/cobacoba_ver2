import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Entities/Operator/operator.dart';
import 'package:dakara_weighbridge/Services/auth_service.dart';
import 'package:dakara_weighbridge/Services/token_service.dart';
import 'package:dakara_weighbridge/dashboard.dart';
import 'package:dakara_weighbridge/Exception/auth_exception.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:dakara_weighbridge/Entities/Supervisor/supervisor.dart';

class CreateOperatorPage extends StatefulWidget {
  const CreateOperatorPage({super.key});

  @override
  State<CreateOperatorPage> createState() => _CreateOperatorPageState();
}

class _CreateOperatorPageState extends State<CreateOperatorPage> {
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
      final authService = AuthService();
      final newAccount = ListAccountJson(
        accountUsername: username,
        accountPassword: authService.hashPassword(password),
        accountPosition: 'supervisor',
      );
      await DbHelper.instance.addUser(newAccount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operator berhasil didaftarkan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendaftar: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login berhasil')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } on InvalidCredentialException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username atau password salah')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal login: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF1E2126);
    const cardBg = Color(0xFF2B2E33);
    const primaryCyan = Color(0xFF00E5FF);
    const inputBg = Color(0xFF383C42);
    const textGrey = Color(0xFFBFC9D6);

    final supervisor = Supervisor();

    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Operator Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Supervisor dapat membuat akun Operator baru dengan mengisi username dan password.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(color: textGrey),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: textGrey),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            supervisor.createOperator(
                              username: _usernameController.text,
                              password: _passwordController.text,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Add Operator',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final token = await TokenService.createToken();
                      print(token.createdBy);
                      print(token.tokenCode);
                    },
                    child: const Text(
                      'Need help? Contact Customer Services',
                      style: TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: textGrey, fontSize: 12),
                    textAlign: TextAlign.center,
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
