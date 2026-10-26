import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HomeSearchFilterBar extends StatelessWidget {
  final String currentFilter;
  final int totalCount;
  final int activeCount;
  final int completedCount;
  final ValueChanged<String> onFilterChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const HomeSearchFilterBar({
    super.key,
    required this.currentFilter,
    required this.totalCount,
    required this.activeCount,
    required this.completedCount,
    required this.onFilterChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final cardBorder = palette.cardBorder;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filter Tabs (All, Active, Completed Pills)
        Row(
          children: [
            _FilterTab(
              id: 'all',
              label: 'All',
              count: totalCount,
              isSelected: currentFilter == 'all',
              onSelected: onFilterChanged,
              palette: palette,
            ),
            const SizedBox(width: 8),
            _FilterTab(
              id: 'active',
              label: 'Active',
              count: activeCount,
              isSelected: currentFilter == 'active',
              onSelected: onFilterChanged,
              palette: palette,
            ),
            const SizedBox(width: 8),
            _FilterTab(
              id: 'completed',
              label: 'Completed',
              count: completedCount,
              isSelected: currentFilter == 'completed',
              onSelected: onFilterChanged,
              palette: palette,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Bar (Rounded Pill)
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: palette.searchBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: palette.softShadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    color: textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(
                      fontFamily: 'Sniglet',
                      color: textSecondary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (searchQuery.isNotEmpty)
                InkWell(
                  onTap: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                  child: Icon(Icons.close, size: 18, color: textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String id;
  final String label;
  final int count;
  final bool isSelected;
  final ValueChanged<String> onSelected;
  final AppPalette palette;

  const _FilterTab({
    required this.id,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onSelected,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = palette.activeChip;
    final activeText = palette.activeChipText;
    final inactiveBg = palette.chipBg;
    final inactiveText = palette.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => onSelected(id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeBg : palette.cardBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeText : inactiveText,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeText.withValues(alpha: 0.20)
                      : palette.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? activeText : inactiveText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
