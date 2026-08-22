import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin/admin_activity_model.dart';
import '../../models/admin/admin_destination_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

const _activityCategories = [
  'sightseeing',
  'adventure',
  'food',
  'shopping',
  'culture',
  'nature',
  'beach',
  'entertainment',
  'transport',
];

const _activityStatusFilters = ['all', 'active', 'inactive'];

class AdminActivitiesScreen extends StatefulWidget {
  const AdminActivitiesScreen({super.key});

  @override
  State<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends State<AdminActivitiesScreen> {
  late Future<List<AdminActivityModel>> _future;
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

  Future<List<AdminActivityModel>> _load() {
    final token = context.read<AuthProvider>().token!;
    return AdminService(token: token).listActivities();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  List<AdminActivityModel> _applyFilters(List<AdminActivityModel> activities) {
    var result = activities;
    if (_statusFilter != 'all') {
      result = result.where((a) => a.status == _statusFilter).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (a) =>
                a.name.toLowerCase().contains(q) ||
                a.location.toLowerCase().contains(q) ||
                a.destination.name.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  Future<void> _openForm({AdminActivityModel? existing}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ActivityFormScreen(existing: existing),
      ),
    );
    if (changed == true) _refresh();
  }

  Future<void> _delete(AdminActivityModel activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete activity?'),
        content: Text('This will permanently delete "${activity.name}".'),
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
      await AdminService(token: token).deleteActivity(activity.id);
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
        title: const Text('Activities'),
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
        child: FutureBuilder<List<AdminActivityModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text('Could not load activities. Pull to retry.'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final activities = _applyFilters(snapshot.data!);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search activities...',
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
                    for (final f in _activityStatusFilters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ActivityFilterPill(
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
                  '${activities.length} ACTIVIT${activities.length == 1 ? 'Y' : 'IES'} LISTED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                if (activities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No activities found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  for (final a in activities) ...[
                    _ActivityCard(
                      activity: a,
                      onTap: () => _openForm(existing: a),
                      onEdit: () => _openForm(existing: a),
                      onDelete: () => _delete(a),
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

class _ActivityFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ActivityFilterPill({
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

const _activityCategoryIcons = {
  'sightseeing': Icons.camera_alt_outlined,
  'adventure': Icons.terrain_outlined,
  'food': Icons.restaurant_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'culture': Icons.museum_outlined,
  'nature': Icons.park_outlined,
  'beach': Icons.beach_access_outlined,
  'entertainment': Icons.celebration_outlined,
  'transport': Icons.directions_bus_outlined,
};

class _ActivityCard extends StatelessWidget {
  final AdminActivityModel activity;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ActivityCard({
    required this.activity,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = activity.status == 'active';
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
                ClipOval(
                  child: Container(
                    width: 46,
                    height: 46,
                    color: Colors.blue.shade50,
                    child: activity.imageUrl != null
                        ? Image.network(
                            activity.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Icon(
                              _activityCategoryIcons[activity.category] ??
                                  Icons.local_activity_outlined,
                              color: Colors.blue.shade400,
                            ),
                          )
                        : Icon(
                            _activityCategoryIcons[activity.category] ??
                                Icons.local_activity_outlined,
                            color: Colors.blue.shade400,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${activity.destination.name} • ${activity.location}',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: active ? Colors.green : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activity.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activity.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${activity.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blue,
                  ),
                ),
                if (activity.durationMinutes != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${activity.durationMinutes} min',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
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

class _ActivityFormScreen extends StatefulWidget {
  final AdminActivityModel? existing;
  const _ActivityFormScreen({this.existing});

  @override
  State<_ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<_ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  late String _category;
  late bool _isActive;
  String? _destinationId;
  bool _isSubmitting = false;
  late Future<List<AdminDestinationModel>> _destinationsFuture;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _durationController = TextEditingController(
      text: e?.durationMinutes?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: e?.price.toStringAsFixed(0) ?? '',
    );
    _imageUrlController = TextEditingController(text: e?.imageUrl ?? '');
    _category = e?.category ?? _activityCategories.first;
    _isActive = (e?.status ?? 'active') == 'active';
    _destinationId = e?.destination.id;

    final token = context.read<AuthProvider>().token!;
    _destinationsFuture = AdminService(token: token).listDestinations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_destinationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final token = context.read<AuthProvider>().token!;
    final body = {
      'destination_id': _destinationId,
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'duration_minutes': _durationController.text.trim().isEmpty
          ? null
          : int.tryParse(_durationController.text.trim()),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'category': _category,
      'image_url': _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      'status': _isActive ? 'active' : 'inactive',
    };
    try {
      final service = AdminService(token: token);
      if (_isEditing) {
        await service.updateActivity(widget.existing!.id, body);
      } else {
        await service.createActivity(body);
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
        title: Text(_isEditing ? 'Edit Activity' : 'Add Activity'),
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
              FutureBuilder<List<AdminDestinationModel>>(
                future: _destinationsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final destinations = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    initialValue: _destinationId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: destinations
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              '${d.name}, ${d.country}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _destinationId = v),
                  );
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'e.g. Colosseum Tour',
                icon: Icons.local_activity_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _locationController,
                label: 'Location',
                hint: 'e.g. Rome',
                icon: Icons.place_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Location is required'
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
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _durationController,
                      label: 'Duration (minutes, optional)',
                      hint: 'e.g. 120',
                      icon: Icons.schedule,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _priceController,
                      label: 'Price (\$)',
                      hint: 'e.g. 45',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || double.tryParse(v.trim()) == null)
                          ? 'Enter a valid price'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _activityCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
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
                  subtitle: const Text(
                    'Inactive activities are hidden from customers',
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Create Activity',
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
