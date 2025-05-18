class CurrentUser {
  static final CurrentUser _instance = CurrentUser._internal();

  String? email;
  String? role;
  String? userId;
  bool isLogin = false;

  factory CurrentUser() {
    return _instance;
  }

  CurrentUser._internal();

  void update({
    required String email,
    required String role,
    required String userId,
  }) {
    this.email = email;
    this.role = role;
    this.userId = userId;
    isLogin = true;
  }

  void logout() {
    email = null;
    role = null;
    userId = null;
    isLogin = false;
  }
}

