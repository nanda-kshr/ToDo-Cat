import 'friend.dart';

class CategoryItem {
  final String id;
  final String name;
  final String? userId;
  final List<FriendUser> sharedWith;
  final bool isDefault;

  const CategoryItem({
    required this.id,
    required this.name,
    this.userId,
    this.sharedWith = const [],
    this.isDefault = false,
  });

  bool get isShared => sharedWith.isNotEmpty;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final rawShared = json['sharedWith'];
    List<FriendUser> shared = [];
    if (rawShared is List) {
      shared = rawShared.map((u) {
        if (u is Map<String, dynamic>) {
          return FriendUser.fromJson(u);
        } else if (u is FriendUser) {
          return u;
        }
        return null;
      }).whereType<FriendUser>().toList();
    }
    return CategoryItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: (json['name'] as String? ?? 'General').trim(),
      userId: json['userId'] is Map
          ? json['userId']['_id']?.toString()
          : json['userId']?.toString(),
      sharedWith: shared,
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'userId': userId,
    'sharedWith': sharedWith
        .map((u) => {
              'id': u.id,
              'email': u.email,
              'name': u.name,
              'avatar': u.avatar,
            })
        .toList(),
    'isDefault': isDefault,
  };
}
