import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/favorite_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/favorite_service.dart';
import '../../widgets/package_list_tile.dart';
import '../packages/package_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<FavoriteModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<FavoriteModel>> _load() {
    final token = context.read<AuthProvider>().token!;
    return FavoriteService(token: token).list();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() { _future = future; });
    await future;
  }

  void _unfavorite(String packageId) {
    final token = context.read<AuthProvider>().token!;
    context.read<FavoritesProvider>().toggle(token, packageId);
    setState(() {
      _future = _future.then((list) => list.where((f) => f.package.id != packageId).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<FavoriteModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Could not load your favorites. Pull to retry.')),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final favorites = snapshot.data!;
            if (favorites.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.favorite_border, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('No favorites yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Tap the heart on a tour package to save it here.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (context, i) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final favorite = favorites[i];
                return PackageListTile(
                  package: favorite.package,
                  isFavorite: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PackageDetailsScreen(packageId: favorite.package.id)),
                  ),
                  onFavoriteTap: () => _unfavorite(favorite.package.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
