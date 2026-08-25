import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/trip_summary.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/customized_tour_service.dart';
import '../../services/trips_service.dart';
import '../../widgets/trip_card.dart';
import '../payment/payment_screen.dart';
import 'customize_trip_screen.dart';
import 'trip_details_sheet.dart';

/// Everything the user has going on, tabbed by where a trip stands:
/// Next (upcoming, hasn't started), Ongoing (in progress right now), Past
/// (completed or cancelled, or an old confirmed/pending trip whose dates
/// quietly elapsed), and Draft (customized tours still being put together).
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);
  late Future<List<TripSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<TripSummary>> _load() {
    final token = context.read<AuthProvider>().token!;
    return TripsService.loadMine(token);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() { _future = future; });
    await future;
  }

  void _openTrip(TripSummary trip) {
    // effectiveStatus, not the raw status: a booking whose payment window
    // already expired shows (and behaves) as cancelled, not as still
    // awaiting payment — see TripSummary.effectiveStatus.
    if (trip.kind == TripKind.booking && trip.effectiveStatus == 'pending') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => PaymentScreen(booking: trip.booking!)))
          .then((_) => _refresh());
      return;
    }
    if (trip.kind == TripKind.customizedTour && trip.status == 'draft') {
      Navigator.of(context)
          .push(MaterialPageRoute(
            builder: (_) => CustomizeTripScreen(
              packageId: trip.customizedTour!.tourPackage.id,
              existingTourId: trip.id,
            ),
          ))
          .then((_) => _refresh());
      return;
    }
    showTripDetailsSheet(context, trip);
  }

  bool _isCancellable(TripSummary trip) {
    if (trip.kind == TripKind.booking) return trip.status == 'pending' || trip.status == 'confirmed';
    return trip.status == 'draft';
  }

  // Mirrors the backend's calculateRefundPercent (bookingController.js) so
  // the confirmation dialog can warn the user before they cancel a
  // confirmed (already-paid) booking:
  //   more than 2 weeks before travel   -> full refund
  //   2 weeks or less, more than 7 days -> 30% refund
  //   7 days or less                    -> no refund
  int _refundPercentFor(DateTime travelDate) {
    final daysUntilTrip = travelDate.difference(DateTime.now()).inMilliseconds / (24 * 60 * 60 * 1000);
    final days = daysUntilTrip.ceil();
    if (days > 14) return 100;
    if (days > 7) return 30;
    return 0;
  }

  String _cancellationMessage(TripSummary trip) {
    final base = 'This will cancel your trip to ${trip.destinationName}. This can\'t be undone.';
    if (trip.kind != TripKind.booking || trip.status != 'confirmed') return base;

    final percent = _refundPercentFor(trip.travelDate);
    final refundAmount = trip.totalPrice * percent / 100;
    if (percent == 100) {
      return '$base\n\nYour trip is more than 2 weeks away, so you\'ll receive a full refund of \$${refundAmount.toStringAsFixed(0)}.';
    } else if (percent == 30) {
      return '$base\n\nYour trip is less than 2 weeks away, so you\'ll receive a 30% refund of \$${refundAmount.toStringAsFixed(0)}.';
    } else {
      return '$base\n\nYour trip is 7 days away or less, so no refund will be issued.';
    }
  }

  Future<void> _cancelTrip(TripSummary trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this trip?'),
        content: Text(_cancellationMessage(trip)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep Trip')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Trip', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token!;
    try {
      if (trip.kind == TripKind.booking) {
        final cancelled = await BookingService(token: token).cancel(trip.id);
        await _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_refundResultMessage(cancelled))));
        }
      } else {
        await CustomizedTourService(token: token).cancel(trip.id);
        await _refresh();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not cancel this trip. Please try again.')));
      }
    }
  }

  String _refundResultMessage(BookingModel cancelled) {
    final percent = cancelled.refundPercent;
    if (percent == null) return 'Trip cancelled.';
    if (percent == 0) return 'Trip cancelled. No refund was issued.';
    final refundAmount = cancelled.totalPrice * percent / 100;
    return 'Trip cancelled. A $percent% refund of \$${refundAmount.toStringAsFixed(0)} has been issued.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Next'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Past'),
            Tab(text: 'Draft'),
          ],
        ),
      ),
      body: FutureBuilder<List<TripSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Could not load your trips. Pull to retry.')),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final trips = snapshot.data!;
          return TabBarView(
            controller: _tabController,
            children: [
              _TripList(
                trips: trips.where((t) => t.bucket == TripBucket.next).toList()
                  ..sort((a, b) => a.travelDate.compareTo(b.travelDate)),
                showStatusBadge: true,
                onRefresh: _refresh,
                onTap: _openTrip,
                onCancel: (t) => _isCancellable(t) ? () => _cancelTrip(t) : null,
                emptyIcon: Icons.card_travel_outlined,
                emptyTitle: 'No upcoming trips',
                emptySubtitle: 'Book or customize a tour package to see it here.',
              ),
              _TripList(
                trips: trips.where((t) => t.bucket == TripBucket.ongoing).toList()
                  ..sort((a, b) => a.travelDate.compareTo(b.travelDate)),
                showStatusBadge: true,
                onRefresh: _refresh,
                onTap: _openTrip,
                onCancel: (t) => _isCancellable(t) ? () => _cancelTrip(t) : null,
                emptyIcon: Icons.flight_takeoff,
                emptyTitle: 'No ongoing trips',
                emptySubtitle: 'Trips currently in progress will show up here.',
              ),
              _TripList(
                trips: trips.where((t) => t.bucket == TripBucket.past).toList()
                  ..sort((a, b) => b.travelDate.compareTo(a.travelDate)),
                showStatusBadge: false,
                onRefresh: _refresh,
                onTap: _openTrip,
                onCancel: (_) => null,
                emptyIcon: Icons.history,
                emptyTitle: 'No past trips yet',
                emptySubtitle: 'Completed and cancelled trips will show up here.',
              ),
              _TripList(
                trips: trips.where((t) => t.bucket == TripBucket.draft).toList()
                  ..sort((a, b) => a.travelDate.compareTo(b.travelDate)),
                showStatusBadge: false,
                onRefresh: _refresh,
                onTap: _openTrip,
                onCancel: (t) => _isCancellable(t) ? () => _cancelTrip(t) : null,
                emptyIcon: Icons.edit_note,
                emptyTitle: 'No drafts',
                emptySubtitle: 'Tours you\'re still customizing will show up here.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  final List<TripSummary> trips;
  final bool showStatusBadge;
  final Future<void> Function() onRefresh;
  final ValueChanged<TripSummary> onTap;
  final VoidCallback? Function(TripSummary) onCancel;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _TripList({
    required this.trips,
    required this.showStatusBadge,
    required this.onRefresh,
    required this.onTap,
    required this.onCancel,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: trips.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Icon(emptyIcon, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Center(
                  child: Text(emptyTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      emptySubtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              separatorBuilder: (context, i) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final trip = trips[i];
                return TripCard(
                  trip: trip,
                  showStatusBadge: showStatusBadge,
                  onTap: () => onTap(trip),
                  onCancel: onCancel(trip),
                );
              },
            ),
    );
  }
}
