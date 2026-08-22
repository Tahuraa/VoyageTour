import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin/admin_destination_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

const _destinationStatusFilters = ['all', 'active', 'inactive'];

class AdminDestinationsScreen extends StatefulWidget {
  const AdminDestinationsScreen({super.key});

  @override
  State<AdminDestinationsScreen> createState() =>
      _AdminDestinationsScreenState();
}

class _AdminDestinationsScreenState extends State<AdminDestinationsScreen> {
  late Future<List<AdminDestinationModel>> _future;
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

  Future<List<AdminDestinationModel>> _load() {
    final token = context.read<AuthProvider>().token!;
    return AdminService(token: token).listDestinations();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  List<AdminDestinationModel> _applyFilters(
    List<AdminDestinationModel> destinations,
  ) {
    var result = destinations;
    if (_statusFilter != 'all') {
      result = result.where((d) => d.status == _statusFilter).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (d) =>
                d.name.toLowerCase().contains(q) ||
                d.country.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  Future<void> _openForm({AdminDestinationModel? existing}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _DestinationFormScreen(existing: existing),
      ),
    );
    if (changed == true) _refresh();
  }

  Future<void> _delete(AdminDestinationModel destination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete destination?'),
        content: Text('This will permanently delete "${destination.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
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
      await AdminService(token: token).deleteDestination(destination.id);
      await _refresh();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Destinations'),
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
        child: FutureBuilder<List<AdminDestinationModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text('Could not load destinations. Pull to retry.'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final destinations = _applyFilters(snapshot.data!);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search destinations...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final f in _destinationStatusFilters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterPill(
                          label: f == 'all'
                              ? 'All'
                              : f[0].toUpperCase() + f.substring(1),
                          selected: _statusFilter == f,
                          onTap: () => setState(() => _statusFilter = f),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${destinations.length} DESTINATION${destinations.length == 1 ? '' : 'S'} LISTED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                if (destinations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No destinations found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  for (final d in destinations) ...[
                    _DestinationCard(
                      destination: d,
                      onTap: () => _openForm(existing: d),
                      onEdit: () => _openForm(existing: d),
                      onDelete: () => _delete(d),
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

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DestinationAvatar extends StatelessWidget {
  final AdminDestinationModel destination;
  const _DestinationAvatar({required this.destination});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 46,
        height: 46,
        child: destination.imageUrl != null
            ? Image.network(
                destination.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
    color: Colors.blue.shade50,
    child: Icon(Icons.public, color: Colors.blue.shade400),
  );
}

class _DestinationCard extends StatelessWidget {
  final AdminDestinationModel destination;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DestinationCard({
    required this.destination,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _DestinationAvatar(destination: destination),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              destination.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (destination.isFeatured) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${destination.country} (${destination.countryCode})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(status: destination.status),
              ],
            ),
            if (destination.description != null &&
                destination.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                destination.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
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

class _DestinationFormScreen extends StatefulWidget {
  final AdminDestinationModel? existing;
  const _DestinationFormScreen({this.existing});

  @override
  State<_DestinationFormScreen> createState() => _DestinationFormScreenState();
}

class _DestinationFormScreenState extends State<_DestinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _countryController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late bool _isFeatured;
  late bool _isActive;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _countryController = TextEditingController(text: e?.country ?? '');
    _countryCodeController = TextEditingController(text: e?.countryCode ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _imageUrlController = TextEditingController(text: e?.imageUrl ?? '');
    _isFeatured = e?.isFeatured ?? false;
    _isActive = (e?.status ?? 'active') == 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _countryCodeController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final token = context.read<AuthProvider>().token!;
    final body = {
      'name': _nameController.text.trim(),
      'country': _countryController.text.trim(),
      'country_code': _countryCodeController.text.trim().toUpperCase(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'image_url': _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      'is_featured': _isFeatured,
      'status': _isActive ? 'active' : 'inactive',
    };
    try {
      final service = AdminService(token: token);
      if (_isEditing) {
        await service.updateDestination(widget.existing!.id, body);
      } else {
        await service.createDestination(body);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
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
        title: Text(_isEditing ? 'Edit Destination' : 'Add Destination'),
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
                controller: _nameController,
                label: 'Name',
                hint: 'e.g. Italy',
                icon: Icons.location_on_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _countryController,
                label: 'Country',
                hint: 'e.g. Italy',
                icon: Icons.public,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Country is required'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _countryCodeController,
                label: 'Country Code',
                hint: 'e.g. IT',
                icon: Icons.flag_outlined,
                validator: (v) => (v == null || v.trim().length != 2)
                    ? 'Must be a 2-letter code'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _descriptionController,
                label: 'Description (optional)',
                hint: 'Short description',
                icon: Icons.notes,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                hint: 'https://...',
                icon: Icons.image_outlined,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Featured on Home screen'),
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text(
                  'Inactive destinations are hidden from customers',
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Create Destination',
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
