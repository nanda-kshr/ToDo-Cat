class User {
  final String id;
  final String email;
  final String? name;
  final String? avatar;

  User({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
    };
  }
}
