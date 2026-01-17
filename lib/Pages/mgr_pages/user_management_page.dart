import 'package:flutter/material.dart';
import 'package:dakara_weighbridge/Entities/Manager/manager.dart';
import 'package:dakara_weighbridge/Json/listaccount_json.dart';
import 'package:intl/intl.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final Manager _manager = Manager();
  late Future<List<ListAccountJson>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();
  
  // (PERBAIKAN: Menghapus map manual karena data sudah ada di database)
  // final Map<int, DateTime?> _lastLoginTimes = {}; 

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

  // Filter untuk menampilkan HANYA supervisor dan operator
  List<ListAccountJson> _filterUsers(List<ListAccountJson> allUsers, String searchQuery) {
    // Urutkan: supervisor dulu, kemudian operator
    final filtered = allUsers.where((user) {
      final role = user.accountPosition.toLowerCase();
      final isSupervisorOrOperator = role == 'supervisor' || role == 'operator';
      final matchesSearch = searchQuery.isEmpty || 
          user.accountUsername.toLowerCase().contains(searchQuery.toLowerCase());
      return isSupervisorOrOperator && matchesSearch;
    }).toList();

    // Sort: supervisor dulu, kemudian operator
    filtered.sort((a, b) {
      if (a.accountPosition.toLowerCase() == 'supervisor' && 
          b.accountPosition.toLowerCase() != 'supervisor') {
        return -1;
      } else if (a.accountPosition.toLowerCase() != 'supervisor' && 
                 b.accountPosition.toLowerCase() == 'supervisor') {
        return 1;
      }
      return a.accountUsername.compareTo(b.accountUsername);
    });

    return filtered;
  }

  // Check if supervisor exists
  bool _hasSupervisor(List<ListAccountJson> users) {
    return users.any((user) => user.accountPosition.toLowerCase() == 'supervisor');
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'supervisor':
        return const Color(0xFFFFA000); // Orange lebih soft
      case 'operator':
        return const Color(0xFF4CAF50); // Green
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplay(String role) {
    switch (role.toLowerCase()) {
      case 'supervisor':
        return 'Supervisor';
      case 'operator':
        return 'Operator';
      default:
        return role;
    }
  }

  // (PERBAIKAN LOGIKA: Mengambil String dari Database dan memformatnya)
  String _formatLastLogin(String? lastLoginString) {
    if (lastLoginString == null || lastLoginString.isEmpty) {
      return "Belum pernah login";
    }
    
    try {
      // Parsing string dari database ke DateTime
      DateTime date = DateTime.parse(lastLoginString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return "-"; // Jika format tanggal di db error
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F172A);
    const cardDark = Color(0xFF1E293B);
    const surfaceDark = Color(0xFF2D3748);
    const primaryBlue = Color(0xFF3B82F6);
    const textPrimary = Color(0xFFF1F5F9);
    const textSecondary = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgDark,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section - Dipindahkan ke bawah dengan margin top
            const SizedBox(height: 40), // Tambah jarak dari atas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "User Management",
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Kelola akun supervisor dan operator",
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Supervisor Alert (jika belum ada supervisor)
            FutureBuilder<List<ListAccountJson>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || 
                    !snapshot.hasData) {
                  return const SizedBox();
                }

                final users = snapshot.data!;
                if (!_hasSupervisor(users)) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Harap buatkan akun supervisor terlebih dahulu. Setelah supervisor dibuat, baru bisa membuat akun operator.",
                            style: TextStyle(
                              color: const Color(0xFF92400E),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 16),

            // Search and Action Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(
                          Icons.search,
                          color: textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: "Cari username...",
                              hintStyle: TextStyle(
                                color: textSecondary.withValues(alpha: 0.7),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: textSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FutureBuilder<List<ListAccountJson>>(
                  future: _usersFuture,
                  builder: (context, snapshot) {
                    final canAddOperator = snapshot.hasData && _hasSupervisor(snapshot.data!);
                    return SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: canAddOperator ? _showAddUserDialog : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text("Tambah User"),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Users List
            Expanded(
              child: FutureBuilder<List<ListAccountJson>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: primaryBlue,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Memuat data...",
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red.withValues(alpha: 0.7),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Terjadi kesalahan",
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredUsers = _filterUsers(snapshot.data ?? [], _searchController.text);
                  
                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchController.text.isEmpty 
                                ? Icons.people_outline_rounded 
                                : Icons.search_off_rounded,
                            color: textSecondary.withValues(alpha: 0.3),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty 
                                ? "Belum ada data user" 
                                : "User tidak ditemukan",
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: surfaceDark,
                            width: 1,
                          ),
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
                                children: [
                                  // Username Column
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: const Text(
                                        "USERNAME",
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Role Column - Tengah
                                  Expanded(
                                    child: const Text(
                                      "ROLE",
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  
                                  // Last Login Column - Tengah
                                  Expanded(
                                    child: const Text(
                                      "TERAKHIR LOGIN",
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  
                                  // Actions Column - Tengah
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: const Text(
                                        "AKSI",
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Users List
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredUsers.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 0,
                                color: surfaceDark,
                                thickness: 1,
                              ),
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final isSupervisor = user.accountPosition.toLowerCase() == 'supervisor';
                                final roleColor = _getRoleColor(user.accountPosition);
                                
                                return Container(
                                  color: cardDark,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      children: [
                                        // Username Column
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.accountUsername,
                                                  style: const TextStyle(
                                                    color: Color(0xFFF1F5F9),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "ID: ${user.accountID}",
                                                  style: TextStyle(
                                                    color: textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        // Role Column - Tengah
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: roleColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: roleColor.withValues(alpha: 0.2),
                                                  ),
                                                ),
                                                child: Text(
                                                  _getRoleDisplay(user.accountPosition),
                                                  style: TextStyle(
                                                    color: roleColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Last Login Column - Tengah (PERBAIKAN DI SINI)
                                        Expanded(
                                          child: Text(
                                            _formatLastLogin(user.lastLogin), // Menggunakan data Real-time dari DB
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        
                                        // Actions Column - Tengah
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                // Update Button for all users
                                                SizedBox(
                                                  width: 80,
                                                  height: 32,
                                                  child: ElevatedButton(
                                                    onPressed: () => _showEditUserDialog(user),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: primaryBlue,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: const Text(
                                                      "Update",
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                                
                                                // Delete Button (only for operators)
                                                if (!isSupervisor) ...[
                                                  const SizedBox(width: 8),
                                                  SizedBox(
                                                    width: 72,
                                                    height: 32,
                                                    child: ElevatedButton(
                                                      onPressed: () => _showDeleteDialog(user),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFFEF4444),
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        elevation: 0,
                                                      ),
                                                      child: const Text(
                                                        "Hapus",
                                                        style: TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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

  // Dialog Functions
  void _showAddUserDialog() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'operator';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Tambah User Baru",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Buat akun operator baru",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Username Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Username",
                            style: TextStyle(
                              color: const Color(0xFFF1F5F9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3748),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: usernameCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                                hintText: "Masukkan username",
                                hintStyle: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Password",
                            style: TextStyle(
                              color: const Color(0xFFF1F5F9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3748),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: passwordCtrl,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                                hintText: "Masukkan password",
                                hintStyle: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Role Selection (only operator available)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Role",
                            style: TextStyle(
                              color: const Color(0xFFF1F5F9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3748),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: selectedRole,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1E293B),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                              style: const TextStyle(color: Colors.white),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'operator',
                                  child: Text("Operator"),
                                ),
                              ],
                              onChanged: (value) => setStateDialog(() => selectedRole = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF475569)),
                                foregroundColor: const Color(0xFF94A3B8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Batal"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (usernameCtrl.text.isNotEmpty && passwordCtrl.text.isNotEmpty) {
                                  try {
                                    await _manager.createSupervisorAndOperator(
                                      username: usernameCtrl.text,
                                      password: passwordCtrl.text,
                                      role: selectedRole,
                                    );
                                    
                                    if (!mounted) return;
                                    Navigator.pop(dialogContext);
                                    
                                    if (!mounted) return;
                                    _refreshUsers();
                                    
                                    if (!mounted) return;
                                    _showSuccessSnackbar("User ${usernameCtrl.text} berhasil ditambahkan");
                                  } catch (e) {
                                    if (!mounted) return;
                                    _showErrorSnackbar("Error: $e");
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text("Simpan"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(ListAccountJson user) {
    final usernameCtrl = TextEditingController(text: user.accountUsername);
    final passwordCtrl = TextEditingController();
    String selectedRole = user.accountPosition;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.accountPosition.toLowerCase() == 'supervisor' 
                            ? "Update Supervisor" 
                            : "Update Operator",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.accountPosition.toLowerCase() == 'supervisor'
                            ? "Update informasi supervisor"
                            : "Update informasi operator",
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Username Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Username",
                            style: TextStyle(
                              color: const Color(0xFFF1F5F9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3748),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: usernameCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Password (kosong jika tidak ubah)",
                            style: TextStyle(
                              color: const Color(0xFFF1F5F9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3748),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: passwordCtrl,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                                hintText: "Masukkan password baru",
                                hintStyle: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Role Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Role",
                            style: TextStyle(
                              color: const Color(0xFFF1F5F9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3748),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: selectedRole,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1E293B),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                              style: const TextStyle(color: Colors.white),
                              underline: const SizedBox(),
                              items: [
                                if (user.accountPosition.toLowerCase() == 'supervisor')
                                  const DropdownMenuItem(
                                    value: 'supervisor',
                                    child: Text("Supervisor"),
                                  ),
                                if (user.accountPosition.toLowerCase() == 'operator')
                                  const DropdownMenuItem(
                                    value: 'operator',
                                    child: Text("Operator"),
                                  ),
                              ],
                              onChanged: (value) => setStateDialog(() => selectedRole = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF475569)),
                                foregroundColor: const Color(0xFF94A3B8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Batal"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  final newPassword = passwordCtrl.text.isEmpty 
                                      ? user.accountPassword 
                                      : passwordCtrl.text;
                                  
                                  await _manager.updateSupervisorAndOperator(
                                    id: user.accountID,
                                    username: usernameCtrl.text,
                                    password: newPassword,
                                    role: selectedRole,
                                  );
                                  
                                  if (!mounted) return;
                                  Navigator.pop(dialogContext);
                                  
                                  if (!mounted) return;
                                  _refreshUsers();
                                  
                                  if (!mounted) return;
                                  _showSuccessSnackbar("User ${usernameCtrl.text} berhasil diperbarui");
                                } catch (e) {
                                  if (!mounted) return;
                                  _showErrorSnackbar("Error: $e");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text("Update"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(ListAccountJson user) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                "Hapus Operator?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Apakah Anda yakin ingin menghapus operator '${user.accountUsername}'?",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.5,
                ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _manager.deleteSupervisorAndOperator(id: user.accountID);
                          
                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          
                          if (!mounted) return;
                          _refreshUsers();
                          
                          if (!mounted) return;
                          _showSuccessSnackbar("Operator ${user.accountUsername} berhasil dihapus");
                        } catch (e) {
                          if (!mounted) return;
                          _showErrorSnackbar("Error: $e");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  // Helper Methods
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}