import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/friend.dart';

Future<List<FriendUser>?> showFriendPickerSheet({
  required BuildContext context,
  required List<FriendItem> availableFriends,
  required List<FriendUser> initialSelected,
  String title = 'Share with Friends',
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

  return showModalBottomSheet<List<FriendUser>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: cardBg,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _FriendPickerSheet(
      availableFriends: availableFriends,
      initialSelected: initialSelected,
      title: title,
    ),
  );
}

class _FriendPickerSheet extends StatefulWidget {
  final List<FriendItem> availableFriends;
  final List<FriendUser> initialSelected;
  final String title;

  const _FriendPickerSheet({
    required this.availableFriends,
    required this.initialSelected,
    required this.title,
  });

  @override
  State<_FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<_FriendPickerSheet> {
  late final TextEditingController _searchController;
  late final List<FriendUser> _selected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selected = List<FriendUser>.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FriendItem> get _filteredFriends {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.availableFriends;
    }
    return widget.availableFriends.where((f) {
      final name = f.user.displayName.toLowerCase();
      final email = f.user.email.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  bool _isSelected(String friendId) {
    return _selected.any((u) => u.id == friendId);
  }

  void _toggleSelection(FriendUser user) {
    setState(() {
      if (_isSelected(user.id)) {
        _selected.removeWhere((u) => u.id == user.id);
      } else {
        _selected.add(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.of(context);
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;
    final inputBg = isDark ? const Color(0xFF282828) : const Color(0xFFF8EEDF);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.72;

    final filtered = _filteredFriends;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
        child: SizedBox(
          height: sheetHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: palette.activeChip,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.group_outlined,
                      size: 18,
                      color: palette.activeChipText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: 'Sniglet',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (_selected.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: palette.activeChip,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_selected.length}',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: palette.activeChipText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar
              RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.cardBorder, width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: TextStyle(
                            fontFamily: 'Sniglet',
                            color: textPrimary,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.availableFriends.isNotEmpty
                                ? 'Search ${widget.availableFriends.length} friends by name or email...'
                                : 'Search friends...',
                            hintStyle: TextStyle(
                              fontFamily: 'Sniglet',
                              color: textSecondary.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(Icons.clear_rounded, size: 16, color: textSecondary),
                        ),
                    ],
                  ),
                ),
              ),

              // Horizontal Selected Friends Chips Carousel
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _selected.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final user = _selected[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: palette.activeChip,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.displayName,
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: palette.activeChipText,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _toggleSelection(user),
                              child: Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: palette.activeChipText,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Friends List View
              Expanded(
                child: RepaintBoundary(
                  child: widget.availableFriends.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No friends added yet.\nYou can add friends from the Friends tab to share tasks and projects.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 13,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No friends found matching "$_searchQuery"',
                                style: TextStyle(
                                  fontFamily: 'Sniglet',
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              cacheExtent: 350,
                              separatorBuilder: (_, _) => Divider(
                                color: palette.cardBorder.withValues(alpha: 0.5),
                                height: 1,
                              ),
                              itemBuilder: (ctx, i) {
                                final friend = filtered[i];
                                final user = friend.user;
                                final selected = _isSelected(user.id);

                                return InkWell(
                                  onTap: () => _toggleSelection(user),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        // Friend Avatar / Initial with hardware-accelerated decode bounds
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: palette.activeChip.withValues(alpha: 0.12),
                                            border: Border.all(
                                              color: palette.cardBorder,
                                              width: 1,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: (user.avatar != null && user.avatar!.isNotEmpty)
                                              ? Image.network(
                                                  user.avatar!,
                                                  fit: BoxFit.cover,
                                                  cacheWidth: 80,
                                                  cacheHeight: 80,
                                                  errorBuilder: (_, _, _) => _buildInitial(user),
                                                )
                                              : _buildInitial(user),
                                        ),
                                        const SizedBox(width: 12),

                                        // Name and Email
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.displayName,
                                                style: TextStyle(
                                                  fontFamily: 'Sniglet',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                user.email,
                                                style: TextStyle(
                                                  fontFamily: 'Sniglet',
                                                  fontSize: 12,
                                                  color: textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Selection Checkmark Circle
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected ? palette.activeChip : Colors.transparent,
                                            border: Border.all(
                                              color: selected ? palette.activeChip : palette.cardBorder,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: selected
                                              ? Icon(
                                                  Icons.check_rounded,
                                                  size: 15,
                                                  color: palette.activeChipText,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),

              const SizedBox(height: 10),

              // Bottom Action Bar
              Row(
                children: [
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selected.clear()),
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          fontFamily: 'Sniglet',
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.fabBg,
                      foregroundColor: palette.fabIcon,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: Text(
                      _selected.isEmpty
                          ? 'Done'
                          : 'Done (${_selected.length})',
                      style: const TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitial(FriendUser user) {
    final initial = user.displayName.isNotEmpty
        ? user.displayName.substring(0, 1).toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Sniglet',
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.of(context).textPrimary,
        ),
      ),
    );
  }
}
