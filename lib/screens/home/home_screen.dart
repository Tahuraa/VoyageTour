import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/destination_model.dart';
import '../../models/promotion_model.dart';
import '../../models/tour_package_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../providers/search_provider.dart';
import '../../services/catalog_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/destination_card.dart';
import '../../widgets/destination_suggestions_list.dart';
import '../../widgets/offer_banner.dart';
import '../../widgets/package_list_tile.dart';
import '../notifications/notifications_screen.dart';
import '../packages/package_details_screen.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToSearch;
  const HomeScreen({super.key, required this.onNavigateToSearch});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _catalogService = CatalogService();
  final _destinationController = TextEditingController();

  late Future<List<DestinationModel>> _featuredDestinations;
  late Future<List<PromotionModel>> _promotions;
  late Future<List<TourPackageModel>> _popularPackages;
  late Future<int> _unreadNotifications;

  @override
  void initState() {
    super.initState();
    _featuredDestinations = _catalogService.getDestinations(featuredOnly: true);
    _promotions = _catalogService.getActivePromotions();
    _popularPackages = _catalogService
        .getPackages(const PackageSearchParams(sort: 'popularity'))
        .then((list) => list.take(5).toList());
    _unreadNotifications = _loadUnreadNotifications();
  }

  Future<int> _loadUnreadNotifications() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return 0;
    try {
      return await NotificationService.unreadCount(token);
    } catch (_) {
      return 0;
    }
  }

  void _openNotifications() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))
        .then((_) {
      if (mounted) {
        setState(() {
          _unreadNotifications = _loadUnreadNotifications();
        });
      }
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  // Only fills the destination field — the user still has to fill in dates
  // and travelers (or accept the defaults) and tap "Search Tour Packages"
  // themselves before a search actually runs.
  void _fillDestination(String name) {
    setState(() => _destinationController.text = name);
  }

  void _claimOffer(PromotionModel promotion) {
    context.read<PromotionProvider>().claim(promotion);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${promotion.code} claimed — it\'ll be applied automatically at checkout')),
    );
  }

  void _openPackage(TourPackageModel package) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PackageDetailsScreen(packageId: package.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.flight, color: Colors.blue, size: 28),
                Row(
                  children: [
                    FutureBuilder<int>(
                      future: _unreadNotifications,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return IconButton(
                          icon: Badge(
                            isLabelVisible: count > 0,
                            label: Text('$count'),
                            child: const Icon(Icons.notifications_none),
                          ),
                          onPressed: _openNotifications,
                        );
                      },
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                          user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null,
                      child: user?.profileImageUrl == null
                          ? Text(
                              user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black, height: 1.2),
                children: [
                  const TextSpan(text: 'Discover your next\n'),
                  TextSpan(text: 'Adventure', style: TextStyle(color: Colors.blue.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SearchShortcutCard(controller: _destinationController, onSearch: widget.onNavigateToSearch),
            const SizedBox(height: 28),
            _SectionHeader(title: 'Popular Destinations', onSeeAll: widget.onNavigateToSearch),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<DestinationModel>>(
                future: _featuredDestinations,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final destinations = snapshot.data!;
                  if (destinations.isEmpty) {
                    return const Center(child: Text('No destinations yet'));
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: destinations.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => DestinationCard(
                      destination: destinations[i],
                      onTap: () => _fillDestination(destinations[i].name),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            FutureBuilder<List<PromotionModel>>(
              future: _promotions,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                final promotions = snapshot.data!;
                final claimed = context.watch<PromotionProvider>().claimed;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(title: 'Special Offers'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: promotions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final promotion = promotions[i];
                          return SizedBox(
                            width: MediaQuery.of(context).size.width - 40,
                            child: OfferBanner(
                              promotion: promotion,
                              isClaimed: claimed?.id == promotion.id,
                              onClaim: () => _claimOffer(promotion),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: 'Popular Tour Packages', onSeeAll: widget.onNavigateToSearch),
            const SizedBox(height: 12),
            FutureBuilder<List<TourPackageModel>>(
              future: _popularPackages,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final packages = snapshot.data!;
                final favorites = context.watch<FavoritesProvider>();
                final token = context.read<AuthProvider>().token;
                return Column(
                  children: [
                    for (final package in packages) ...[
                      PackageListTile(
                        package: package,
                        isFavorite: favorites.isFavorite(package.id),
                        onTap: () => _openPackage(package),
                        onFavoriteTap: token == null ? () {} : () => favorites.toggle(token, package.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'TRENDING SEARCHES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<DestinationModel>>(
              future: _featuredDestinations.then((_) => _catalogService.getDestinations()),
              builder: (context, snapshot) {
                final names = (snapshot.data ?? []).map((d) => d.name).take(6).toList();
                if (names.isEmpty) return const SizedBox.shrink();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: names
                      .map(
                        (name) => ActionChip(
                          label: Text(name),
                          backgroundColor: Colors.white,
                          onPressed: () => _fillDestination(name),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchShortcutCard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  const _SearchShortcutCard({required this.controller, required this.onSearch});

  @override
  State<_SearchShortcutCard> createState() => _SearchShortcutCardState();
}

class _SearchShortcutCardState extends State<_SearchShortcutCard> {
  final _focusNode = FocusNode();
  List<DestinationModel> _allDestinations = [];

  @override
  void initState() {
    super.initState();
    CatalogService().getDestinations().then((list) {
      if (mounted) setState(() => _allDestinations = list);
    });
    _focusNode.addListener(() => setState(() {}));
    widget.controller.addListener(_onDestinationChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onDestinationChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onDestinationChanged() => setState(() {});

  List<DestinationModel> get _suggestions {
    final typed = widget.controller.text.trim().toLowerCase();
    if (typed.isEmpty) return const [];
    return _allDestinations
        .where((d) => d.name.toLowerCase().contains(typed) || d.country.toLowerCase().contains(typed))
        .toList();
  }

  // Requires a destination and travel dates to be filled in before it will
  // actually run a search — selecting a destination or picking dates alone
  // no longer jumps to results on its own.
  void _goToSearch(SearchProvider search) {
    final destination = widget.controller.text.trim();
    final missing = <String>[
      if (destination.isEmpty) 'a destination',
      if (search.startDate == null || search.endDate == null) 'travel dates',
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select ${missing.join(' and ')} to search')));
      return;
    }
    search.searchFor(destination);
    widget.onSearch();
  }

  void _selectDestination(DestinationModel destination) {
    widget.controller.text = destination.name;
    _focusNode.unfocus();
  }

  Future<void> _pickDateRange(SearchProvider search) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      initialDateRange: search.startDate != null && search.endDate != null
          ? DateTimeRange(start: search.startDate!, end: search.endDate!)
          : null,
    );
    if (range != null) search.setDateRange(range.start, range.end);
  }

  Future<void> _pickTravelers(SearchProvider search) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final n in [1, 2, 3, 4, 5, 6])
              ListTile(title: Text('$n Traveler${n > 1 ? 's' : ''}'), onTap: () => Navigator.pop(context, n)),
          ],
        ),
      ),
    );
    if (selected != null) search.setTravelers(selected);
  }

  String _dateLabel(SearchProvider search) {
    if (search.startDate == null || search.endDate == null) return 'Add dates';
    String fmt(DateTime d) => '${_monthNames[d.month - 1]} ${d.day}';
    return '${fmt(search.startDate!)} - ${fmt(search.endDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DESTINATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _focusNode.unfocus(),
                    decoration: InputDecoration(
                      hintText: 'Where do you want to go?',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_focusNode.hasFocus && _suggestions.isNotEmpty)
            DestinationSuggestionsList(suggestions: _suggestions, onSelected: _selectDestination),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniField(
                  icon: Icons.calendar_today_outlined,
                  label: 'DATES',
                  value: _dateLabel(search),
                  onTap: () => _pickDateRange(search),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniField(
                  icon: Icons.people_outline,
                  label: 'TRAVELERS',
                  value: '${search.travelers} People',
                  onTap: () => _pickTravelers(search),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _goToSearch(search),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search Tour Packages', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _MiniField({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text('See all', style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
                Icon(Icons.chevron_right, size: 16, color: Colors.blue.shade600),
              ],
            ),
          ),
      ],
    );
  }
}
