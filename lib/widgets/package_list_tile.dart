import 'package:flutter/material.dart';
import '../models/tour_package_model.dart';

/// Compact horizontal row used for "Popular Tour Packages" on the Home screen.
class PackageListTile extends StatelessWidget {
  final TourPackageModel package;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isFavorite;

  const PackageListTile({
    super.key,
    required this.package,
    required this.onTap,
    required this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: package.imageUrl != null
                  ? Image.network(
                      package.imageUrl!,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(width: 68, height: 68, color: Colors.grey.shade300),
                    )
                  : Container(width: 68, height: 68, color: Colors.grey.shade300),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 3),
                      Text('${package.durationDays} Days', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      if (package.ratingAvg != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.star, size: 13, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text('${package.ratingAvg}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      text: '\$${package.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
                      children: [
                        TextSpan(
                          text: ' / person',
                          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
              ),
              onPressed: onFavoriteTap,
            ),
          ],
        ),
      ),
    );
  }
}
