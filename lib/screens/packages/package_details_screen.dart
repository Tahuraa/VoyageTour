import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tour_package_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/api_client.dart';
import '../../services/catalog_service.dart';
import '../trips/customize_trip_screen.dart';
import '../trips/review_trip_screen.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String packageId;
  const PackageDetailsScreen({super.key, required this.packageId});

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  final _catalogService = CatalogService();
  late Future<TourPackageModel> _future;
  bool _showAllDays = false;

  @override
  void initState() {
    super.initState();
    _future = _catalogService.getPackageById(widget.packageId);
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<TourPackageModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Could not load this package. Please try again.';
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go back')),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final package = snapshot.data!;
          final visibleDays = _showAllDays ? package.itinerary : package.itinerary.take(4).toList();
          final remainingDays = package.itinerary.length - visibleDays.length;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 280,
                    backgroundColor: Colors.white,
                    leading: _RoundIconButton(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
                    actions: [
                      _RoundIconButton(icon: Icons.share_outlined, onTap: () => _comingSoon('Sharing')),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final favorites = context.watch<FavoritesProvider>();
                          final token = context.read<AuthProvider>().token;
                          final isFavorite = favorites.isFavorite(package.id);
                          return _RoundIconButton(
                            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                            iconColor: isFavorite ? Colors.red : Colors.white,
                            onTap: token == null ? () {} : () => favorites.toggle(token, package.id),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: package.imageUrl != null
                          ? Image.network(
                              package.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Container(color: Colors.grey.shade300),
                            )
                          : Container(color: Colors.grey.shade300),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 190),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 15, color: Colors.blue.shade400),
                              const SizedBox(width: 4),
                              Text(
                                '${package.destination.name.toUpperCase()}, ${package.destination.country.toUpperCase()}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade600, letterSpacing: 0.4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(package.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.25)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (package.ratingAvg != null) ...[
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('${package.ratingAvg} (${package.reviewCount} Reviews)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(width: 12),
                              ],
                              GestureDetector(
                                onTap: () => _comingSoon('Map view'),
                                child: Text('View on Map', style: TextStyle(color: Colors.blue.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(child: _InfoChip(icon: Icons.schedule, label: '${package.durationDays} Days')),
                              const SizedBox(width: 10),
                              Expanded(child: _InfoChip(icon: Icons.category_outlined, label: _categoryLabel(package.category))),
                              const SizedBox(width: 10),
                              Expanded(child: _InfoChip(icon: Icons.people_outline, label: 'Up to ${package.maxPeople}')),
                            ],
                          ),
                          const SizedBox(height: 26),
                          const Text('About this tour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            package.description ?? '',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                          ),
                          if (package.includedServices.isNotEmpty) ...[
                            const SizedBox(height: 26),
                            const Text("What's Included", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            for (final service in package.includedServices)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle, size: 18, color: Colors.green),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(service, style: const TextStyle(fontSize: 13.5))),
                                  ],
                                ),
                              ),
                          ],
                          if (package.itinerary.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Itinerary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('${package.itinerary.length} Days Total', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (final day in visibleDays) _ItineraryDayCard(day: day, expandedByDefault: day.dayNumber == 1),
                            if (remainingDays > 0)
                              TextButton(
                                onPressed: () => setState(() => _showAllDays = true),
                                child: Text('Show Remaining $remainingDays Days'),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BookingBar(
                  package: package,
                  onCustomize: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CustomizeTripScreen(packageId: package.id)),
                  ),
                  onBook: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ReviewTripScreen(packageId: package.id)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _categoryLabel(String category) =>
      category.isEmpty ? '' : '${category[0].toUpperCase()}${category.substring(1)}';
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  const _RoundIconButton({required this.icon, required this.onTap, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        child: IconButton(icon: Icon(icon, color: iconColor, size: 18), onPressed: onTap),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ItineraryDayCard extends StatefulWidget {
  final ItineraryDay day;
  final bool expandedByDefault;
  const _ItineraryDayCard({required this.day, this.expandedByDefault = false});

  @override
  State<_ItineraryDayCard> createState() => _ItineraryDayCardState();
}

class _ItineraryDayCardState extends State<_ItineraryDayCard> {
  late bool _expanded = widget.expandedByDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text('${widget.day.dayNumber}', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAY ${widget.day.dayNumber}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 0.5)),
                        Text(widget.day.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.day.description != null)
                    Text(widget.day.description!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
                  if (widget.day.activities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    for (final entry in widget.day.activities) _ItineraryActivityRow(entry: entry),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

IconData _iconForActivityCategory(String category) {
  switch (category) {
    case 'sightseeing':
      return Icons.photo_camera_outlined;
    case 'adventure':
      return Icons.terrain;
    case 'food':
      return Icons.restaurant;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'culture':
      return Icons.museum_outlined;
    case 'nature':
      return Icons.park_outlined;
    case 'beach':
      return Icons.beach_access_outlined;
    case 'entertainment':
      return Icons.celebration_outlined;
    case 'transport':
      return Icons.directions_car_outlined;
    default:
      return Icons.place_outlined;
  }
}

class _ItineraryActivityRow extends StatelessWidget {
  final ItineraryActivityEntry entry;
  const _ItineraryActivityRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final activity = entry.activity;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconForActivityCategory(activity.category), size: 16, color: Colors.blue.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(activity.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                    ),
                    if (entry.isOptional)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text('Optional', style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Text(activity.location, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    if (activity.durationMinutes != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.schedule, size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text('${activity.durationMinutes} min', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.price > 0 ? '\$${activity.price.toStringAsFixed(0)}' : 'Free',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue.shade600),
          ),
        ],
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  final TourPackageModel package;
  final VoidCallback onCustomize;
  final VoidCallback onBook;
  const _BookingBar({required this.package, required this.onCustomize, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('STARTING FROM', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 0.6)),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    text: '\$${package.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    children: [
                      TextSpan(text: ' /person', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCustomize,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Customize Trip', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Book', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
