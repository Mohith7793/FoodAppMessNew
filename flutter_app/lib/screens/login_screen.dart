import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'admin/admin_shell.dart';
import 'admin/admin_register_screen.dart';
import 'admin/admin_login_screen.dart';
import 'staff/staff_shell.dart';
import 'staff/staff_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  // Shown below the login card so user knows which server is targeted
  String get _serverLabel => '${AppConfig.serverHost}:${AppConfig.serverPort}';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showServerSettings() {
    showDialog(context: context, builder: (_) => _ServerSettingsDialog(onSaved: () => setState(() {})));
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
    if (success && mounted) {
      if (auth.isAdmin) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminShell()));
      } else if (auth.isStaff) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StaffShell()));
      } else {
        await context.read<CartProvider>().fetchCart(auth.token!);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                const _BrandHeader(),
                const SizedBox(height: 40),
                // Login Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Welcome Back!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
                        const SizedBox(height: 6),
                        Text('Sign in to continue', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        const SizedBox(height: 24),
                        if (auth.error != null) ...[
                          _ErrorBanner(message: auth.error!, onDismiss: auth.clearError),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFFF6B35)), hintText: 'Enter your email'),
                          validator: (v) { if (v == null || v.isEmpty) return 'Email required'; if (!v.contains('@')) return 'Enter valid email'; return null; },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFF6B35)),
                            suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                          ),
                          validator: (v) { if (v == null || v.isEmpty) return 'Password required'; if (v.length < 6) return 'Min 6 characters'; return null; },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: auth.loading ? null : _handleLogin,
                            child: auth.loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Sign In'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600])),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: const Text('Register', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Server indicator + settings button
                GestureDetector(
                  onTap: _showServerSettings,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.dns_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text('Server: $_serverLabel', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Role-based login links
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffLoginScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.teal.withOpacity(0.5)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.badge_outlined, color: Colors.teal, size: 22),
                                SizedBox(height: 6),
                                Text('Staff Login', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 22),
                                SizedBox(height: 6),
                                Text('Admin Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRegisterScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.store_outlined, color: Colors.white, size: 22),
                                SizedBox(height: 6),
                                Text('Admin Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]), child: const Icon(Icons.restaurant_menu, size: 44, color: Color(0xFFFF6B35))),
      const SizedBox(height: 16),
      const Text('Mess Food', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      const Text('Your Campus Kitchen', style: TextStyle(fontSize: 14, color: Colors.white70)),
    ]);
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message; final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 13))),
        GestureDetector(onTap: onDismiss, child: const Icon(Icons.close, color: Colors.red, size: 16)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Server Settings Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ServerSettingsDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _ServerSettingsDialog({required this.onSaved});

  @override
  State<_ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<_ServerSettingsDialog> {
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: AppConfig.serverHost);
    _portCtrl = TextEditingController(text: AppConfig.serverPort.toString());
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim());
    if (host.isEmpty || port == null || port <= 0 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid host and port (1–65535).'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    await AppConfig.save(host: host, port: port);
    setState(() => _saving = false);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _reset() async {
    await AppConfig.reset();
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_outlined, color: Color(0xFFFF6B35)),
          SizedBox(width: 8),
          Text('Server Settings'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the IP address of the machine running the backend server. '
            'All devices must use the same IP.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hostCtrl,
            decoration: const InputDecoration(
              labelText: 'Server Host / IP',
              hintText: 'e.g. 192.168.1.100 or localhost',
              prefixIcon: Icon(Icons.computer_outlined),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portCtrl,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '5001',
              prefixIcon: Icon(Icons.numbers_outlined),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Text(
            'Current URL: http://${AppConfig.serverHost}:${AppConfig.serverPort}/api',
            style: const TextStyle(fontSize: 11, color: Colors.black38),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _reset, child: const Text('Reset to Default', style: TextStyle(color: Colors.grey))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
