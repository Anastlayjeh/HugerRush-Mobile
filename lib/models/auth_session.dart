class AuthSession {
  const AuthSession({
    required this.token,
    required this.role,
    required this.restaurantName,
    this.refreshToken,
    this.user,
  });

  final String token;
  final String role;
  final String restaurantName;
  final String? refreshToken;
  final Map<String, dynamic>? user;

  AuthSession copyWith({
    String? token,
    String? role,
    String? restaurantName,
    String? refreshToken,
    bool clearRefreshToken = false,
    Map<String, dynamic>? user,
    bool keepExistingUser = true,
  }) {
    return AuthSession(
      token: token ?? this.token,
      role: role ?? this.role,
      restaurantName: restaurantName ?? this.restaurantName,
      refreshToken: clearRefreshToken
          ? null
          : (refreshToken ?? this.refreshToken),
      user: keepExistingUser ? (user ?? this.user) : user,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'role': role,
      'restaurant_name': restaurantName,
      'refresh_token': refreshToken,
      'user': user,
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: (json['token'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      restaurantName: (json['restaurant_name'] as String?) ?? 'Restaurant',
      refreshToken: json['refresh_token'] as String?,
      user: json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : null,
    );
  }
}
