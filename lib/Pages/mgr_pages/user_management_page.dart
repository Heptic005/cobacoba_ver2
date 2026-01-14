import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Entities/Manager/manager.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final Manager _manager = Manager();
  late Future<List<ListAccountJson>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = _manager.getSupervisorAndOperator();
    });
  }

  void _showAddUserDialog() {
    final TextEditingController usernameCtrl = TextEditingController();
    final TextEditingController passwordCtrl = TextEditingController();
    String selectedRole = 'operator'; // Default role

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Agar Dropdown bisa berubah state-nya dalam dialog
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Tambah User Baru"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(labelText: "Username"),
                  ),
                  TextField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'supervisor', child: Text("Supervisor")),
                      DropdownMenuItem(value: 'operator', child: Text("Operator")),
                      DropdownMenuItem(value: 'manager', child: Text("Manager")),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (usernameCtrl.text.isNotEmpty && passwordCtrl.text.isNotEmpty) {
                      await _manager.createSupervisorAndOperator(
                        username: usernameCtrl.text,
                        password: passwordCtrl.text,
                        role: selectedRole,
                      );
                      Navigator.pop(context);
                      _refreshUsers(); // Refresh list setelah tambah
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("User berhasil ditambahkan")),
                      );
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteUser(int id) async {
    if (id == 0) return; // Mencegah hapus akun system jika ada
    await _manager.deleteSupervisorAndOperator(id: id);
    _refreshUsers();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User berhasil dihapus")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Agar menyatu dengan background dashboard
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        label: const Text("Tambah User"),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.blue[800],
      ),
      body: FutureBuilder<List<ListAccountJson>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data user."));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRoleColor(user.accountPosition),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(user.accountUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Role: ${user.accountPosition.toUpperCase()}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                       // Konfirmasi hapus
                       showDialog(
                         context: context,
                         builder: (context) => AlertDialog(
                           title: const Text("Hapus User?"),
                           content: Text("Yakin ingin menghapus ${user.accountUsername}?"),
                           actions: [
                             TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                             TextButton(onPressed: () {
                               Navigator.pop(context);
                               _deleteUser(user.accountID);
                             }, child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                           ],
                         ),
                       );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'manager': return Colors.red;
      case 'supervisor': return Colors.orange;
      case 'operator': return Colors.green;
      default: return Colors.grey;
    }
  }
}