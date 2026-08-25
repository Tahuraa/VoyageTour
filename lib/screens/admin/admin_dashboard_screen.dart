import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin/admin_destination_model.dart';
import '../../models/admin/admin_stats_model.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../auth/login_screen.dart';
import 'admin_activities_screen.dart';
import 'admin_promotions_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminStatsModel> _statsFuture;
  late Future<List<AdminDestinationModel>> _destinationsFuture;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
    _destinationsFuture = _loadDestinations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<AdminStatsModel> _loadStats() {
    final token = context.read<AuthProvider>().token!;
    return AdminService(token: token).getStats();
  }

  Future<List<AdminDestinationModel>> _loadDestinations() {
    final token = context.read<AuthProvider>().token!;
    return AdminService(token: token).listDestinations();
  }

  Future<void> _refresh() async {
    final stats = _loadStats();
    final destinations = _loadDestinations();
    setState(() {
      _statsFuture = stats;
      _destinationsFuture = destinations;
    });
    await Future.wait([stats, destinations]);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _relativeTime(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _fmtDate(d);
  }

  List<BookingModel> _filterBookings(List<BookingModel> bookings) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return bookings;
    return bookings
        .where(
          (b) =>
              b.package.title.toLowerCase().contains(q) ||
              (b.bookedByName ?? '').toLowerCase().contains(q) ||
              (b.bookedByEmail ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AdminStatsModel>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Could not load dashboard data. Pull to retry.';
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(message, textAlign: TextAlign.center)),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final stats = snapshot.data!;
            final bookings = _filterBookings(stats.recentBookings);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search bookings by package or customer...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _query = '';
                            }),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Global Statistics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _StatCard(
                      icon: Icons.people_outline,
                      label: 'Total Users',
                      value: '${stats.totalUsers}',
                      color: Colors.blue,
                    ),
                    _StatCard(
                      icon: Icons.card_travel,
                      label: 'Total Bookings',
                      value: '${stats.totalBookings}',
                      color: Colors.orange,
                    ),
                    _StatCard(
                      icon: Icons.attach_money,
                      label: 'Total Revenue',
                      value: '\$${stats.totalRevenue.toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                    _StatCard(
                      icon: Icons.map_outlined,
                      label: 'Packages',
                      value: '${stats.totalPackages}',
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bookings by Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: stats.bookingsByStatus.entries
                            .map(
                              (e) => _StatusChip(status: e.key, count: e.value),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _QuickActionCard(
                  icon: Icons.local_activity_outlined,
                  label: 'Manage Activities',
                  subtitle:
                      'Create and edit day-trip activities used in itineraries',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminActivitiesScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _QuickActionCard(
                  icon: Icons.local_offer_outlined,
                  label: 'Manage Offers & Promotions',
                  subtitle: 'Create, edit and remove promo codes and discounts',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminPromotionsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Popular Destinations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 130,
                  child: FutureBuilder<List<AdminDestinationModel>>(
                    future: _destinationsFuture,
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      final list = [
                        ...snap.data!.where((d) => d.status == 'active'),
                      ];
                      list.sort(
                        (a, b) =>
                            (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0),
                      );
                      final show = list.take(8).toList();
                      if (show.isEmpty) {
                        return Center(
                          child: Text(
                            'No active destinations yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      }
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: show.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, i) =>
                            _DestinationMiniCard(destination: show[i]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Bookings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_query.isNotEmpty)
                      Text(
                        '${bookings.length} match(es)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (bookings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        stats.recentBookings.isEmpty
                            ? 'No bookings yet'
                            : 'No matches',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (final b in bookings) ...[
                          _RecentBookingTile(
                            booking: b,
                            relativeTime: _relativeTime(b.createdAt),
                          ),
                          if (b != bookings.last) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.indigo, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _DestinationMiniCard extends StatelessWidget {
  final AdminDestinationModel destination;
  const _DestinationMiniCard({required this.destination});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 130,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (destination.imageUrl != null)
              Image.network(
                destination.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _fallback(),
              )
            else
              _fallback(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 22, 10, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      destination.country,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
    color: Colors.blue.shade100,
    child: Icon(
      Icons.landscape_outlined,
      color: Colors.blue.shade400,
      size: 32,
    ),
  );
}

class _RecentBookingTile extends StatelessWidget {
  final BookingModel booking;
  final String relativeTime;
  const _RecentBookingTile({required this.booking, required this.relativeTime});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = booking.bookedByName ?? 'Unknown';
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final color = _statusColor(booking.status);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade50,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        booking.package.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${booking.package.destination.name}, ${booking.package.destination.country}'
        '${relativeTime.isNotEmpty ? ' • $relativeTime' : ''}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${booking.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            booking.status[0].toUpperCase() + booking.status.substring(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final int count;
  const _StatusChip({required this.status, required this.count});

  ({Color bg, Color fg}) _style() {
    switch (status) {
      case 'confirmed':
        return (bg: Colors.green.shade50, fg: Colors.green.shade700);
      case 'pending':
        return (bg: Colors.orange.shade50, fg: Colors.orange.shade800);
      case 'completed':
        return (bg: Colors.grey.shade200, fg: Colors.grey.shade700);
      case 'cancelled':
        return (bg: Colors.red.shade50, fg: Colors.red.shade700);
      default:
        return (bg: Colors.grey.shade200, fg: Colors.grey.shade700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${status[0].toUpperCase()}${status.substring(1)}: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: style.fg,
        ),
      ),
    );
  }
}
