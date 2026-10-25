class FriendUser {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final String friendshipStatus; // 'none', 'accepted', 'pending_sent', 'pending_received'
  final String? friendshipId;

  const FriendUser({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    this.friendshipStatus = 'none',
    this.friendshipId,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      avatar: json['avatar'],
      friendshipStatus: json['friendshipStatus'] ?? 'none',
      friendshipId: json['friendshipId']?.toString(),
    );
  }

  String get displayName => (name != null && name!.trim().isNotEmpty) ? name! : email.split('@').first;
}

class FriendItem {
  final String friendshipId;
  final FriendUser user;
  final DateTime? since;

  const FriendItem({
    required this.friendshipId,
    required this.user,
    this.since,
  });

  factory FriendItem.fromJson(Map<String, dynamic> json) {
    return FriendItem(
      friendshipId: json['friendshipId']?.toString() ?? '',
      user: FriendUser.fromJson(json['user'] ?? {}),
      since: json['since'] != null ? DateTime.tryParse(json['since']) : null,
    );
  }
}

class PendingFriendRequest {
  final String friendshipId;
  final FriendUser user;
  final DateTime? createdAt;

  const PendingFriendRequest({
    required this.friendshipId,
    required this.user,
    this.createdAt,
  });

  factory PendingFriendRequest.fromJson(Map<String, dynamic> json) {
    return PendingFriendRequest(
      friendshipId: json['friendshipId']?.toString() ?? '',
      user: FriendUser.fromJson(json['user'] ?? {}),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class FriendsData {
  final List<FriendItem> friends;
  final List<PendingFriendRequest> pendingIncoming;
  final List<PendingFriendRequest> pendingOutgoing;
  final int total;
  final bool hasMore;
  final int page;

  const FriendsData({
    required this.friends,
    required this.pendingIncoming,
    required this.pendingOutgoing,
    this.total = 0,
    this.hasMore = false,
    this.page = 1,
  });

  factory FriendsData.fromJson(Map<String, dynamic> json) {
    final friendsList = (json['friends'] as List? ?? [])
        .map((e) => FriendItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final incomingList = (json['pendingIncoming'] as List? ?? [])
        .map((e) => PendingFriendRequest.fromJson(e as Map<String, dynamic>))
        .toList();
    final outgoingList = (json['pendingOutgoing'] as List? ?? [])
        .map((e) => PendingFriendRequest.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;

    return FriendsData(
      friends: friendsList,
      pendingIncoming: incomingList,
      pendingOutgoing: outgoingList,
      total: pagination?['total'] ?? friendsList.length,
      hasMore: pagination?['hasMore'] ?? false,
      page: pagination?['page'] ?? 1,
    );
  }
}
