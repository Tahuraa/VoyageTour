import '../models/booking_model.dart';
import 'api_client.dart';

class PaymentIntentResult {
  final String clientSecret;
  final String paymentIntentId;
  PaymentIntentResult({required this.clientSecret, required this.paymentIntentId});
}

class PaymentConfirmResult {
  final BookingModel booking;
  PaymentConfirmResult({required this.booking});
}

class PaymentService {
  final String token;
  PaymentService({required this.token});

  ApiClient get _client => ApiClient(token: token);

  static Future<String> getPublishableKey() async {
    final res = await ApiClient().get('/payments/config');
    return res['publishableKey'] as String? ?? '';
  }

  Future<PaymentIntentResult> createIntent(String bookingId) async {
    final res = await _client.post('/payments/create-intent', {'booking_id': bookingId});
    return PaymentIntentResult(
      clientSecret: res['clientSecret'] as String,
      paymentIntentId: res['paymentIntentId'] as String,
    );
  }

  Future<PaymentConfirmResult> confirm(String paymentIntentId) async {
    final res = await _client.post('/payments/confirm', {'payment_intent_id': paymentIntentId});
    return PaymentConfirmResult(booking: BookingModel.fromJson(res['booking'] as Map<String, dynamic>));
  }
}
