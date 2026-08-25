import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customized_tour_model.dart';
import '../../models/promotion_model.dart';
import '../../models/tour_package_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../providers/search_provider.dart';
import '../../services/api_client.dart';
import '../../services/booking_service.dart';
import '../../services/catalog_service.dart';
import '../../services/customized_tour_service.dart';
import '../../widgets/primary_button.dart';
import '../payment/payment_screen.dart';

/// The single "Review Trip" screen, reached two ways:
/// - The direct "Book" path (default constructor, [packageId]): review the
///   plain package as-is, pick date/travelers, fill in lead traveler
///   details, and pay the package's flat price.
/// - The "Customize Trip" path ([ReviewTripScreen.forCustomizedTour]):
///   review the itinerary already built on CustomizeTripScreen (hotel,
///   transportation, activities) with its computed total, fill in lead
///   traveler details, and confirm + pay — date/travelers are fixed by then
///   so they're shown read-only here.
class ReviewTripScreen extends StatefulWidget {
  final String? packageId;
  final CustomizedTourModel? tour;
  final CustomizedTourService? tourService;

  const ReviewTripScreen({super.key, required String this.packageId})
      : tour = null,
        tourService = null;

  const ReviewTripScreen.forCustomizedTour({
    super.key,
    required this.tour,
    required CustomizedTourService service,
  })  : packageId = null,
        tourService = service;

  @override
  State<ReviewTripScreen> createState() => _ReviewTripScreenState();
}

class _ReviewTripScreenState extends State<ReviewTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  Future<TourPackageModel>? _future;
  int _travelers = 2;
  DateTime _travelDate = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;

  bool get _isCustomized => widget.tour != null;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    if (_isCustomized) {
      _travelers = widget.tour!.travelers;
      _travelDate = widget.tour!.travelDate;
    } else {
      _future = CatalogService().getPackageById(widget.packageId!);
      final search = context.read<SearchProvider>();
      _travelers = search.travelers;
      if (search.startDate != null) _travelDate = search.startDate!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _travelDate = picked);
  }

  Future<void> _pickTravelers(int maxPeople) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int n = 1; n <= maxPeople; n++)
                  ListTile(title: Text('$n Traveler${n > 1 ? 's' : ''}'), onTap: () => Navigator.pop(context, n)),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) setState(() => _travelers = selected);
  }

  Future<void> _pay({TourPackageModel? package}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final subtotal = _isCustomized ? widget.tour!.totalPrice : _totalPrice(package!);
    final promo = context.read<PromotionProvider>().claimed;
    final eligiblePromoCode = (promo != null && promo.discountFor(subtotal) > 0) ? promo.code : null;
    try {
      final booking = _isCustomized
          ? await widget.tourService!.confirm(
              widget.tour!.id,
              leadTravelerName: _nameController.text.trim(),
              leadTravelerEmail: _emailController.text.trim(),
              leadTravelerPhone: _phoneController.text.trim(),
              promoCode: eligiblePromoCode,
            )
          : await BookingService(token: context.read<AuthProvider>().token!).create(
              packageId: package!.id,
              travelers: _travelers,
              travelDate: _travelDate,
              leadTravelerName: _nameController.text.trim(),
              leadTravelerEmail: _emailController.text.trim(),
              leadTravelerPhone: _phoneController.text.trim(),
              promoCode: eligiblePromoCode,
            );
      if (!mounted) return;
      if (eligiblePromoCode != null) context.read<PromotionProvider>().clear();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
      );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not reach the server. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  double _totalPrice(TourPackageModel package) => package.price * _travelers;

  ({PromotionModel promotion, double amount})? _claimedDiscount(double subtotal) {
    final promo = context.watch<PromotionProvider>().claimed;
    if (promo == null) return null;
    final amount = promo.discountFor(subtotal);
    if (amount <= 0) return null;
    return (promotion: promo, amount: amount);
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
        title: const Text('Review Trip'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isCustomized ? _buildCustomizedBody(widget.tour!) : _buildDirectBody(),
    );
  }

  Widget _buildDirectBody() {
    return FutureBuilder<TourPackageModel>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : 'Could not load this package. Please try again.';
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center)));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final package = snapshot.data!;
        final endDate = _travelDate.add(Duration(days: package.durationDays - 1));
        final subtotal = _totalPrice(package);
        final discount = _claimedDiscount(subtotal);

        return _ReviewLayout(
          destinationName: package.destination.name,
          destinationCountry: package.destination.country,
          title: package.title,
          dateLabel: '${_fmt(_travelDate)} - ${_fmt(endDate)}',
          onChangeDate: _pickDate,
          travelers: _travelers,
          onChangeTravelers: () => _pickTravelers(package.maxPeople),
          formKey: _formKey,
          nameController: _nameController,
          emailController: _emailController,
          phoneController: _phoneController,
          priceRows: [
            _PriceRow('Package Price (per person)', package.price),
            _PriceRow('Travelers × $_travelers', null),
            if (discount != null)
              _PriceRow('Promo (${discount.promotion.code})', -discount.amount, isDiscount: true),
          ],
          totalPrice: subtotal - (discount?.amount ?? 0),
          isSubmitting: _isSubmitting,
          onPay: () => _pay(package: package),
        );
      },
    );
  }

  Widget _buildCustomizedBody(CustomizedTourModel tour) {
    final endDate = tour.travelDate.add(Duration(days: tour.tourPackage.durationDays - 1));
    final discount = _claimedDiscount(tour.totalPrice);
    return _ReviewLayout(
      destinationName: tour.destination.name,
      destinationCountry: tour.destination.country,
      title: tour.tourPackage.title,
      dateLabel: '${_fmt(tour.travelDate)} - ${_fmt(endDate)}',
      onChangeDate: null,
      travelers: tour.travelers,
      onChangeTravelers: null,
      formKey: _formKey,
      nameController: _nameController,
      emailController: _emailController,
      phoneController: _phoneController,
      // Mirrors the direct-booking price summary: the per-person price
      // (the same figure shown on the Customize Trip screen) times the
      // traveler count, rather than an itemized hotel/transport/activities
      // breakdown.
      priceRows: [
        _PriceRow('Price per person', tour.totalPrice / tour.travelers),
        _PriceRow('Travelers × ${tour.travelers}', null),
        if (discount != null)
          _PriceRow('Promo (${discount.promotion.code})', -discount.amount, isDiscount: true),
      ],
      totalPrice: tour.totalPrice - (discount?.amount ?? 0),
      isSubmitting: _isSubmitting,
      onPay: () => _pay(),
    );
  }
}

class _PriceRow {
  final String label;
  final double? value;
  final bool isDiscount;
  const _PriceRow(this.label, this.value, {this.isDiscount = false});
}

class _ReviewLayout extends StatelessWidget {
  final String destinationName;
  final String destinationCountry;
  final String title;
  final String dateLabel;
  final VoidCallback? onChangeDate;
  final int travelers;
  final VoidCallback? onChangeTravelers;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final List<_PriceRow> priceRows;
  final double totalPrice;
  final bool isSubmitting;
  final VoidCallback onPay;

  const _ReviewLayout({
    required this.destinationName,
    required this.destinationCountry,
    required this.title,
    required this.dateLabel,
    required this.onChangeDate,
    required this.travelers,
    required this.onChangeTravelers,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.priceRows,
    required this.totalPrice,
    required this.isSubmitting,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.location_on, color: Colors.blue.shade700, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$destinationName, $destinationCountry',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: onChangeDate,
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 15, color: Colors.blue.shade700),
                              const SizedBox(width: 6),
                              Flexible(child: Text(dateLabel, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onChangeTravelers,
                        child: Row(
                          children: [
                            Icon(Icons.people_outline, size: 15, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                            Text('$travelers Travelers', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Traveler Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Form(
              key: formKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid phone number' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Price Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  for (final row in priceRows) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          row.label,
                          style: TextStyle(fontSize: 13, color: row.isDiscount ? Colors.green.shade700 : null),
                        ),
                        if (row.value != null)
                          Text(
                            '${row.isDiscount ? '-' : ''}\$${row.value!.abs().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: row.isDiscount ? Colors.green.shade700 : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  const Divider(height: 0),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('\$${totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: PrimaryButton(
                label: 'Pay \$${totalPrice.toStringAsFixed(0)}',
                isLoading: isSubmitting,
                onPressed: onPay,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
