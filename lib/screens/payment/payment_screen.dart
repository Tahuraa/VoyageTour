import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/payment_service.dart';
import '../main_shell.dart';

enum _PaymentState { preparing, ready, processing, error, succeeded }

/// Collects payment for a booking via Stripe's PaymentSheet (test mode).
/// Flow: fetch the publishable key -> create a PaymentIntent for this
/// booking's total_price -> present Stripe's native sheet -> once the user
/// completes it, ask the backend to verify the intent and flip the booking
/// to 'confirmed'.
class PaymentScreen extends StatefulWidget {
  final BookingModel booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PaymentState _state = _PaymentState.preparing;
  String? _errorMessage;
  String? _paymentIntentId;
  late BookingModel _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _prepare();
  }

  Future<void> _prepare() async {
    final token = context.read<AuthProvider>().token!;
    setState(() {
      _state = _PaymentState.preparing;
      _errorMessage = null;
    });
    try {
      final publishableKey = await PaymentService.getPublishableKey();
      if (publishableKey.isEmpty) {
        throw Exception('Payments are not configured yet. Please try again later.');
      }
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();

      final intent = await PaymentService(token: token).createIntent(_booking.id);
      _paymentIntentId = intent.paymentIntentId;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'VoyageTour',
        ),
      );

      if (mounted) setState(() => _state = _PaymentState.ready);
    } on ApiException catch (e) {
      if (mounted) setState(() { _state = _PaymentState.error; _errorMessage = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() { _state = _PaymentState.error; _errorMessage = 'Could not start payment. Please try again.'; });
      }
    }
  }

  Future<void> _pay() async {
    final token = context.read<AuthProvider>().token!;
    setState(() => _state = _PaymentState.processing);
    try {
      await Stripe.instance.presentPaymentSheet();

      final result = await PaymentService(token: token).confirm(_paymentIntentId!);
      if (!mounted) return;
      setState(() {
        _booking = result.booking;
        _state = _PaymentState.succeeded;
      });
    } on StripeException catch (e) {
      final canceled = e.error.code == FailureCode.Canceled;
      if (mounted) {
        setState(() => _state = _PaymentState.ready);
        if (!canceled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.error.localizedMessage ?? 'Payment failed. Please try again.')),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _state = _PaymentState.ready);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = _PaymentState.ready);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Payment could not be completed. Please try again.')));
      }
    }
  }

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _StatusCard(state: _state, errorMessage: _errorMessage),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_booking.package.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      '${_booking.package.destination.name}, ${_booking.package.destination.country}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 24),
                    _row('Travel Dates', '${_fmt(_booking.travelStartDate)} - ${_fmt(_booking.travelEndDate)}'),
                    _row('Travelers', '${_booking.travelers}'),
                    _row('Lead Traveler', _booking.leadTravelerName),
                    _row('Booking Status', _booking.status.toUpperCase()),
                    const Divider(height: 24),
                    _row(
                      _state == _PaymentState.succeeded ? 'Amount Paid' : 'Amount Due',
                      '\$${_booking.totalPrice.toStringAsFixed(0)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _bottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomAction() {
    if (_state == _PaymentState.succeeded) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainShell()),
            (route) => false,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }
    if (_state == _PaymentState.error) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _prepare,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }
    final busy = _state == _PaymentState.preparing || _state == _PaymentState.processing;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: busy ? null : _pay,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: busy
            ? const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text('Pay \$${_booking.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: bold ? Colors.blue : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final _PaymentState state;
  final String? errorMessage;
  const _StatusCard({required this.state, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    late final String title;
    late final String subtitle;

    switch (state) {
      case _PaymentState.succeeded:
        icon = Icons.check_circle;
        color = Colors.green;
        title = 'Payment Successful';
        subtitle = 'Your booking is confirmed. A confirmation has been saved to your account.';
        break;
      case _PaymentState.error:
        icon = Icons.error_outline;
        color = Colors.red;
        title = 'Something went wrong';
        subtitle = errorMessage ?? 'Please try again.';
        break;
      case _PaymentState.preparing:
        icon = Icons.hourglass_top;
        color = Colors.orange;
        title = 'Preparing Payment';
        subtitle = 'Setting up a secure Stripe checkout for your booking…';
        break;
      case _PaymentState.processing:
        icon = Icons.hourglass_top;
        color = Colors.orange;
        title = 'Processing Payment';
        subtitle = 'Complete the checkout in the payment sheet.';
        break;
      case _PaymentState.ready:
        icon = Icons.lock_outline;
        color = Colors.blue;
        title = 'Ready to Pay';
        subtitle = 'Tap below to pay securely with Stripe. This is test mode — no real charge is made.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }
}
