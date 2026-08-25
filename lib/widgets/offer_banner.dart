import 'package:flutter/material.dart';
import '../models/promotion_model.dart';

class OfferBanner extends StatelessWidget {
  final PromotionModel promotion;
  final bool isClaimed;
  final VoidCallback onClaim;

  const OfferBanner({super.key, required this.promotion, this.isClaimed = false, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (promotion.imageUrl != null)
            Image.network(
              promotion.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(color: Colors.blue.shade200),
            )
          else
            Container(color: Colors.blue.shade200),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (promotion.badgeLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      promotion.badgeLabel!,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  promotion.title ?? promotion.discountLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.2),
                ),
                if (promotion.subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    promotion.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ],
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: isClaimed ? null : onClaim,
                  icon: isClaimed ? const Icon(Icons.check, size: 15) : null,
                  label: Text(isClaimed ? 'Claimed' : 'Claim Offer',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClaimed ? Colors.green : Colors.white,
                    foregroundColor: isClaimed ? Colors.white : Colors.black,
                    disabledBackgroundColor: Colors.green,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
