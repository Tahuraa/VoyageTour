import 'package:flutter/foundation.dart';
import '../models/promotion_model.dart';

/// Tracks the one offer the user has "claimed" (Home / Special Offers) so
/// Review Trip can apply its discount automatically at checkout without
/// the user having to re-enter a code. Session-only — not persisted.
class PromotionProvider extends ChangeNotifier {
  PromotionModel? _claimed;
  PromotionModel? get claimed => _claimed;

  void claim(PromotionModel promotion) {
    _claimed = promotion;
    notifyListeners();
  }

  void clear() {
    if (_claimed == null) return;
    _claimed = null;
    notifyListeners();
  }
}
