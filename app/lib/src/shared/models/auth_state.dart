class AuthStateSnapshot {
  const AuthStateSnapshot({
    required this.isAuthenticated,
    this.userId,
    this.email,
    this.isRemote = false,
  });

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final bool isRemote;

  factory AuthStateSnapshot.fromJson(Map<String, dynamic> json) {
    return AuthStateSnapshot(
      isAuthenticated: json['is_authenticated'] == true,
      userId: json['user_id']?.toString(),
      email: json['email']?.toString(),
      isRemote: json['is_remote'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_authenticated': isAuthenticated,
      'user_id': userId,
      'email': email,
      'is_remote': isRemote,
    };
  }
}
