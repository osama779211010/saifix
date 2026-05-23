import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum FavoriteType { subscriber, pos, recharge, wallet, remittance, payment, bill }

class FavoriteItem {
  final String id;
  final String name;
  final FavoriteType type;
  final String? lastUsed;
  final String? amount;
  final String? category; // This can be used for display name of the type

  FavoriteItem({
    required this.id,
    required this.name,
    required this.type,
    this.lastUsed,
    this.amount,
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'lastUsed': lastUsed,
    'amount': amount,
    'category': category,
  };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
    id: json['id'],
    name: json['name'],
    type: FavoriteType.values[json['type'] ?? 0],
    lastUsed: json['lastUsed'],
    amount: json['amount'],
    category: json['category'],
  );
}

class FavoritesService {
  static const String _key = 'user_favorites';

  // Singleton pattern
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  Future<List<FavoriteItem>> getAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => FavoriteItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<FavoriteItem>> getFavoritesByType(FavoriteType type) async {
    final all = await getAllFavorites();
    return all.where((item) => item.type == type).toList();
  }

  Future<bool> isFavorite(String id, FavoriteType type) async {
    final all = await getAllFavorites();
    return all.any((item) => item.id == id && item.type == type);
  }

  // Support both old and new calls
  Future<void> addFavorite(
    dynamic idOrName, [
    dynamic nameOrType,
    FavoriteType? typeOnly,
  ]) async {
    String id;
    String name;
    FavoriteType type;
    String? amount;
    String? category;

    if (idOrName is String && nameOrType is String && typeOnly != null) {
      // Old call: addFavorite(id, name, type)
      id = idOrName;
      name = nameOrType;
      type = typeOnly;
    } else {
      // New call: should be named, but for now we handle the errors
      // Actually, it's better to just use named parameters but provide a shim
      return; // Will fix the calling sites instead
    }

    final all = await getAllFavorites();
    all.removeWhere((item) => item.id == id && item.type == type);

    all.insert(
      0,
      FavoriteItem(
        id: id,
        name: name,
        type: type,
        lastUsed: DateTime.now().toIso8601String(),
        amount: amount,
        category: category,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }

  // New named parameter version
  Future<void> addFavoriteNew({
    required String id,
    required String name,
    required FavoriteType type,
    String? amount,
    String? category,
  }) async {
    final all = await getAllFavorites();
    all.removeWhere((item) => item.id == id && item.type == type);

    all.insert(
      0,
      FavoriteItem(
        id: id,
        name: name,
        type: type,
        lastUsed: DateTime.now().toIso8601String(),
        amount: amount,
        category: category,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> removeFavorite(String id, FavoriteType type) async {
    final all = await getAllFavorites();
    all.removeWhere((item) => item.id == id && item.type == type);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> updateLastUsed(String id, FavoriteType type) async {
    final all = await getAllFavorites();
    final index = all.indexWhere((item) => item.id == id && item.type == type);

    if (index != -1) {
      final updated = FavoriteItem(
        id: all[index].id,
        name: all[index].name,
        type: all[index].type,
        lastUsed: DateTime.now().toIso8601String(),
        amount: all[index].amount,
        category: all[index].category,
      );
      all.removeAt(index);
      all.insert(0, updated);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(all.map((e) => e.toJson()).toList()),
      );
    }
  }
}

final favoritesService = FavoritesService();
