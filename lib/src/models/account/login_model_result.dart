class LoginModelResult {
  String token;
  int id;
  String nickName;

  LoginModelResult(
      {required this.id, required this.nickName, required this.token});

  factory LoginModelResult.fromMap(Map<String, dynamic> map) {
    return LoginModelResult(
        id: map['id'], nickName: map['nickName'], token: map['token']);
  }
}
