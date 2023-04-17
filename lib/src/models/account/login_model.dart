import 'package:cashflow_app/src/models/model_base.dart';

class LoginModel extends ModelBase {
  final String email;
  final String password;

  LoginModel({required this.email, required this.password});

  @override
  Map<String, dynamic> toMap() {
    return {'email': email, 'password': password};
  }
}
