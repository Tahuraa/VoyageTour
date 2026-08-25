import 'package:flutter/material.dart';
import 'trip_summary.dart';

enum NotificationKind { paymentPending, startingSoon, cancelled, confirmed, draftReminder }

/// A notification derived on-device from the user's trips — there's no
/// backend notifications store, so this is computed fresh each load from
/// whatever [TripsService.loadMine] returns, exactly like "My Trips" does.
class AppNotification {
  final String id;
  final NotificationKind kind;
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final DateTime sortDate;
  final TripSummary trip;

  AppNotification({
    required this.id,
    required this.kind,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.sortDate,
    required this.trip,
  });
}

const _kindPriority = {
  NotificationKind.paymentPending: 0,
  NotificationKind.startingSoon: 1,
  NotificationKind.cancelled: 2,
  NotificationKind.confirmed: 3,
  NotificationKind.draftReminder: 4,
};

/// One notification per trip at most, picked by what's most actionable for
/// that trip's current state — a trip never contributes more than one card.
List<AppNotification> notificationsForTrips(List<TripSummary> trips) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final items = <AppNotification>[];

  for (final trip in trips) {
    final status = trip.effectiveStatus;

    if (trip.kind == TripKind.booking && status == 'pending') {
      items.add(AppNotification(
        id: 'pending-${trip.id}',
        kind: NotificationKind.paymentPending,
        icon: Icons.payment,
        color: Colors.orange,
        title: 'Payment Pending',
        message:
            'Complete payment for your trip to ${trip.destinationName} — \$${trip.totalPrice.toStringAsFixed(0)}',
        sortDate: trip.travelDate,
        trip: trip,
      ));
      continue;
    }

    if (status == 'cancelled') {
      final refundPercent = trip.booking?.refundPercent;
      final message = refundPercent == null
          ? 'Your trip to ${trip.destinationName} was cancelled.'
          : refundPercent == 0
              ? 'Your trip to ${trip.destinationName} was cancelled. No refund was issued.'
              : 'Your trip to ${trip.destinationName} was cancelled. A $refundPercent% refund of '
                  '\$${(trip.totalPrice * refundPercent / 100).toStringAsFixed(0)} has been issued.';
      items.add(AppNotification(
        id: 'cancelled-${trip.id}',
        kind: NotificationKind.cancelled,
        icon: Icons.cancel_outlined,
        color: Colors.red,
        title: 'Trip Cancelled',
        message: message,
        sortDate: trip.travelDate,
        trip: trip,
      ));
      continue;
    }

    if (trip.kind == TripKind.customizedTour && status == 'draft') {
      items.add(AppNotification(
        id: 'draft-${trip.id}',
        kind: NotificationKind.draftReminder,
        icon: Icons.edit_note,
        color: Colors.blue,
        title: 'Unfinished Trip',
        message: 'Continue customizing your trip to ${trip.destinationName}.',
        sortDate: trip.travelDate,
        trip: trip,
      ));
      continue;
    }

    if (status == 'confirmed') {
      final startDay = DateTime(trip.travelDate.year, trip.travelDate.month, trip.travelDate.day);
      final daysUntil = startDay.difference(today).inDays;
      if (trip.bucket == TripBucket.next && daysUntil >= 0 && daysUntil <= 7) {
        items.add(AppNotification(
          id: 'soon-${trip.id}',
          kind: NotificationKind.startingSoon,
          icon: Icons.flight_takeoff,
          color: Colors.blue,
          title: 'Trip Starting Soon',
          message: 'Your trip to ${trip.destinationName} starts '
              '${daysUntil == 0 ? 'today' : 'in $daysUntil day${daysUntil == 1 ? '' : 's'}'}!',
          sortDate: trip.travelDate,
          trip: trip,
        ));
      } else {
        items.add(AppNotification(
          id: 'confirmed-${trip.id}',
          kind: NotificationKind.confirmed,
          icon: Icons.check_circle_outline,
          color: Colors.green,
          title: 'Trip Confirmed',
          message: 'Your trip to ${trip.destinationName} is confirmed.',
          sortDate: trip.travelDate,
          trip: trip,
        ));
      }
    }
  }

  // Most urgent first (payment due, starting soon, cancellations needing
  // attention), then everything else soonest-first within its own group.
  items.sort((a, b) {
    final byKind = _kindPriority[a.kind]!.compareTo(_kindPriority[b.kind]!);
    if (byKind != 0) return byKind;
    return a.sortDate.compareTo(b.sortDate);
  });

  return items;
}
