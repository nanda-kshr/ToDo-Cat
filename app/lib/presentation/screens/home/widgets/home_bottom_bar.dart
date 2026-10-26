import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/app_outlined_icons.dart';

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
    final palette = AppColors.of(context);

    final glassBg = palette.bottomNavBg.withValues(alpha: isDark ? 0.88 : 0.92);
    final glassBorder = palette.cardBorder;
    final pillBg = palette.activeChip;
    final activeColor = palette.activeChipText;
    final inactiveColor = palette.textSecondary;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: palette.softShadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  color: glassBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: glassBorder, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    _NavItem(
                      index: 0,
                      label: 'Friends',
                      isSelected: currentTab == 0,
                      onSelected: onTabSelected,
                      activeIcon: AppSvgAssets.friendsActive,
                      inactiveIcon: AppSvgAssets.friendsInactive,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      pillBg: pillBg,
                    ),
                    _NavItem(
                      index: 1,
                      label: 'Home',
                      isSelected: currentTab == 1,
                      onSelected: onTabSelected,
                      activeIcon: AppSvgAssets.homeActive,
                      inactiveIcon: AppSvgAssets.homeInactive,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      pillBg: pillBg,
                    ),
                    _NavItem(
                      index: 2,
                      label: 'Profile',
                      isSelected: currentTab == 2,
                      onSelected: onTabSelected,
                      activeIcon: AppSvgAssets.profileActive,
                      inactiveIcon: AppSvgAssets.profileInactive,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      pillBg: pillBg,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final String label;
  final bool isSelected;
  final ValueChanged<int> onSelected;
  final String activeIcon;
  final String inactiveIcon;
  final Color activeColor;
  final Color inactiveColor;
  final Color pillBg;

  const _NavItem({
    required this.index,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.activeColor,
    required this.inactiveColor,
    required this.pillBg,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;
    final svgAsset = isSelected ? activeIcon : inactiveIcon;

    return Expanded(
      child: InkWell(
        onTap: () => onSelected(index),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? pillBg : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                svgAsset,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
