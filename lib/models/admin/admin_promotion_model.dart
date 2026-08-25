class AdminPromotionModel {
  final String id;
  final String code;
  final String? title;
  final String? subtitle;
  final String? badgeLabel;
  final String? imageUrl;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final DateTime validFrom;
  final DateTime validTo;
  final int? usageLimit;
  final String status;

  AdminPromotionModel({
    required this.id,
    required this.code,
    this.title,
    this.subtitle,
    this.badgeLabel,
    this.imageUrl,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.validFrom,
    required this.validTo,
    this.usageLimit,
    required this.status,
  });

  factory AdminPromotionModel.fromJson(Map<String, dynamic> json) => AdminPromotionModel(
        id: json['_id'] as String,
        code: json['code'] as String,
        title: json['title'] as String?,
        subtitle: json['subtitle'] as String?,
        badgeLabel: json['badge_label'] as String?,
        imageUrl: json['image_url'] as String?,
        discountType: json['discount_type'] as String,
        discountValue: (json['discount_value'] as num).toDouble(),
        minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
        validFrom: DateTime.parse(json['valid_from'] as String),
        validTo: DateTime.parse(json['valid_to'] as String),
        usageLimit: json['usage_limit'] as int?,
        status: json['status'] as String? ?? 'active',
      );
}
