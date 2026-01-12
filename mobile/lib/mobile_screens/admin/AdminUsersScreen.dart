import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> users = [];
  bool loading = true;
  final List<String> allowedRoles = ["student", "doctor", "admin"];

  // 🔍 SEARCH
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getAdminUsers();
      setState(() {
        users = data;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _toggleUser(int userId, bool isActive) async {
    try {
      if (isActive) {
        await ApiService.deactivateUser(userId);
      } else {
        await ApiService.activateUser(userId);
      }
      await _loadUsers();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _changeRole(int userId, String newRole) async {
    try {
      await ApiService.changeUserRole(userId, newRole);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case "admin":
        return const Color(0xFF7C4DFF);
      case "doctor":
        return const Color(0xFF00B0FF);
      case "student":
      default:
        return const Color(0xFF00C853);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 FILTERED USERS (NO LOGIC CHANGE)
    final filteredUsers = users.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery) || email.contains(searchQuery);
    }).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF4ECFA),
              Color(0xFFEDE7F6),
              Color(0xFFFDFBFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== HEADER =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: const Color(0xFF4A148C),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Users Control Center",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "Baloo",
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A148C),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Manage access, roles & activity",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      color: const Color(0xFF4A148C),
                      onPressed: _loadUsers,
                    ),
                  ],
                ),
              ),

              // 🔍 SEARCH BAR (NEW – DESIGN MATCHING)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Select users",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ===== CONTENT =====
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredUsers.isEmpty
                        ? const Center(child: Text("No users found"))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final u = filteredUsers[index];
                              final bool isActive = u['is_active'] == 1;

                              final photoUrl = u['photo_url'] != null
                                  ? "http://10.0.2.2:5000${u['photo_url']}?t=${DateTime.now().millisecondsSinceEpoch}"
                                  : null;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 22),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFEFE1),
                                      Color(0xFFF9EFFD),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _roleColor(u['role'])
                                          .withOpacity(0.18),
                                      blurRadius: 30,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _roleColor(u['role'])
                                                    .withOpacity(0.35),
                                                blurRadius: 18,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 29,
                                            backgroundColor:
                                                _roleColor(u['role'])
                                                    .withOpacity(0.15),
                                            backgroundImage: photoUrl != null
                                                ? NetworkImage(photoUrl)
                                                : null,
                                            child: photoUrl == null
                                                ? Text(
                                                    (u['full_name'] ?? '?')
                                                        .toString()
                                                        .substring(0, 1)
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          _roleColor(u['role']),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                u['full_name'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                u['email'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color: _roleColor(u['role'])
                                                .withOpacity(0.18),
                                          ),
                                          child: Text(
                                            u['role'].toString().toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _roleColor(u['role']),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Divider(color: Colors.brown.shade200),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              "Active",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(width: 10),
                                            Switch(
                                              value: isActive,
                                              activeColor:
                                                  _roleColor(u['role']),
                                              onChanged: (_) => _toggleUser(
                                                  u['id'], isActive),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _roleColor(u['role'])
                                                  .withOpacity(0.4),
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: allowedRoles
                                                      .contains(u['role'])
                                                  ? u['role']
                                                  : null,
                                              hint: const Text("Role"),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: "student",
                                                    child: Text("Student")),
                                                DropdownMenuItem(
                                                    value: "doctor",
                                                    child: Text("Doctor")),
                                                DropdownMenuItem(
                                                    value: "admin",
                                                    child: Text("Admin")),
                                              ],
                                              onChanged: (val) {
                                                if (val != null &&
                                                    val != u['role']) {
                                                  setState(() {
                                                    u['role'] = val;
                                                  });
                                                  _changeRole(u['id'], val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
