import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../services/favorites_service.dart';
import '../components/recharge/add_favorite_dialog.dart';

class FavoritesScreen extends StatefulWidget {
  final bool isDarkMode;
  const FavoritesScreen({super.key, required this.isDarkMode});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FavoriteItem> _allFavorites = [];
  List<FavoriteItem> _filteredFavorites = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  bool _isSearchVisible = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'fav_all'.tr(), 'icon': Icons.grid_view_rounded},
    {'id': 'recharge', 'label': 'fav_recharge'.tr(), 'icon': Icons.bolt_rounded, 'type': FavoriteType.recharge},
    {'id': 'wallet', 'label': 'fav_wallet'.tr(), 'icon': Icons.account_balance_wallet_rounded, 'type': FavoriteType.wallet},
    {'id': 'remittance', 'label': 'fav_remittance'.tr(), 'icon': Icons.send_rounded, 'type': FavoriteType.remittance},
    {'id': 'payment', 'label': 'fav_payment'.tr(), 'icon': Icons.shopping_bag_rounded, 'type': FavoriteType.payment},
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final favs = await favoritesService.getAllFavorites();
    setState(() {
      _allFavorites = favs;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredFavorites = _allFavorites.where((item) {
        final matchesCategory = _selectedCategory == 'all' || 
            item.type == _categories.firstWhere((c) => c['id'] == _selectedCategory)['type'];
        
        final query = _searchController.text.toLowerCase();
        final matchesSearch = item.name.toLowerCase().contains(query) || 
                             item.id.contains(query);
        
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? AppColors.scaffoldDark : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : AppColors.textBlack;
    final cardColor = widget.isDarkMode ? AppColors.cardDark : Colors.grey.shade50;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearchVisible 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'search_favorites_hint'.tr(),
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
                border: InputBorder.none,
              ),
              onChanged: (_) => _applyFilters(),
            )
          : Text(
              'favorites_title'.tr(),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search_rounded, color: textColor),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _applyFilters();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: textColor),
            onPressed: () => _showAddDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat['id'];
                        _applyFilters();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.secondaryBlue : cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.secondaryBlue : textColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat['icon'],
                            size: 18,
                            color: isSelected ? Colors.white : textColor.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat['label'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor.withValues(alpha: 0.7),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFavorites.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: _filteredFavorites.length,
                        itemBuilder: (context, index) {
                          final item = _filteredFavorites[index];
                          return _buildFavoriteItem(item, index, cardColor, textColor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog({FavoriteItem? item}) {
    AddFavoriteDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      initialType: item?.type,
      editItem: item, // Passing the item for edit mode
      onAdded: () {
        _loadFavorites();
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.favorite_border_rounded,
          size: 80,
          color: AppColors.secondaryBlue.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 20),
        Text(
          'fav_no_found'.tr(),
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'fav_add_hint'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white54 : Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    ).animate().fade();
  }

  Widget _buildFavoriteItem(
    FavoriteItem item,
    int index,
    Color cardColor,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAddDialog(item: item),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: textColor.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.id,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Container(
                height: 35,
                width: 1.2,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.category ?? 'fav_wallet'.tr(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.amount ?? '0',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }
}
