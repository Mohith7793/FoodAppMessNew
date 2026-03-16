import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import '../../config/app_config.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});
  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch({String? search}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.getAdminProducts(token, search: search);
      if (res['success'] == true) {
        setState(() {
          _products = (res['data'] as List<dynamic>).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = res['message'] as String? ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  Future<void> _toggleAvailability(Product p) async {
    final token = context.read<AuthProvider>().token!;
    await ApiService.updateProduct(token, p.id, {'is_available': !p.isAvailable});
    _fetch(search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null);
  }

  Future<void> _delete(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        title: const Text('Delete Product?', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${p.name}"? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      final token = context.read<AuthProvider>().token!;
      await ApiService.deleteProduct(token, p.id);
      _fetch();
    }
  }

  void _openForm({Product? product}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: product, onSaved: _fetch)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        backgroundColor: _kCard,
        automaticallyImplyLeading: false,
        title: const Text('Products', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _fetch),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _kOrange,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search products...', hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B35)),
                filled: true, fillColor: _kCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A4A))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A4A))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kOrange, width: 2)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: () { _searchCtrl.clear(); _fetch(); setState(() {}); })
                    : null,
              ),
              onChanged: (v) { setState(() {}); if (v.length >= 2 || v.isEmpty) _fetch(search: v.isEmpty ? null : v); },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kOrange))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white54)))
                    : _products.isEmpty
                        ? const Center(child: Text('No products found', style: TextStyle(color: Colors.white54)))
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: _kOrange,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: _products.length,
                              itemBuilder: (_, i) {
                                final p = _products[i];
                                return _ProductTile(
                                  product: p,
                                  onEdit: () => _openForm(product: p),
                                  onDelete: () => _delete(p),
                                  onToggle: () => _toggleAvailability(p),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit, onDelete, onToggle;
  const _ProductTile({required this.product, required this.onEdit, required this.onDelete, required this.onToggle});

  static const _kOrange = Color(0xFFFF6B35);
  static const _kCard = Color(0xFF16213E);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: product.isAvailable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 90, height: 90,
              child: product.imageUrl != null
                  ? Image.network(
                      AppConfig.resolveImageUrl(product.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _Placeholder(),
                    )
                  : _Placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('₹${product.price.toStringAsFixed(0)} · ${product.category}', style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.inventory_2_outlined, size: 12, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text('Stock: ${product.stock}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.isAvailable ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(product.isAvailable ? 'Available' : 'Unavailable',
                        style: TextStyle(color: product.isAvailable ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ]),
            ),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Switch(value: product.isAvailable, onChanged: (_) => onToggle(), activeColor: _kOrange, inactiveTrackColor: Colors.white24),
            Row(children: [
              IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18), onPressed: onEdit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 4),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 8),
            ]),
          ]),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(color: const Color(0xFF1A1A2E), child: const Icon(Icons.fastfood, color: Color(0xFFFF6B35), size: 32));
}

// ── Product Form Screen ────────────────────────────────────────────────────────

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final VoidCallback onSaved;
  const ProductFormScreen({super.key, this.product, required this.onSaved});
  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  bool _isAvailable = true;
  bool _loading = false;
  String? _error;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _existingImageUrl;

  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);

  static const _categories = ['Breakfast', 'Lunch', 'Dinner', 'Main Course', 'Snacks', 'Beverages', 'Desserts', 'Others'];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _priceCtrl.text = p.price.toStringAsFixed(0);
      _stockCtrl.text = p.stock.toString();
      _catCtrl.text = p.category;
      _isAvailable = p.isAvailable;
      _existingImageUrl = p.imageUrl;
    } else {
      _stockCtrl.text = '100';
      _catCtrl.text = 'Main Course';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() { _imageBytes = bytes; _imageFileName = picked.name; });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'stock': int.tryParse(_stockCtrl.text) ?? 100,
        'category': _catCtrl.text.trim(),
        'is_available': _isAvailable,
      };

      Map<String, dynamic> res;
      if (_isEditing) {
        res = await ApiService.updateProduct(token, widget.product!.id, data);
      } else {
        res = await ApiService.createProduct(token, data);
      }

      if (res['success'] == true && _imageBytes != null) {
        final productId = _isEditing ? widget.product!.id : (res['data'] as Map<String, dynamic>)['id'] as int;
        await ApiService.uploadProductImage(token, productId, _imageBytes!, _imageFileName ?? 'product.jpg');
      }

      if (res['success'] == true && mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Product updated!' : 'Product created!'), backgroundColor: Colors.green));
      } else {
        setState(() { _error = res['message'] as String? ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        backgroundColor: _kCard,
        title: Text(_isEditing ? 'Edit Product' : 'Add Product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isEditing ? 'Save' : 'Create', style: const TextStyle(color: _kOrange, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null)
              Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Text(_error!, style: const TextStyle(color: Colors.red))),

            // Image picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kOrange.withOpacity(0.3), width: 2)),
                  child: _imageBytes != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                      : (_existingImageUrl != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(
                              AppConfig.resolveImageUrl(_existingImageUrl),
                              fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder()))
                          : _imagePlaceholder()),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(child: Text('Tap to upload image', style: TextStyle(color: Colors.white54, fontSize: 12))),
            const SizedBox(height: 20),

            _label('Product Name'),
            _field(_nameCtrl, 'e.g. Idli Vada', validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),

            _label('Description'),
            _field(_descCtrl, 'Brief description of the dish', maxLines: 3),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Price (₹)'),
                _field(_priceCtrl, '0.00', type: TextInputType.number, validator: (v) => double.tryParse(v!) == null ? 'Invalid' : null),
              ])),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Stock'),
                _field(_stockCtrl, '100', type: TextInputType.number, validator: (v) => int.tryParse(v!) == null ? 'Invalid' : null),
              ])),
            ]),
            const SizedBox(height: 16),

            _label('Category'),
            DropdownButtonFormField<String>(
              value: _categories.contains(_catCtrl.text) ? _catCtrl.text : null,
              style: const TextStyle(color: Colors.white),
              dropdownColor: _kCard,
              decoration: _inputDeco('Select category', Icons.category_outlined),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) { if (v != null) _catCtrl.text = v; },
              validator: (v) => v == null ? 'Select a category' : null,
            ),
            const SizedBox(height: 20),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Available for ordering', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              Switch(value: _isAvailable, onChanged: (v) => setState(() => _isAvailable = v), activeColor: _kOrange),
            ]),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: _kOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(_isEditing ? 'Save Changes' : 'Create Product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _field(TextEditingController ctrl, String hint, {TextInputType? type, String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl, style: const TextStyle(color: Colors.white), keyboardType: type, maxLines: maxLines, validator: validator,
      decoration: _inputDeco(hint, null),
    );
  }

  InputDecoration _inputDeco(String hint, IconData? icon) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.white38),
    prefixIcon: icon != null ? Icon(icon, color: _kOrange) : null,
    filled: true, fillColor: _kCard,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A4A))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A4A))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kOrange, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _imagePlaceholder() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFFFF6B35), size: 40),
    const SizedBox(height: 6),
    const Text('Upload Image', style: TextStyle(color: Color(0xFFFF6B35), fontSize: 12)),
  ]);
}
