import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin/admin_activity_model.dart';
import '../../models/admin/admin_destination_model.dart';
import '../../models/admin/admin_package_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'admin_activities_screen.dart';

const _packageStatusFilters = ['all', 'active', 'inactive'];

const _packageCategories = [
  'adventure',
  'beach',
  'cultural',
  'city',
  'nature',
  'luxury',
  'family',
  'honeymoon',
];

const _pickerActivityCategories = [
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

class AdminPackagesScreen extends StatefulWidget {
  const AdminPackagesScreen({super.key});

  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  late Future<List<AdminPackageModel>> _future;
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

  Future<List<AdminPackageModel>> _load() {
    final token = context.read<AuthProvider>().token!;
    return AdminService(token: token).listPackages();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  List<AdminPackageModel> _applyFilters(List<AdminPackageModel> packages) {
    var result = packages;
    if (_statusFilter != 'all') {
      result = result.where((p) => p.status == _statusFilter).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.title.toLowerCase().contains(q) ||
                p.destination.name.toLowerCase().contains(q) ||
                p.destination.country.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  Future<void> _openForm({AdminPackageModel? existing}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _PackageFormScreen(existing: existing)),
    );
    if (changed == true) _refresh();
  }

  Future<void> _delete(AdminPackageModel pkg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete package?'),
        content: Text('This will permanently delete "${pkg.title}".'),
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
      await AdminService(token: token).deletePackage(pkg.id);
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
        title: const Text('Packages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.local_activity_outlined),
            tooltip: 'Manage Activities',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminActivitiesScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminPackageModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text('Could not load packages. Pull to retry.'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final packages = _applyFilters(snapshot.data!);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search packages...',
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
                    for (final f in _packageStatusFilters)
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
                  'FOUND ${packages.length} TOUR PACKAGE${packages.length == 1 ? '' : 'S'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                if (packages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No packages found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  for (final p in packages) ...[
                    _PackageCard(
                      package: p,
                      onTap: () => _openForm(existing: p),
                      onEdit: () => _openForm(existing: p),
                      onDelete: () => _delete(p),
                    ),
                    const SizedBox(height: 12),
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

class _PackageCard extends StatelessWidget {
  final AdminPackageModel package;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PackageCard({
    required this.package,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _imageFallback() => Container(
    color: Colors.blue.shade50,
    child: Icon(Icons.card_travel, color: Colors.blue.shade300, size: 36),
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: package.imageUrl != null
                      ? Image.network(
                          package.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              _imageFallback(),
                        )
                      : _imageFallback(),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _StatusPill(status: package.status),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          package.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${package.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${package.destination.name}, ${package.destination.country} • ${package.durationDays} days',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${package.itinerary.length} itinerary day(s)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
          ],
        ),
      ),
    );
  }
}

class _DayDraft {
  int dayNumber;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  List<AdminItineraryActivity> activities;

  _DayDraft({
    required this.dayNumber,
    String title = '',
    String description = '',
    List<AdminItineraryActivity>? activities,
  }) : titleController = TextEditingController(text: title),
       descriptionController = TextEditingController(text: description),
       activities = activities ?? [];

  AdminItineraryDay toModel() => AdminItineraryDay(
    dayNumber: dayNumber,
    title: titleController.text.trim().isEmpty
        ? 'Day $dayNumber'
        : titleController.text.trim(),
    description: descriptionController.text.trim().isEmpty
        ? null
        : descriptionController.text.trim(),
    activities: activities,
  );

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}

class _PackageFormScreen extends StatefulWidget {
  final AdminPackageModel? existing;
  const _PackageFormScreen({this.existing});

  @override
  State<_PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<_PackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _maxPeopleController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _includedServicesController;
  late String _category;
  late bool _isActive;
  String? _destinationId;
  bool _isSubmitting = false;
  late Future<List<AdminDestinationModel>> _destinationsFuture;

  List<_DayDraft> _days = [];
  List<AdminActivityModel>? _destActivities;
  bool _loadingDestActivities = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _priceController = TextEditingController(
      text: e?.price.toStringAsFixed(0) ?? '',
    );
    _durationController = TextEditingController(
      text: e?.durationDays.toString() ?? '',
    );
    _maxPeopleController = TextEditingController(
      text: e?.maxPeople.toString() ?? '',
    );
    _imageUrlController = TextEditingController(text: e?.imageUrl ?? '');
    _includedServicesController = TextEditingController(
      text: (e?.includedServices ?? []).join('\n'),
    );
    _category = e?.category ?? _packageCategories.first;
    _isActive = (e?.status ?? 'active') == 'active';
    _destinationId = e?.destination.id;
    _days = (e?.itinerary ?? [])
        .map(
          (d) => _DayDraft(
            dayNumber: d.dayNumber,
            title: d.title,
            description: d.description ?? '',
            activities: List.of(d.activities),
          ),
        )
        .toList();

    final token = context.read<AuthProvider>().token!;
    _destinationsFuture = AdminService(token: token).listDestinations();
    if (_destinationId != null) _loadDestActivities();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _maxPeopleController.dispose();
    _imageUrlController.dispose();
    _includedServicesController.dispose();
    for (final d in _days) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDestActivities() async {
    if (_destinationId == null) {
      setState(() => _destActivities = null);
      return;
    }
    setState(() => _loadingDestActivities = true);
    final token = context.read<AuthProvider>().token!;
    try {
      final list = await AdminService(
        token: token,
      ).listActivities(destinationId: _destinationId);
      if (!mounted) return;
      setState(() {
        _destActivities = list;
        _loadingDestActivities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDestActivities = false);
    }
  }

  Future<void> _syncDaysToDuration() async {
    final duration = int.tryParse(_durationController.text.trim());
    if (duration == null || duration < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid duration (days) first')),
      );
      return;
    }
    if (duration < _days.length) {
      final toRemove = _days.sublist(duration);
      final hasData = toRemove.any(
        (d) =>
            d.activities.isNotEmpty ||
            d.descriptionController.text.trim().isNotEmpty,
      );
      if (hasData) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove days?'),
            content: Text(
              'Reducing to $duration days will delete ${toRemove.length} day(s) and their activities. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }
    if (!mounted) return;
    setState(() {
      if (duration > _days.length) {
        for (var i = _days.length; i < duration; i++) {
          _days.add(_DayDraft(dayNumber: i + 1, title: 'Day ${i + 1}'));
        }
      } else if (duration < _days.length) {
        for (final d in _days.sublist(duration)) {
          d.dispose();
        }
        _days = _days.sublist(0, duration);
      }
    });
  }

  void _addDay() {
    setState(
      () => _days.add(
        _DayDraft(
          dayNumber: _days.length + 1,
          title: 'Day ${_days.length + 1}',
        ),
      ),
    );
  }

  Future<void> _removeDay(int index) async {
    final day = _days[index];
    if (day.activities.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove this day?'),
          content: Text(
            'This will delete "${day.titleController.text.trim().isEmpty ? 'Day ${day.dayNumber}' : day.titleController.text}" and its ${day.activities.length} activity/activities.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    setState(() {
      day.dispose();
      _days.removeAt(index);
      for (var i = 0; i < _days.length; i++) {
        _days[i].dayNumber = i + 1;
      }
    });
  }

  Future<void> _addActivityToDay(int dayIndex) async {
    if (_destinationId == null) return;
    final picked = await showModalBottomSheet<AdminActivityModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivityPickerSheet(
        destinationId: _destinationId!,
        activities: _destActivities,
        loading: _loadingDestActivities,
        onCreated: (created) {
          setState(() {
            _destActivities = [...(_destActivities ?? []), created];
          });
        },
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _days[dayIndex].activities.add(
        AdminItineraryActivity(
          activityId: picked.id,
          activityName: picked.name,
          activityPrice: picked.price,
        ),
      );
    });
  }

  void _removeActivityFromDay(int dayIndex, int activityIndex) {
    setState(() => _days[dayIndex].activities.removeAt(activityIndex));
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
    final includedServices = _includedServicesController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final body = {
      'destination_id': _destinationId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'duration_days': int.tryParse(_durationController.text.trim()) ?? 1,
      'max_people': int.tryParse(_maxPeopleController.text.trim()) ?? 1,
      'image_url': _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      'category': _category,
      'included_services': includedServices,
      'status': _isActive ? 'active' : 'inactive',
      'itinerary': _days.map((d) => d.toModel().toJson()).toList(),
    };
    try {
      final service = AdminService(token: token);
      if (_isEditing) {
        await service.updatePackage(widget.existing!.id, body);
      } else {
        await service.createPackage(body);
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

  Widget _buildDayCard(int index) {
    final day = _days[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DAY ${day.dayNumber}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _removeDay(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: day.titleController,
            decoration: InputDecoration(
              labelText: 'Day title',
              hintText: 'e.g. Arrival & City Tour',
              isDense: true,
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: day.descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              isDense: true,
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (day.activities.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < day.activities.length; i++)
                  Chip(
                    label: Text(
                      '${day.activities[i].activityName} • \$${day.activities[i].activityPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () => _removeActivityFromDay(index, i),
                    backgroundColor: Colors.grey.shade100,
                  ),
              ],
            ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => _addActivityToDay(index),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Activity'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Package' : 'Add Package'),
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
                    onChanged: (v) {
                      setState(() => _destinationId = v);
                      _loadDestActivities();
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'e.g. Italy Highlights',
                icon: Icons.card_travel_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
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
                      controller: _priceController,
                      label: 'Price (\$/person)',
                      hint: 'e.g. 1100',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || double.tryParse(v.trim()) == null)
                          ? 'Enter a valid price'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _durationController,
                      label: 'Duration (days)',
                      hint: 'e.g. 8',
                      icon: Icons.schedule,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || int.tryParse(v.trim()) == null)
                          ? 'Enter valid days'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _maxPeopleController,
                label: 'Max People',
                hint: 'e.g. 10',
                icon: Icons.people_outline,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v.trim()) == null)
                    ? 'Enter a valid number'
                    : null,
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
                items: _packageCategories
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
              const SizedBox(height: 14),
              Text(
                'INCLUDED SERVICES (one per line)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _includedServicesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Airport transfers\nHotel accommodation\nDaily breakfast',
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text(
                    'Inactive packages are hidden from customers',
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'ITINERARY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _destinationId == null
                        ? null
                        : _syncDaysToDuration,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync to duration'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_destinationId == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Select a destination above to build the day-by-day itinerary.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                )
              else ...[
                for (var i = 0; i < _days.length; i++) _buildDayCard(i),
                OutlinedButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Day'),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Create Package',
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

class _ActivityPickerSheet extends StatefulWidget {
  final String destinationId;
  final List<AdminActivityModel>? activities;
  final bool loading;
  final ValueChanged<AdminActivityModel> onCreated;

  const _ActivityPickerSheet({
    required this.destinationId,
    required this.activities,
    required this.loading,
    required this.onCreated,
  });

  @override
  State<_ActivityPickerSheet> createState() => _ActivityPickerSheetState();
}

class _ActivityPickerSheetState extends State<_ActivityPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createNew() async {
    final created = await showDialog<AdminActivityModel>(
      context: context,
      builder: (context) =>
          _QuickActivityDialog(destinationId: widget.destinationId),
    );
    if (created != null) {
      widget.onCreated(created);
      if (mounted) Navigator.of(context).pop(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.activities ?? [];
    final filtered = _query.isEmpty
        ? all
        : all
              .where((a) => a.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _createNew,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search activities...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? Center(
                      child: Text(
                        all.isEmpty
                            ? 'No activities yet for this destination. Create one.'
                            : 'No matches.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: filtered.length,
                      separatorBuilder: (context, i) =>
                          const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final a = filtered[i];
                        return ListTile(
                          title: Text(a.name),
                          subtitle: Text('${a.category} • ${a.location}'),
                          trailing: Text(
                            '\$${a.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(a),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActivityDialog extends StatefulWidget {
  final String destinationId;
  const _QuickActivityDialog({required this.destinationId});

  @override
  State<_QuickActivityDialog> createState() => _QuickActivityDialogState();
}

class _QuickActivityDialogState extends State<_QuickActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  String _category = _pickerActivityCategories.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final token = context.read<AuthProvider>().token!;
    try {
      final created = await AdminService(token: token).createActivity({
        'destination_id': widget.destinationId,
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'category': _category,
        'duration_minutes': _durationController.text.trim().isEmpty
            ? null
            : int.tryParse(_durationController.text.trim()),
      });
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create activity.')),
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Activity'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || double.tryParse(v.trim()) == null)
                          ? 'Invalid'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(labelText: 'Minutes'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _pickerActivityCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
