class User {
  final String id;
  final String username;
  final String? avatar;
  final String? category;
  final String? role;
  final String? info;
  final bool isOnline;
  final String? lastSeen;

  User({
    required this.id,
    required this.username,
    this.avatar,
    this.category,
    this.role,
    this.info,
    this.isOnline = false,
    this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'],
      category: json['category'] ?? 'Hetero',
      role: json['role'],
      info: json['info'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'category': category,
      'role': role,
      'info': info,
    };
  }
}
