import 'package:flutter/material.dart';
import '../models/trip_summary.dart';

class TripCard extends StatelessWidget {
  final TripSummary trip;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  // Next/Ongoing show a compact emoji status badge; Past and Draft omit it
  // since the tab itself already says what the trip is.
  final bool showStatusBadge;
  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onCancel,
    this.showStatusBadge = true,
  });

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  ({Color bg, Color fg, String label})? _statusStyle() {
    switch (trip.effectiveStatus) {
      case 'confirmed':
        return (bg: Colors.green.shade50, fg: Colors.green.shade700, label: '🟢 Confirmed');
      case 'pending':
        return (bg: Colors.orange.shade50, fg: Colors.orange.shade800, label: '🟡 Payment Pending');
      case 'cancelled':
        return (bg: Colors.red.shade50, fg: Colors.red.shade700, label: '🔴 Cancelled');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = showStatusBadge ? _statusStyle() : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: trip.imageUrl != null
                  ? Image.network(
                      trip.imageUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(width: 72, height: 72, color: Colors.grey.shade300),
                    )
                  : Container(width: 72, height: 72, color: Colors.grey.shade300),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(trip.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (trip.kind == TripKind.customizedTour)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.tune, size: 14, color: Colors.grey.shade500),
                        ),
                      if (onCancel != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: InkWell(
                            onTap: onCancel,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${trip.destinationName}, ${trip.destinationCountry}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(_fmt(trip.travelDate), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(width: 10),
                      Icon(Icons.people_outline, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('${trip.travelers}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                        status != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                    children: [
                      if (status != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: status.bg, borderRadius: BorderRadius.circular(6)),
                          child: Text(status.label,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: status.fg)),
                        ),
                      Text('\$${trip.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
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
