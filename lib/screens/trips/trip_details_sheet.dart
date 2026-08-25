import 'package:flutter/material.dart';
import '../../models/trip_summary.dart';

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// Read-only breakdown for a trip that isn't actionable from the list (a
/// confirmed booking, a confirmed/completed customized tour, or history).
void showTripDetailsSheet(BuildContext context, TripSummary trip) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(trip.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${trip.destinationName}, ${trip.destinationCountry}',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            _row('Travel Date', _fmtDate(trip.travelDate)),
            if (trip.travelEndDate != null) _row('Return Date', _fmtDate(trip.travelEndDate!)),
            _row('Travelers', '${trip.travelers}'),
            _row('Status', trip.effectiveStatus.toUpperCase()),
            if (trip.booking != null) ...[
              _row('Lead Traveler', trip.booking!.leadTravelerName),
              _row('Contact Email', trip.booking!.leadTravelerEmail),
              _row('Contact Phone', trip.booking!.leadTravelerPhone),
              if (trip.booking!.promoCode != null)
                _row('Promo Applied',
                    '${trip.booking!.promoCode} (-\$${trip.booking!.discountAmount.toStringAsFixed(0)})'),
              if (trip.booking!.refundPercent != null)
                _row(
                  'Refund',
                  trip.booking!.refundPercent == 0
                      ? 'None'
                      : '${trip.booking!.refundPercent}% (\$${(trip.totalPrice * trip.booking!.refundPercent! / 100).toStringAsFixed(0)})',
                ),
            ],
            if (trip.customizedTour != null) ...[
              const Divider(height: 32),
              const Text('Price Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _row('Base Package', '\$${trip.customizedTour!.basePrice.toStringAsFixed(0)}'),
              if (trip.customizedTour!.activitiesPrice > 0)
                _row('Added Activities', '\$${trip.customizedTour!.activitiesPrice.toStringAsFixed(0)}'),
              if (trip.customizedTour!.hotel != null)
                _row('Hotel (${trip.customizedTour!.hotel!.category})',
                    '\$${trip.customizedTour!.hotelPrice.toStringAsFixed(0)}'),
              if (trip.customizedTour!.transportation != null)
                _row('Transportation', '\$${trip.customizedTour!.transportationPrice.toStringAsFixed(0)}'),
            ],
            const Divider(height: 32),
            _row('Total', '\$${trip.totalPrice.toStringAsFixed(0)}', bold: true),
          ],
        ),
      ),
    ),
  );
}

Widget _row(String label, String value, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: bold ? Colors.blue : Colors.black87,
          ),
        ),
      ],
    ),
  );
}
