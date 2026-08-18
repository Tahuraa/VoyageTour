import 'package:flutter/material.dart';
import '../models/tour_package_model.dart';
import 'rating_badge.dart';

/// Large vertical card used for search results.
class PackageResultCard extends StatelessWidget {
  final TourPackageModel package;
  final VoidCallback onViewDetails;

  const PackageResultCard({super.key, required this.package, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: package.imageUrl != null
                    ? Image.network(
                        package.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(color: Colors.grey.shade300),
                      )
                    : Container(color: Colors.grey.shade300),
              ),
              if (package.ratingAvg != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: RatingBadge(rating: package.ratingAvg, reviewCount: package.reviewCount),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.blue.shade400),
                    const SizedBox(width: 3),
                    Text(
                      '${package.destination.name.toUpperCase()}, ${package.destination.country.toUpperCase()}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade600, letterSpacing: 0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(package.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (package.description != null)
                  Text(
                    package.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('${package.durationDays} Days', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 14),
                    Icon(Icons.check_circle_outline, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('Instant Confirmation', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FROM', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 0.6)),
                          Text.rich(
                            TextSpan(
                              text: '\$${package.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                              children: [
                                TextSpan(
                                  text: ' /person',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onViewDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
