import 'package:flutter/material.dart';
import 'package:mobile/web_screens/center/service_profile_screen.dart';
import 'package:mobile/web_screens/doctor/ShowDoctorProfileScreen.dart';
import '../../services/api_service.dart';
import 'AdminRoleDetailsScreen.dart';

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  bool loading = true;
  List<dynamic> roles = [];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      setState(() => loading = true);
      final data = await ApiService.getAllRoles();
      setState(() {
        roles = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _error("Failed to load roles");
    }
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Color _roleColor(String name) {
    switch (name.toLowerCase()) {
      case "admin":
        return const Color(0xFF7C4DFF);
      case "doctor":
        return const Color(0xFF00B0FF);
      case "student":
        return const Color(0xFF00C853);
      case "service_center":
        return const Color(0xFF8E24AA);
      default:
        return const Color(0xFF5E35B1);
    }
  }

  // ========================= UI =========================

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF9F5F0),
              Color(0xFFF3ECE5),
              Color(0xFFF7F2ED),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== HEADER =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 22, 12, 18),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: const Color(0xFF7B1FA2),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Roles & Permissions",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "Baloo",
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: uniPurple,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Control system access & capabilities",
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
                      color: const Color(0xFF7B1FA2),
                      onPressed: _loadRoles,
                    ),
                  ],
                ),
              ),

              // ===== CONTENT =====
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : roles.isEmpty
                        ? const Center(child: Text("No roles found"))
                        : GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 18,
                              childAspectRatio: isWide ? 1.15 : 0.9,
                            ),
                            itemCount: roles.length,
                            itemBuilder: (context, index) {
                              final r = roles[index];
                              final color = _roleColor(r["name"]);

                              return GestureDetector(
                                onTap: () => _openRoleDetails(r),
                                child: _roleCard(
                                  name: r["name"],
                                  description:
                                      r["description"] ?? "No description",
                                  color: color,
                                  onView: () => _openRoleDetails(r),
                                  onDelete: () =>
                                      _confirmDeleteRole(r["id"], r["name"]),
                                ),
                              );
                            },
                          ),
              ),

              // ===== ADD ROLE BUTTON =====
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "Create New Role",
                      style: TextStyle(
                        fontFamily: "Baloo",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _createRoleDialog,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================= ROLE CARD =========================

  Widget _roleCard({
    required String name,
    required String description,
    required Color color,
    required VoidCallback onView,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🛡 ROLE ICON
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(Icons.security, color: color),
          ),

          const SizedBox(height: 12),

          // ROLE NAME
          Text(
            name.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 6),

          // DESCRIPTION
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.black54,
            ),
          ),

          // ⬇⬇⬇ هذا هو المفتاح
          const Spacer(),

          // 🔽 ACTIONS AT BOTTOM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
                tooltip: "Delete role",
              ),
              TextButton.icon(
                onPressed: onView,
                icon: Icon(Icons.arrow_forward_ios, size: 16, color: color),
                label: Text(
                  "Manage",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================= NAVIGATION =========================

  void _openRoleDetails(Map role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminRoleDetailsScreen(
          roleId: role["id"],
          roleName: role["name"],
          roleDescription: role["description"],
        ),
      ),
    );
  }

  // ========================= DELETE ROLE =========================

  void _confirmDeleteRole(int roleId, String roleName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Delete Role",
          style: TextStyle(fontFamily: "Baloo"),
        ),
        content: Text(
          "Are you sure you want to delete \"$roleName\"?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () async {
              try {
                await ApiService.deleteRole(roleId);
                Navigator.pop(context);
                _loadRoles();
              } catch (e) {
                _error("Failed to delete role");
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ========================= CREATE ROLE =========================

  void _createRoleDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Create New Role",
          style: TextStyle(fontFamily: "Baloo"),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Role Name"),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;

              try {
                await ApiService.createRole(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  permissions: [],
                );
                Navigator.pop(context);
                _loadRoles();
              } catch (e) {
                _error("Create role failed");
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
