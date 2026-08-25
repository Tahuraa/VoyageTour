import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin/admin_promotion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

const _discountTypes = ['percentage', 'fixed'];
const _promotionStatusFilters = ['all', 'active', 'inactive'];

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  late Future<List<AdminPromotionModel>> _future;
  final _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<AdminPromotionModel>> _load() {
    final token = context.read<AuthProvider>().token!;
    return AdminService(token: token).listPromotions();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  List<AdminPromotionModel> _applyFilters(List<AdminPromotionModel> promotions) {
    var result = promotions;
    if (_statusFilter != 'all') {
      result = result.where((p) => p.status == _statusFilter).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where((p) => p.code.toLowerCase().contains(q) || (p.title ?? '').toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  Future<void> _openForm({AdminPromotionModel? existing}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _PromotionFormScreen(existing: existing)),
    );
    if (changed == true) _refresh();
  }

  Future<void> _delete(AdminPromotionModel promotion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete promotion?'),
        content: Text('This will permanently delete "${promotion.code}".'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token!;
    try {
      await AdminService(token: token).deletePromotion(promotion.id);
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not delete. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Offers & Promotions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminPromotionModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Could not load promotions. Pull to retry.')),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final promotions = _applyFilters(snapshot.data!);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search promo codes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final f in _promotionStatusFilters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _PromotionFilterPill(
                          label: f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1),
                          selected: _statusFilter == f,
                          onTap: () => setState(() => _statusFilter = f),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${promotions.length} PROMOTION${promotions.length == 1 ? '' : 'S'} LISTED',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                if (promotions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No promotions found', style: TextStyle(color: Colors.grey.shade600))),
                  )
                else
                  for (final p in promotions) ...[
                    _PromotionCard(
                      promotion: p,
                      onTap: () => _openForm(existing: p),
                      onEdit: () => _openForm(existing: p),
                      onDelete: () => _delete(p),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PromotionFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PromotionFilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.blue : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final AdminPromotionModel promotion;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PromotionCard({required this.promotion, required this.onTap, required this.onEdit, required this.onDelete});

  String get _discountLabel => promotion.discountType == 'percentage'
      ? '${promotion.discountValue.toStringAsFixed(0)}% OFF'
      : '\$${promotion.discountValue.toStringAsFixed(0)} OFF';

  @override
  Widget build(BuildContext context) {
    final active = promotion.status == 'active';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: Container(
                    width: 46,
                    height: 46,
                    color: Colors.orange.shade50,
                    alignment: Alignment.center,
                    child: Icon(Icons.local_offer_outlined, color: Colors.orange.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(promotion.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        promotion.title ?? _discountLabel,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: active ? Colors.green : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    promotion.status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    _discountLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_fmtDate(promotion.validFrom)} – ${_fmtDate(promotion.validTo)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionFormScreen extends StatefulWidget {
  final AdminPromotionModel? existing;
  const _PromotionFormScreen({this.existing});

  @override
  State<_PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends State<_PromotionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _badgeLabelController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _usageLimitController;
  late String _discountType;
  late DateTime _validFrom;
  late DateTime _validTo;
  late bool _isActive;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeController = TextEditingController(text: e?.code ?? '');
    _titleController = TextEditingController(text: e?.title ?? '');
    _subtitleController = TextEditingController(text: e?.subtitle ?? '');
    _badgeLabelController = TextEditingController(text: e?.badgeLabel ?? '');
    _imageUrlController = TextEditingController(text: e?.imageUrl ?? '');
    _discountValueController = TextEditingController(text: e?.discountValue.toStringAsFixed(0) ?? '');
    _minOrderController = TextEditingController(text: e?.minOrderAmount.toStringAsFixed(0) ?? '');
    _usageLimitController = TextEditingController(text: e?.usageLimit?.toString() ?? '');
    _discountType = e?.discountType ?? _discountTypes.first;
    final now = DateTime.now();
    _validFrom = e?.validFrom ?? DateTime(now.year, now.month, now.day);
    _validTo = e?.validTo ?? DateTime(now.year, now.month, now.day).add(const Duration(days: 30));
    _isActive = (e?.status ?? 'active') == 'active';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _badgeLabelController.dispose();
    _imageUrlController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _validFrom : _validTo,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _validFrom = picked;
      } else {
        _validTo = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_validTo.isBefore(_validFrom)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Valid to date must be on or after valid from date')));
      return;
    }
    setState(() => _isSubmitting = true);
    final token = context.read<AuthProvider>().token!;
    final body = {
      'code': _codeController.text.trim().toUpperCase(),
      'title': _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      'subtitle': _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
      'badge_label': _badgeLabelController.text.trim().isEmpty ? null : _badgeLabelController.text.trim(),
      'image_url': _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      'discount_type': _discountType,
      'discount_value': double.tryParse(_discountValueController.text.trim()) ?? 0,
      'min_order_amount': double.tryParse(_minOrderController.text.trim()) ?? 0,
      'valid_from': _validFrom.toIso8601String(),
      'valid_to': _validTo.toIso8601String(),
      'usage_limit':
          _usageLimitController.text.trim().isEmpty ? null : int.tryParse(_usageLimitController.text.trim()),
      'status': _isActive ? 'active' : 'inactive',
    };
    try {
      final service = AdminService(token: token);
      if (_isEditing) {
        await service.updatePromotion(widget.existing!.id, body);
      } else {
        await service.createPromotion(body);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Promotion' : 'Add Promotion'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              AppTextField(
                controller: _codeController,
                label: 'Promo Code',
                hint: 'e.g. SUMMER40',
                icon: Icons.local_offer_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Code is required' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _titleController,
                label: 'Title (optional)',
                hint: 'e.g. Summer Sale',
                icon: Icons.title,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _subtitleController,
                label: 'Subtitle (optional)',
                hint: 'Short description shown on the banner',
                icon: Icons.notes,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _badgeLabelController,
                label: 'Badge Label (optional)',
                hint: 'e.g. LIMITED TIME',
                icon: Icons.bookmark_outline,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _discountType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Discount Type',
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      items: _discountTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _discountType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _discountValueController,
                      label: _discountType == 'percentage' ? 'Discount (%)' : 'Discount (\$)',
                      hint: 'e.g. 20',
                      icon: Icons.percent,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || double.tryParse(v.trim()) == null) ? 'Enter a valid amount' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _minOrderController,
                label: 'Minimum Order Amount (\$, optional)',
                hint: 'e.g. 100',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _usageLimitController,
                label: 'Usage Limit (optional)',
                hint: 'e.g. 100',
                icon: Icons.confirmation_number_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(label: 'Valid From', date: _validFrom, onTap: () => _pickDate(isFrom: true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(label: 'Valid To', date: _validTo, onTap: () => _pickDate(isFrom: false)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                hint: 'https://...',
                icon: Icons.image_outlined,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Inactive promotions are hidden from customers'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Create Promotion',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black45),
                const SizedBox(width: 10),
                Text(_fmtDate(date)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
