import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminRoleDetailsScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String? roleDescription;

  const AdminRoleDetailsScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.roleDescription,
  });

  @override
  State<AdminRoleDetailsScreen> createState() => _AdminRoleDetailsScreenState();
}

class _AdminRoleDetailsScreenState extends State<AdminRoleDetailsScreen> {
  bool loading = true;
  bool saving = false;

  List<dynamic> allPermissions = [];
  Set<String> selectedPermissions = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => loading = true);

      final permissions = await ApiService.getAllPermissions();
      final rolePerms = await ApiService.getRolePermissions(widget.roleId);

      setState(() {
        allPermissions = permissions;
        selectedPermissions =
            rolePerms.map<String>((p) => p["key_name"]).toSet();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _showError("Failed to load permissions");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _saveChanges() async {
    try {
      setState(() => saving = true);

      await ApiService.updateRole(
        roleId: widget.roleId,
        name: widget.roleName,
        description: widget.roleDescription,
        permissions: selectedPermissions.toList(),
      );

      setState(() => saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Permissions updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => saving = false);
      _showError("Failed to update role");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildPermissionsList()),
                  _buildSaveButton(),
                ],
              ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9C27B0),
            Color(0xFF9C27B0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.roleName.toUpperCase(),
            style: const TextStyle(
              fontFamily: "Baloo",
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (widget.roleDescription != null) ...[
            const SizedBox(height: 3),
            Text(
              widget.roleDescription!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ================= PERMISSIONS LIST =================

  Widget _buildPermissionsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      itemCount: allPermissions.length,
      itemBuilder: (context, index) {
        final p = allPermissions[index];
        final key = p["key_name"];
        final desc = p["description"] ?? "";
        final enabled = selectedPermissions.contains(key);

        return _permissionCard(
          keyName: key,
          description: desc,
          enabled: enabled,
          onToggle: (val) {
            setState(() {
              val
                  ? selectedPermissions.add(key)
                  : selectedPermissions.remove(key);
            });
          },
        );
      },
    );
  }

  Widget _permissionCard({
    required String keyName,
    required String description,
    required bool enabled,
    required Function(bool) onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: enabled
              ? [
                  const Color(0xFF7B1FA2).withOpacity(0.18),
                  Colors.white,
                ]
              : [
                  Colors.white,
                  Colors.white,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? const Color(0xFF7B1FA2) : Colors.grey.shade300,
            ),
            child: Icon(
              Icons.security,
              color: enabled ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  keyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeColor: Colors.purple,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }

  // ================= SAVE BUTTON =================

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: saving ? null : _saveChanges,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(
            saving ? "Saving..." : "Save Changes",
            style: const TextStyle(
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
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 6,
          ),
        ),
      ),
    );
  }
}
