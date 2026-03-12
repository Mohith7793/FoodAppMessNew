import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});
  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<dynamic> _staff = [];
  bool _loading = true;
  String? _error;

  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.getStaff(token);
      if (res['success'] == true) setState(() { _staff = res['data'] as List<dynamic>? ?? []; _loading = false; });
      else setState(() { _error = res['message'] as String?; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  Future<void> _toggle(int id) async {
    final token = context.read<AuthProvider>().token!;
    await ApiService.toggleStaff(token, id);
    _fetch();
  }

  Future<void> _delete(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        title: const Text('Remove Staff?', style: TextStyle(color: Colors.white)),
        content: Text('Remove $name from staff?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final token = context.read<AuthProvider>().token!;
      await ApiService.deleteStaff(token, id);
      _fetch();
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateStaffSheet(onCreated: _fetch),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        backgroundColor: _kCard,
        automaticallyImplyLeading: false,
        title: const Text('Staff Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _fetch),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: _kOrange,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kOrange))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white54)))
              : _staff.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.people_outline, size: 72, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text('No staff members yet', style: TextStyle(color: Colors.white54, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('Tap + to add staff credentials', style: TextStyle(color: Colors.white38)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: _kOrange,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _staff.length,
                        itemBuilder: (_, i) {
                          final s = _staff[i] as Map<String, dynamic>;
                          final isActive = s['is_active'] as bool? ?? true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2))),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                child: Text((s['name'] as String? ?? 'S')[0].toUpperCase(), style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.w800)),
                              ),
                              title: Text(s['name'] as String? ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s['email'] as String? ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                  child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ]),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                Switch(value: isActive, onChanged: (_) => _toggle(s['id'] as int), activeColor: _kOrange, inactiveTrackColor: Colors.white24),
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _delete(s['id'] as int, s['name'] as String? ?? 'Staff')),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _CreateStaffSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateStaffSheet({required this.onCreated});
  @override
  State<_CreateStaffSheet> createState() => _CreateStaffSheetState();
}

class _CreateStaffSheetState extends State<_CreateStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.createStaff(token, name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      if (res['success'] == true && mounted) {
        widget.onCreated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff member created!'), backgroundColor: Colors.green));
      } else {
        setState(() { _error = res['message'] as String? ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      decoration: const BoxDecoration(color: Color(0xFF16213E), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Create Staff Credentials', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Staff will use these credentials to login', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          if (_error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          TextFormField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Full Name', Icons.person_outline), validator: (v) => v!.length < 2 ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _emailCtrl, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.emailAddress, decoration: _inputDeco('Email', Icons.email_outlined), validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordCtrl, style: const TextStyle(color: Colors.white), obscureText: _obscure,
            decoration: _inputDeco('Password', Icons.lock_outline).copyWith(
              suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54), onPressed: () => setState(() => _obscure = !_obscure)),
            ),
            validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(height: 50, child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Create Staff Account', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(color: Colors.white60),
    prefixIcon: Icon(icon, color: const Color(0xFFFF6B35)),
    filled: true, fillColor: const Color(0xFF1A1A2E),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A4A))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A4A))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2)),
  );
}
