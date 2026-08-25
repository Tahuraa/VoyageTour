import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../models/trip_summary.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../payment/payment_screen.dart';
import '../trips/customize_trip_screen.dart';
import '../trips/trip_details_sheet.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;
  Set<String> _readIds = {};
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppNotification>> _load() async {
    final token = context.read<AuthProvider>().token!;
    final enabled = await NotificationService.isEnabled();
    final notifications = await NotificationService.load(token);
    final readIds = await NotificationService.readIds();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _readIds = readIds;
      });
    }
    return notifications;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _onTapNotification(AppNotification notification) async {
    if (!_readIds.contains(notification.id)) {
      await NotificationService.markRead(notification.id);
      if (mounted) setState(() => _readIds.add(notification.id));
    }
    if (!mounted) return;
    _openTrip(notification.trip);
  }

  void _openTrip(TripSummary trip) {
    if (trip.kind == TripKind.booking && trip.effectiveStatus == 'pending') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentScreen(booking: trip.booking!)));
      return;
    }
    if (trip.kind == TripKind.customizedTour && trip.status == 'draft') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CustomizeTripScreen(
          packageId: trip.customizedTour!.tourPackage.id,
          existingTourId: trip.id,
        ),
      ));
      return;
    }
    showTripDetailsSheet(context, trip);
  }

  Future<void> _markAllRead(List<AppNotification> notifications) async {
    await NotificationService.markAllRead(notifications.map((n) => n.id));
    if (mounted) setState(() => _readIds = notifications.map((n) => n.id).toSet());
  }

  String _relativeDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          FutureBuilder<List<AppNotification>>(
            future: _future,
            builder: (context, snapshot) {
              final notifications = snapshot.data;
              if (notifications == null || notifications.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _markAllRead(notifications),
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Could not load notifications. Pull to retry.')),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Icon(
                    _notificationsEnabled ? Icons.notifications_none : Icons.notifications_off_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _notificationsEnabled ? 'You\'re all caught up' : 'Notifications are turned off',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      _notificationsEnabled
                          ? 'Updates about your trips will show up here.'
                          : 'Turn them back on from Account Settings to see updates about your trips.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, i) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final notification = notifications[i];
                return _NotificationCard(
                  notification: notification,
                  isRead: _readIds.contains(notification.id),
                  dateLabel: _relativeDate(notification.sortDate),
                  onTap: () => _onTapNotification(notification),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isRead;
  final String dateLabel;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isRead,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : notification.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: isRead ? null : Border.all(color: notification.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: notification.color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(notification.icon, color: notification.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 4),
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Text(dateLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
