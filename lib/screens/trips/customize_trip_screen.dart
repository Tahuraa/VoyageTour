import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity_model.dart';
import '../../models/customized_tour_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../services/api_client.dart';
import '../../services/customized_tour_service.dart';
import 'review_trip_screen.dart';

class CustomizeTripScreen extends StatefulWidget {
  final String packageId;
  /// When resuming a draft from "My Trips", pass its id so we load the
  /// existing customization instead of starting a brand new draft.
  final String? existingTourId;
  const CustomizeTripScreen({super.key, required this.packageId, this.existingTourId});

  @override
  State<CustomizeTripScreen> createState() => _CustomizeTripScreenState();
}

class _CustomizeTripScreenState extends State<CustomizeTripScreen> {
  late final CustomizedTourService _service;
  CustomizedTourModel? _tour;
  CustomizationOptions? _options;
  String? _error;
  bool _isLoading = true;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _service = CustomizedTourService(token: context.read<AuthProvider>().token!);
    _init();
  }

  Future<void> _init() async {
    try {
      final search = context.read<SearchProvider>();
      final results = await Future.wait([
        widget.existingTourId != null
            ? _service.getById(widget.existingTourId!)
            : _service.create(
                tourPackageId: widget.packageId,
                travelers: search.travelers,
                travelDate: search.startDate ?? DateTime.now().add(const Duration(days: 30)),
              ),
        CustomizedTourService.getOptions(),
      ]);
      setState(() {
        _tour = results[0] as CustomizedTourModel;
        _options = results[1] as CustomizationOptions;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not reach the server. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _mutate(Future<CustomizedTourModel> Function() action) async {
    setState(() => _isMutating = true);
    try {
      final updated = await action();
      if (mounted) setState(() => _tour = updated);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Something went wrong. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _pickDate() async {
    final tour = _tour!;
    final picked = await showDatePicker(
      context: context,
      initialDate: tour.travelDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      await _mutate(() => _service.updateTripDetails(tour.id, travelDate: picked));
    }
  }

  Future<void> _pickTravelers() async {
    final tour = _tour!;
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final n in [1, 2, 3, 4, 5, 6, 7, 8])
                  ListTile(title: Text('$n Traveler${n > 1 ? 's' : ''}'), onTap: () => Navigator.pop(context, n)),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) {
      await _mutate(() => _service.updateTripDetails(tour.id, travelers: selected));
    }
  }

  Future<void> _changeHotel() async {
    final tour = _tour!;
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _HotelPickerSheet(options: _options!.hotelCategories, initialHotel: tour.hotel),
    );
    if (result == null) return;
    if (result['remove'] == 'true') {
      await _mutate(() => _service.clearHotel(tour.id));
    } else {
      await _mutate(() => _service.selectHotel(tour.id, category: result['category']!));
    }
  }

  Future<void> _changeTransportation() async {
    final tour = _tour!;
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _TransportationPickerSheet(
        options: _options!.transportationTypes,
        hasSelection: tour.transportation != null,
      ),
    );
    if (result == null) return;
    if (result == 'remove') {
      await _mutate(() => _service.clearTransportation(tour.id));
    } else {
      await _mutate(() => _service.selectTransportation(tour.id, type: result));
    }
  }

  Future<void> _addActivity(int dayNumber) async {
    final tour = _tour!;
    final activity = await showModalBottomSheet<ActivityModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ActivityPickerSheet(destinationId: tour.destination.id),
    );
    if (activity != null) {
      await _mutate(() => _service.addActivity(tour.id, dayNumber: dayNumber, activityId: activity.id));
    }
  }

  Future<void> _removeActivity(CustomizedActivityEntry entry) async {
    final tour = _tour!;
    await _mutate(() => _service.removeActivity(tour.id, entry.id));
  }

  void _goToReview() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReviewTripScreen.forCustomizedTour(tour: _tour!, service: _service)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Customize Your Trip'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go back')),
            ],
          ),
        ),
      );
    }

    final tour = _tour!;
    final isDraft = tour.status == 'draft';
    final activitiesByDay = tour.activitiesByDay;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          children: [
            _TripSummaryCard(
              tour: tour,
              editable: isDraft,
              onChangeDate: _pickDate,
              onChangeTravelers: _pickTravelers,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Accommodations & Travel'),
            const SizedBox(height: 10),
            _OptionTile(
              icon: Icons.hotel,
              title: 'Hotel Category',
              subtitle: tour.hotel != null
                  ? '${_hotelCategoryLabel(tour.hotel!.category)} • \$${tour.hotel!.price.toStringAsFixed(0)}'
                  : 'Choose a hotel category',
              actionLabel: tour.hotel != null ? 'Change' : 'Add',
              onTap: isDraft ? _changeHotel : null,
            ),
            const SizedBox(height: 10),
            _OptionTile(
              icon: Icons.directions_car_filled,
              title: tour.transportation != null
                  ? _transportLabel(tour.transportation!.type)
                  : 'No transportation selected',
              subtitle: tour.transportation != null
                  ? '\$${tour.transportation!.price.toStringAsFixed(0)}'
                  : 'Add airport & local transport',
              actionLabel: tour.transportation != null ? 'Change' : 'Add',
              onTap: isDraft ? _changeTransportation : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle('Daily Itinerary'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${tour.tourPackage.durationDays} Days',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (int day = 1; day <= tour.tourPackage.durationDays; day++)
              _DayCard(
                dayNumber: day,
                date: tour.travelDate.add(Duration(days: day - 1)),
                entries: activitiesByDay[day] ?? const [],
                editable: isDraft,
                onAddActivity: () => _addActivity(day),
                onRemoveActivity: _removeActivity,
              ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomBar(
            tour: tour,
            isBusy: _isMutating,
            onConfirm: isDraft ? _goToReview : null,
          ),
        ),
      ],
    );
  }
}

String _hotelCategoryLabel(String category) => switch (category) {
      '3_star' => '3-Star',
      '4_star' => '4-Star',
      '5_star' => '5-Star',
      _ => category,
    };

String _transportLabel(String type) => switch (type) {
      'private_car' => 'Private Car',
      'shared_shuttle' => 'Shared Shuttle',
      'tour_bus' => 'Tour Bus',
      _ => type,
    };

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}

class _TripSummaryCard extends StatelessWidget {
  final CustomizedTourModel tour;
  final bool editable;
  final VoidCallback onChangeDate;
  final VoidCallback onChangeTravelers;

  const _TripSummaryCard({
    required this.tour,
    required this.editable,
    required this.onChangeDate,
    required this.onChangeTravelers,
  });

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final endDate = tour.travelDate.add(Duration(days: tour.tourPackage.durationDays - 1));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.location_on, color: Colors.blue.shade700, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tour.destination.name}, ${tour.destination.country}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(tour.tourPackage.title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: editable ? onChangeDate : null,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 15, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text('${_fmt(tour.travelDate)} - ${_fmt(endDate)}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: editable ? onChangeTravelers : null,
                child: Row(
                  children: [
                    Icon(Icons.people_outline, size: 15, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Text('${tour.travelers} Travelers', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (onTap != null)
            TextButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final int dayNumber;
  final DateTime date;
  final List<CustomizedActivityEntry> entries;
  final bool editable;
  final VoidCallback onAddActivity;
  final ValueChanged<CustomizedActivityEntry> onRemoveActivity;

  const _DayCard({
    required this.dayNumber,
    required this.date,
    required this.entries,
    required this.editable,
    required this.onAddActivity,
    required this.onRemoveActivity,
  });

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text('$dayNumber', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DAY $dayNumber', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 0.5)),
                  Text(_fmt(date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('No activities planned', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  for (final entry in entries) _ActivityRow(entry: entry, editable: editable, onRemove: () => onRemoveActivity(entry)),
                ],
              ),
            ),
          if (editable) ...[
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: onAddActivity,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Activity'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final CustomizedActivityEntry entry;
  final bool editable;
  final VoidCallback onRemove;
  const _ActivityRow({required this.entry, required this.editable, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            entry.source == 'added' ? Icons.add_circle : Icons.check_circle,
            size: 16,
            color: entry.source == 'added' ? Colors.blue : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.activity.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  // Package-included activities are bundled into the flat
                  // package price — removing one doesn't change the total,
                  // so show "Included" rather than a price that implies it
                  // would. Only activities the user added on top are priced
                  // separately and actually move the total when removed.
                  entry.source == 'added'
                      ? (entry.price > 0 ? '\$${entry.price.toStringAsFixed(0)}' : 'Free')
                      : 'Included',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (editable)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final CustomizedTourModel tour;
  final bool isBusy;
  final VoidCallback? onConfirm;
  const _BottomBar({required this.tour, required this.isBusy, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRICE PER PERSON', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 0.6)),
                  Text.rich(
                    TextSpan(
                      text: '\$${(tour.totalPrice / tour.travelers).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                      children: [
                        TextSpan(
                          text: ' / person',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: (isBusy || onConfirm == null) ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(onConfirm == null ? 'Confirmed' : 'Confirm Booking', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelPickerSheet extends StatefulWidget {
  final List<HotelCategoryOption> options;
  final SelectedHotel? initialHotel;
  const _HotelPickerSheet({required this.options, required this.initialHotel});

  @override
  State<_HotelPickerSheet> createState() => _HotelPickerSheetState();
}

class _HotelPickerSheetState extends State<_HotelPickerSheet> {
  late String _category = widget.initialHotel?.category ?? widget.options.first.category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hotel Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Choose the star rating for your stay', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.options
                .map(
                  (o) => ChoiceChip(
                    label: Text('${o.label} (\$${o.pricePerNight.toStringAsFixed(0)}/night)'),
                    selected: _category == o.category,
                    onSelected: (_) => setState(() => _category = o.category),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {'category': _category}),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Hotel Category', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          if (widget.initialHotel != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, {'remove': 'true'}),
              child: const Text('Remove hotel', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransportationPickerSheet extends StatelessWidget {
  final List<TransportationTypeOption> options;
  final bool hasSelection;
  const _TransportationPickerSheet({required this.options, required this.hasSelection});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose Transportation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          for (final o in options)
            ListTile(
              leading: const Icon(Icons.directions_car_outlined, color: Colors.blue),
              title: Text(o.label),
              trailing: Text('\$${o.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context, o.type),
            ),
          if (hasSelection)
            ListTile(
              leading: const Icon(Icons.close, color: Colors.redAccent),
              title: const Text('Remove transportation', style: TextStyle(color: Colors.redAccent)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActivityPickerSheet extends StatefulWidget {
  final String destinationId;
  const _ActivityPickerSheet({required this.destinationId});

  @override
  State<_ActivityPickerSheet> createState() => _ActivityPickerSheetState();
}

class _ActivityPickerSheetState extends State<_ActivityPickerSheet> {
  late Future<List<ActivityModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = CustomizedTourService.getActivitiesForDestination(widget.destinationId);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add an Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<ActivityModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final activities = snapshot.data!;
                    if (activities.isEmpty) {
                      return const Center(child: Text('No activities available for this destination'));
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: activities.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final a = activities[i];
                        return ListTile(
                          title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          subtitle: Text(
                            '${a.location} • ${a.durationMinutes ?? '-'} min',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            a.price > 0 ? '\$${a.price.toStringAsFixed(0)}' : 'Free',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          onTap: () => Navigator.pop(context, a),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
