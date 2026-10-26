import 'package:flutter/material.dart';

class HomeBottomBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabSelected;

  const HomeBottomBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF242424) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    return Container(
      height: 62 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          top: BorderSide(color: cardBorder),
        ),
      ),
      child: Row(
        children: [
          _NavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: currentTab == 0,
            onSelected: onTabSelected,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _NavItem(
            index: 1,
            icon: Icons.person_rounded,
            label: 'Profile',
            isSelected: currentTab == 1,
            onSelected: onTabSelected,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _NavItem(
            index: 2,
            icon: Icons.people_alt_rounded,
            label: 'Friends',
            isSelected: currentTab == 2,
            onSelected: onTabSelected,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final ValueChanged<int> onSelected;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? Colors.white : const Color(0xFF4B5563);
    return Expanded(
      child: InkWell(
        onTap: () => onSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
