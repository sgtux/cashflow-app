class LoginModelResult {
  String token;
  int id;
  String email;

  LoginModelResult(
      {required this.id, required this.email, required this.token});

  factory LoginModelResult.fromMap(Map<String, dynamic> map) {
    return LoginModelResult(
        id: map['id'], email: map['email'], token: map['token']);
  }
}
