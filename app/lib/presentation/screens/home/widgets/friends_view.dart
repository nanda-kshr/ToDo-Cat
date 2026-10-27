import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/friend.dart';
import '../../../../services/api_service.dart';
import '../../../widgets/app_outlined_icons.dart';
import 'friend_stats_sheet.dart';
import '../../../widgets/app_toast.dart';

class FriendsView extends StatefulWidget {
  final VoidCallback? onFriendsUpdated;

  const FriendsView({super.key, this.onFriendsUpdated});

  @override
  State<FriendsView> createState() => FriendsViewState();
}

class FriendsViewState extends State<FriendsView> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<FriendItem> _friends = [];
  List<PendingFriendRequest> _pendingRequests = [];
  int _totalFriends = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFriends(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 150) {
      if (!_loadingMore && _hasMore) {
        _loadMoreFriends();
      }
    }
  }

  void reload() {
    _loadFriends(reset: true);
  }

  Future<void> _loadFriends({bool reset = true}) async {
    try {
      if (reset) {
        setState(() {
          _page = 1;
          _loading = true;
          _error = null;
        });
      }

      final query = _searchController.text.trim();
      final data = await _apiService.fetchFriends(
        page: 1,
        limit: 10,
        search: query.isNotEmpty ? query : null,
      );

      if (mounted) {
        setState(() {
          _friends = data.friends;
          _pendingRequests = data.pendingIncoming;
          _totalFriends = data.total;
          _hasMore = data.hasMore;
          _page = 1;
          _loading = false;
        });
        widget.onFriendsUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : 'Unable to load friends. Please check your connection.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMoreFriends() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final nextPage = _page + 1;
      final query = _searchController.text.trim();
      final data = await _apiService.fetchFriends(
        page: nextPage,
        limit: 10,
        search: query.isNotEmpty ? query : null,
      );

      if (mounted) {
        setState(() {
          _page = nextPage;
          _friends.addAll(data.friends);
          _hasMore = data.hasMore;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _loadFriends(reset: true);
    });
  }

  void openAddFriendDialog() async {
    final sentEmail = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddFriendBottomSheet(
        onFriendAdded: () {
          _loadFriends(reset: true);
        },
      ),
    );

    if (sentEmail != null && mounted) {
      AppToast.show(context, 'Friend request sent');
    }
  }

  Future<void> _respondRequest(String friendshipId, String action, String name) async {
    final prevPending = List<PendingFriendRequest>.from(_pendingRequests);
    final prevFriends = List<FriendItem>.from(_friends);
    final prevTotal = _totalFriends;

    final reqIndex = _pendingRequests.indexWhere((r) => r.friendshipId == friendshipId);
    final requestItem = reqIndex != -1 ? _pendingRequests[reqIndex] : null;

    // Instant UI update
    setState(() {
      _pendingRequests.removeWhere((r) => r.friendshipId == friendshipId);
      if (action == 'accept' && requestItem != null) {
        _friends.insert(
          0,
          FriendItem(
            friendshipId: friendshipId,
            user: requestItem.user,
            since: DateTime.now(),
          ),
        );
        _totalFriends += 1;
      }
    });
    widget.onFriendsUpdated?.call();
    AppToast.show(context, action == 'accept' ? 'Added friend' : 'Request declined');

    try {
      await _apiService.respondFriendRequest(friendshipId, action);
    } catch (_) {
      // Revert if API fails
      if (mounted) {
        setState(() {
          _pendingRequests = prevPending;
          _friends = prevFriends;
          _totalFriends = prevTotal;
        });
        widget.onFriendsUpdated?.call();
        AppToast.show(context, 'Failed to update request', isError: true);
      }
    }
  }

  Future<void> _removeFriend(FriendItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Friend', style: TextStyle(fontFamily: 'Sniglet')),
        content: Text(
          'Are you sure you want to remove ${item.user.displayName} from your friends?',
          style: const TextStyle(fontFamily: 'Sniglet'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Sniglet')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(fontFamily: 'Sniglet', color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final prevFriends = List<FriendItem>.from(_friends);
      final prevTotal = _totalFriends;

      // Instant UI update
      setState(() {
        _friends.removeWhere((f) => f.friendshipId == item.friendshipId);
        _totalFriends = (_totalFriends > 0) ? _totalFriends - 1 : 0;
      });
      widget.onFriendsUpdated?.call();
      AppToast.show(context, 'Friend removed');

      try {
        await _apiService.removeFriend(item.friendshipId);
      } catch (_) {
        if (mounted) {
          setState(() {
            _friends = prevFriends;
            _totalFriends = prevTotal;
          });
          widget.onFriendsUpdated?.call();
          AppToast.show(context, 'Failed to remove friend', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF374151);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final inputBg = isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6);

    return RefreshIndicator(
      onRefresh: () => _loadFriends(reset: true),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECTION 1: Pending Friend Requests Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 25 : 8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mark_email_unread_outlined, size: 20, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Text(
                        'Pending Requests',
                        style: TextStyle(
                          fontFamily: 'Sniglet',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_pendingRequests.length}',
                          style: const TextStyle(
                            fontFamily: 'Sniglet',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_pendingRequests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          'No pending friend requests.',
                          style: TextStyle(
                            fontFamily: 'Sniglet',
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._pendingRequests.map(
                      (req) => _buildIncomingRequestTile(req, isDark, textPrimary, textSecondary),
                    ),
                ],
              ),
            ),

            // SECTION 2: Existing Friends Card with Search & Lazy Loading
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 25 : 8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Friends',
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_totalFriends',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _loadFriends(reset: true),
                        icon: Icon(Icons.refresh_rounded, size: 20, color: textSecondary),
                        tooltip: 'Refresh',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 1) Search friends by email (searches existing friends)
                  Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 18, color: textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              color: textPrimary,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search friends by email...',
                              hintStyle: TextStyle(
                                fontFamily: 'Sniglet',
                                color: textSecondary,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _loadFriends(reset: true);
                            },
                            child: Icon(Icons.close, size: 16, color: textSecondary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Friends list or Loading/Empty state
                  if (_loading && _friends.isEmpty) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (_error != null && _friends.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 32, color: Colors.red.shade300),
                          const SizedBox(height: 6),
                          Text(
                            _error!,
                            style: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _loadFriends(reset: true),
                            child: const Text('Try Again', style: TextStyle(fontFamily: 'Sniglet', fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_friends.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.pets, size: 26, color: textSecondary),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No friends match your search.'
                                  : 'No friends yet!',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Try searching with a different email.'
                                  : 'Tap the + button below to add a friend by email.',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    ..._friends.map(
                      (item) => _buildFriendCard(item, isDark, textPrimary, textSecondary),
                    ),
                    if (_loadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (_hasMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: TextButton(
                            onPressed: _loadMoreFriends,
                            child: Text(
                              'Load more friends',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 110), // Space for FAB & Bottom Bar
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequestTile(
    PendingFriendRequest req,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
            backgroundImage: req.user.avatar != null && req.user.avatar!.isNotEmpty
                ? NetworkImage(req.user.avatar!)
                : null,
            child: req.user.avatar == null || req.user.avatar!.isEmpty
                ? Text(
                    req.user.displayName.isNotEmpty ? req.user.displayName[0].toUpperCase() : '?',
                    style: TextStyle(fontFamily: 'Sniglet', fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.user.displayName,
                  style: TextStyle(fontFamily: 'Sniglet', fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  req.user.email,
                  style: TextStyle(fontFamily: 'Sniglet', fontSize: 11, color: textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Accept (Handwritten Tick) Button
          Tooltip(
            message: 'Accept',
            child: InkWell(
              onTap: () => _respondRequest(req.friendshipId, 'accept', req.user.displayName),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242424) : const Color(0xFFEFEBE2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF404040) : const Color(0xFFDDD7CB),
                  ),
                ),
                alignment: Alignment.center,
                child: AppOutlinedIcon(
                  svgString: AppOutlinedSvgStrings.handwrittenTick,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF292524),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Decline (Handwritten Cross) Button
          Tooltip(
            message: 'Decline',
            child: InkWell(
              onTap: () => _respondRequest(req.friendshipId, 'decline', req.user.displayName),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DC),
                  ),
                ),
                alignment: Alignment.center,
                child: AppOutlinedIcon(
                  svgString: AppOutlinedSvgStrings.handwrittenCross,
                  size: 16,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF78716C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(
    FriendItem item,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final palette = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFF3F4F6),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (item.user.isProfilePublic) {
            showFriendStatsSheet(context, friend: item.user);
          } else {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                title: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 22, color: Color(0xFFA1A1AA)),
                    const SizedBox(width: 8),
                    Text(
                      'Private Stats',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 18,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  '${item.user.displayName} has kept their stats private.',
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK', style: TextStyle(fontFamily: 'Sniglet')),
                  ),
                ],
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                backgroundImage: item.user.avatar != null && item.user.avatar!.isNotEmpty
                    ? NetworkImage(item.user.avatar!)
                    : null,
                child: item.user.avatar == null || item.user.avatar!.isEmpty
                    ? Text(
                        item.user.displayName.isNotEmpty ? item.user.displayName[0].toUpperCase() : '?',
                        style: TextStyle(fontFamily: 'Sniglet', fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.user.displayName,
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (item.user.isProfilePublic)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: palette.subtleGreenBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: palette.subtleGreenBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bar_chart_rounded, size: 10, color: palette.subtleGreen),
                                const SizedBox(width: 2),
                                Text(
                                  'Stats',
                                  style: TextStyle(
                                    fontFamily: 'Sniglet',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: palette.subtleGreen,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Icon(Icons.lock_outline, size: 12, color: textSecondary.withValues(alpha: 0.6)),
                      ],
                    ),
                    Text(
                      item.user.email,
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: isDark ? const Color(0xFF262626) : Colors.white,
                onSelected: (val) {
                  if (val == 'remove') {
                    _removeFriend(item);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_outlined, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Remove Friend',
                          style: TextStyle(fontFamily: 'Sniglet', color: Colors.red, fontSize: 13),
                        ),
                      ],
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
}

class _AddFriendBottomSheet extends StatefulWidget {
  final VoidCallback? onFriendAdded;

  const _AddFriendBottomSheet({this.onFriendAdded});

  @override
  State<_AddFriendBottomSheet> createState() => _AddFriendBottomSheetState();
}

class _AddFriendBottomSheetState extends State<_AddFriendBottomSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<FriendUser> _results = [];
  bool _searching = false;
  Timer? _debounce;
  String? _feedback;
  bool _isError = false;
  String? _sendingEmail;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    final query = val.trim();
    final isCompleteEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(query);

    if (!isCompleteEmail) {
      setState(() {
        _results = [];
        _searching = false;
        _feedback = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _searching = true);
      try {
        final users = await _apiService.searchFriends(query);
        if (mounted) {
          setState(() {
            _results = users;
            _searching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _sendRequest(String email) async {
    if (_sendingEmail != null) return;
    setState(() {
      _sendingEmail = email;
      _feedback = null;
      _isError = false;
    });

    try {
      await _apiService.sendFriendRequest(email);
      if (mounted) {
        widget.onFriendAdded?.call();
        Navigator.of(context).pop(email);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sendingEmail = null;
          _feedback = e is ApiException
              ? e.message
              : 'Unable to send friend request. Please check your connection.';
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF374151);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final inputBg = isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6);

    return Container(
      padding: EdgeInsets.only(
        top: 18,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add New Friend',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: textSecondary),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_feedback != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _isError
                    ? Colors.red.withAlpha(20)
                    : (isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isError ? Colors.red.withAlpha(80) : cardBorder,
                ),
              ),
              child: Row(
                children: [
                  if (_isError)
                    const Text('⚠️ ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      _feedback!,
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isError ? Colors.red : textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 20, color: textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    autofocus: true,
                    style: TextStyle(
                      fontFamily: 'Sniglet',
                      color: textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter registered user email...',
                      hintStyle: TextStyle(
                        fontFamily: 'Sniglet',
                        color: textSecondary,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (context, index) => Divider(color: cardBorder, height: 1),
                itemBuilder: (ctx, idx) {
                  final u = _results[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                          backgroundImage: u.avatar != null && u.avatar!.isNotEmpty
                              ? NetworkImage(u.avatar!)
                              : null,
                          child: u.avatar == null || u.avatar!.isEmpty
                              ? Text(
                                  u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : '?',
                                  style: TextStyle(fontFamily: 'Sniglet', fontWeight: FontWeight.bold, color: textPrimary),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.displayName,
                                style: TextStyle(
                                  fontFamily: 'Sniglet',
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                u.email,
                                style: TextStyle(fontFamily: 'Sniglet', fontSize: 11, color: textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (u.friendshipStatus == 'accepted')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Friends',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          )
                        else if (u.friendshipStatus == 'pending_sent')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Sent',
                              style: TextStyle(fontFamily: 'Sniglet', fontSize: 11, color: textSecondary),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: _sendingEmail != null ? null : () => _sendRequest(u.email),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              backgroundColor: isDark ? Colors.white : const Color(0xFF374151),
                            ),
                            child: _sendingEmail == u.email
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark ? Colors.black : Colors.white,
                                    ),
                                  )
                                : Text(
                                    '+ Add',
                                    style: TextStyle(
                                      fontFamily: 'Sniglet',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.black : Colors.white,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}