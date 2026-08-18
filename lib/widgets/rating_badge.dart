import 'package:flutter/material.dart';

class RatingBadge extends StatelessWidget {
  final double? rating;
  final int? reviewCount;
  final bool compact;

  const RatingBadge({super.key, required this.rating, this.reviewCount, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (rating == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 3),
          Text(
            reviewCount != null ? '$rating ($reviewCount)' : '$rating',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
