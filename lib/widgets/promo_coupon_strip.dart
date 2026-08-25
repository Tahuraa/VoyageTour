import 'package:flutter/material.dart';
import '../models/promotion_model.dart';

/// A horizontal strip of claimable promo-code "tickets" shown right below a
/// search bar (Agoda-style), as opposed to the full-size banner carousel
/// used on the Home screen.
class PromoCouponStrip extends StatelessWidget {
  final List<PromotionModel> promotions;
  final PromotionModel? claimed;
  final ValueChanged<PromotionModel> onClaim;

  const PromoCouponStrip({
    super.key,
    required this.promotions,
    required this.claimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    if (promotions.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: promotions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final promotion = promotions[i];
          final isClaimed = claimed?.id == promotion.id;
          return _CouponCard(
            promotion: promotion,
            isClaimed: isClaimed,
            onTap: isClaimed ? null : () => onClaim(promotion),
          );
        },
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final PromotionModel promotion;
  final bool isClaimed;
  final VoidCallback? onTap;

  const _CouponCard({required this.promotion, required this.isClaimed, required this.onTap});

  String get _discountShort =>
      promotion.discountType == 'percentage' ? '${promotion.discountValue.toInt()}%' : '\$${promotion.discountValue.toInt()}';

  @override
  Widget build(BuildContext context) {
    final accent = isClaimed ? Colors.green : Colors.orange;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: CustomPaint(
          painter: _DashedRRectPainter(color: accent.shade200, radius: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: accent.shade50, shape: BoxShape.circle),
                child: Text(
                  _discountShort,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: accent.shade700),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      promotion.code,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      promotion.discountLabel,
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              isClaimed
                  ? Icon(Icons.check_circle, color: Colors.green.shade600, size: 20)
                  : Text(
                      'CLAIM',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blue.shade600),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
