import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_shell.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureSecret = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passwordCtrl.dispose(); _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.registerAdmin(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      adminSecret: _secretCtrl.text.trim(),
    );
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminShell()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mess Owner Registration', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.store, color: Color(0xFFFF6B35), size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('Register as Mess Owner', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Enter the admin secret key provided by the system', style: TextStyle(color: Colors.white60, fontSize: 13), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (auth.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
                child: Text(auth.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _DarkTextField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline,
                      validator: (v) => v!.length < 2 ? 'Name required' : null),
                  const SizedBox(height: 14),
                  _DarkTextField(controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => !v!.contains('@') ? 'Valid email required' : null),
                  const SizedBox(height: 14),
                  _DarkTextField(controller: _passwordCtrl, label: 'Password', icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                      validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
                  const SizedBox(height: 14),
                  _DarkTextField(controller: _secretCtrl, label: 'Admin Secret Key', icon: Icons.vpn_key_outlined,
                      obscure: _obscureSecret,
                      suffixIcon: IconButton(icon: Icon(_obscureSecret ? Icons.visibility_off : Icons.visibility, color: Colors.white54), onPressed: () => setState(() => _obscureSecret = !_obscureSecret)),
                      validator: (v) => v!.isEmpty ? 'Secret key required' : null),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: auth.loading ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: auth.loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Create Mess Owner Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _DarkTextField({required this.controller, required this.label, required this.icon, this.obscure = false, this.suffixIcon, this.validator, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B35)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A4A))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A4A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }
}
