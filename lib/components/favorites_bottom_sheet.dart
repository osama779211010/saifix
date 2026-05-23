import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../services/favorites_service.dart';
import 'recharge/add_favorite_dialog.dart';

class FavoritesBottomSheet extends StatefulWidget {
  final FavoriteType type;
  final bool isDarkMode;
  final Function(String id, String name, String? amount) onSelected;

  const FavoritesBottomSheet({
    super.key,
    required this.type,
    required this.isDarkMode,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required FavoriteType type,
    required bool isDarkMode,
    required Function(String id, String name, String? amount) onSelected,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FavoritesBottomSheet(
            type: type,
            isDarkMode: isDarkMode,
            onSelected: onSelected,
          ),
    );
  }

  @override
  State<FavoritesBottomSheet> createState() => _FavoritesBottomSheetState();
}

class _FavoritesBottomSheetState extends State<FavoritesBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<FavoriteItem> _allFavorites = [];
  List<FavoriteItem> _filteredFavorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final favs = await favoritesService.getFavoritesByType(widget.type);
    setState(() {
      _allFavorites = favs;
      _filteredFavorites = favs;
      _isLoading = false;
    });
  }

  void _filterFavorites(String query) {
    setState(() {
      _filteredFavorites =
          _allFavorites
              .where(
                (item) =>
                    item.name.toLowerCase().contains(query.toLowerCase()) ||
                    item.id.contains(query),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? AppColors.scaffoldDark : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : AppColors.textBlack;
    final cardColor =
        widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
            child: Row(
              children: [
                // Close Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.5)),
                ),
                
                // Title (Centered)
                Expanded(
                  child: Text(
                    'fav_select_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Add Button
                InkWell(
                  onTap: _showAddDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'fav_add_label'.tr(),
                          style: TextStyle(
                            color: AppColors.secondaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.add_circle_outline,
                          color: AppColors.secondaryBlue,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),



          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterFavorites,
                textAlign: TextAlign.start,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'search_favorites_hint'.tr(),
                  hintStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  suffixIcon: Icon(
                    Icons.search_rounded,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredFavorites.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
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

  void _showAddDialog() {
    AddFavoriteDialog.show(
      context,
      isDarkMode: widget.isDarkMode,
      initialType: widget.type,
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
        onTap: () {
          widget.onSelected(item.id, item.name, item.amount);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              // Right Side (appears on right in RTL)
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

              // Vertical Divider
              Container(
                height: 35,
                width: 1.2,
                color: Colors.grey.withValues(alpha: 0.3),
              ),

              const SizedBox(width: 15),

              // Left Side (appears on left in RTL)
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
