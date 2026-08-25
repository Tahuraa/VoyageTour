class PromotionModel {
  final String id;
  final String code;
  final String? title;
  final String? subtitle;
  final String? badgeLabel;
  final String? imageUrl;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final DateTime validTo;

  PromotionModel({
    required this.id,
    required this.code,
    this.title,
    this.subtitle,
    this.badgeLabel,
    this.imageUrl,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.validTo,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
        id: json['_id'] as String,
        code: json['code'] as String,
        title: json['title'] as String?,
        subtitle: json['subtitle'] as String?,
        badgeLabel: json['badge_label'] as String?,
        imageUrl: json['image_url'] as String?,
        discountType: json['discount_type'] as String,
        discountValue: (json['discount_value'] as num).toDouble(),
        minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
        validTo: DateTime.parse(json['valid_to'] as String),
      );

  String get discountLabel =>
      discountType == 'percentage' ? 'Up to ${discountValue.toInt()}% Off' : '\$${discountValue.toInt()} Off';

  double discountFor(double subtotal) {
    if (subtotal < minOrderAmount) return 0;
    final raw = discountType == 'percentage' ? subtotal * (discountValue / 100) : discountValue;
    return raw.clamp(0, subtotal);
  }
}
