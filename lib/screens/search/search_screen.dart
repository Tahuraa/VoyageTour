import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/destination_model.dart';
import '../../models/promotion_model.dart';
import '../../providers/promotion_provider.dart';
import '../../providers/search_provider.dart';
import '../../services/catalog_service.dart';
import '../../widgets/destination_suggestions_list.dart';
import '../../widgets/package_result_card.dart';
import '../../widgets/promo_coupon_strip.dart';
import '../packages/package_details_screen.dart';

const _categories = <String, String>{
  'adventure': 'Adventure',
  'beach': 'Beach',
  'cultural': 'Cultural',
  'city': 'City',
  'nature': 'Nature',
  'luxury': 'Luxury',
  'family': 'Family',
  'honeymoon': 'Honeymoon',
};

const _sortOptions = <String, String>{
  'popularity': 'Recommended',
  'rating': 'Highest Rated',
  'price_asc': 'Price: Low to High',
  'price_desc': 'Price: High to Low',
};

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  List<DestinationModel> _allDestinations = [];
  late final Future<List<PromotionModel>> _promotionsFuture;

  @override
  void initState() {
    super.initState();
    CatalogService().getDestinations().then((list) {
      if (mounted) setState(() => _allDestinations = list);
    });
    _focusNode.addListener(() => setState(() {}));
    _promotionsFuture = CatalogService().getActivePromotions();
  }

  void _claimOffer(PromotionModel promotion) {
    context.read<PromotionProvider>().claim(promotion);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${promotion.code} claimed — it\'ll be applied automatically at checkout')),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<DestinationModel> get _suggestions {
    final typed = _textController.text.trim().toLowerCase();
    final search = context.read<SearchProvider>();
    return _allDestinations.where((d) {
      final alreadyAdded = search.destinations.any((s) => s.toLowerCase() == d.name.toLowerCase());
      if (alreadyAdded) return false;
      if (typed.isEmpty) return true;
      return d.name.toLowerCase().contains(typed) || d.country.toLowerCase().contains(typed);
    }).toList();
  }

  void _addDestination(SearchProvider search, String value) {
    if (value.trim().isEmpty) return;
    search.addDestination(value);
    _textController.clear();
    setState(() {});
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
    if (range != null) {
      search.setDateRange(range.start, range.end);
      if (search.hasSearched) search.search();
    }
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

  void _openFilters(SearchProvider search) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _FiltersSheet(search: search),
    );
  }

  String _dateLabel(SearchProvider search) {
    if (search.startDate == null || search.endDate == null) return 'Add dates';
    String fmt(DateTime d) => '${_month(d.month)} ${d.day}';
    return '${fmt(search.startDate!)} - ${fmt(search.endDate!)}';
  }

  String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  _DestinationInput(
                    destinations: search.destinations,
                    controller: _textController,
                    focusNode: _focusNode,
                    onRemove: search.removeDestination,
                    onSubmitted: (value) => _addDestination(search, value),
                    onFiltersTap: () => _openFilters(search),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_focusNode.hasFocus && _suggestions.isNotEmpty)
                    DestinationSuggestionsList(
                      suggestions: _suggestions,
                      onSelected: (d) => _addDestination(search, d.name),
                    ),
                  const SizedBox(height: 10),
                  // Hidden while the destination field is focused: the keyboard
                  // (plus the suggestions dropdown) already leaves little
                  // vertical room, and this fixed-height panel isn't scrollable.
                  if (!_focusNode.hasFocus)
                    FutureBuilder<List<PromotionModel>>(
                      future: _promotionsFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                        final claimed = context.watch<PromotionProvider>().claimed;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PromoCouponStrip(
                            promotions: snapshot.data!,
                            claimed: claimed,
                            onClaim: _claimOffer,
                          ),
                        );
                      },
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _ChipButton(
                          icon: Icons.calendar_today_outlined,
                          label: _dateLabel(search),
                          onTap: () => _pickDateRange(search),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ChipButton(
                          icon: Icons.people_outline,
                          label: '${search.travelers} Traveler${search.travelers > 1 ? 's' : ''}',
                          onTap: () => _pickTravelers(search),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_textController.text.trim().isNotEmpty) {
                                _addDestination(search, _textController.text);
                              } else {
                                search.search();
                              }
                            },
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('Search'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        initialValue: search.sort,
                        onSelected: (value) {
                          search.setSort(value);
                          if (search.hasSearched) search.search();
                        },
                        itemBuilder: (context) => _sortOptions.entries
                            .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.sort, size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Text(_sortOptions[search.sort]!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _ResultsArea(search: search)),
          ],
        ),
      ),
    );
  }
}

class _DestinationInput extends StatelessWidget {
  final List<String> destinations;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback onFiltersTap;

  const _DestinationInput({
    required this.destinations,
    required this.controller,
    required this.focusNode,
    required this.onRemove,
    required this.onSubmitted,
    required this.onChanged,
    required this.onFiltersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 10), child: Icon(Icons.search, color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final destination in destinations)
                  Chip(
                    label: Text(destination, style: const TextStyle(fontSize: 13)),
                    backgroundColor: Colors.blue.shade50,
                    deleteIcon: const Icon(Icons.close, size: 15),
                    onDeleted: () => onRemove(destination),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide.none,
                  ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: destinations.isEmpty ? 'Where do you want to go?' : 'Add another...',
                      hintStyle: const TextStyle(fontSize: 13),
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.tune),
            onPressed: onFiltersTap,
          ),
        ],
      ),
    );
  }
}

class _ResultsArea extends StatelessWidget {
  final SearchProvider search;
  const _ResultsArea({required this.search});

  @override
  Widget build(BuildContext context) {
    if (search.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (search.error != null) {
      return _ScrollableCenter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(search.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (!search.hasSearched) {
      return _ScrollableCenter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Add one or more destinations to explore tour packages',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    if (search.results.isEmpty) {
      return _ScrollableCenter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No experiences found. Try different filters.', style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        if (search.destinations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              search.destinations.join(', '),
              style: TextStyle(fontSize: 12, color: Colors.blue.shade600, fontWeight: FontWeight.w600),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${search.results.length} Experiences Found', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('PRICES IN USD', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 14),
        for (final package in search.results)
          PackageResultCard(
            package: package,
            onViewDetails: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PackageDetailsScreen(packageId: package.id)),
            ),
          ),
      ],
    );
  }
}

/// Centers [child] when there's room, but scrolls instead of overflowing
/// when the available height shrinks (e.g. the keyboard opening above a
/// fixed-height search panel).
class _ScrollableCenter extends StatelessWidget {
  final Widget child;
  const _ScrollableCenter({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChipButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  final SearchProvider search;
  const _FiltersSheet({required this.search});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _category = widget.search.category;
  late RangeValues _priceRange = RangeValues(
    widget.search.minPrice ?? 0,
    widget.search.maxPrice ?? 3000,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('TRIP CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.entries
                .map(
                  (e) => ChoiceChip(
                    label: Text(e.value),
                    selected: _category == e.key,
                    onSelected: (selected) => setState(() => _category = selected ? e.key : null),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text('BUDGET (USD)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 3000,
            divisions: 30,
            labels: RangeLabels('\$${_priceRange.start.round()}', '\$${_priceRange.end.round()}'),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.search.setCategory(_category);
                widget.search.setPriceRange(_priceRange.start, _priceRange.end);
                Navigator.pop(context);
                widget.search.search();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
