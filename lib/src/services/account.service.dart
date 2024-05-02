import 'package:cashflow_app/src/models/account/login_model.dart';
import 'package:cashflow_app/src/models/account/login_model_result.dart';
import 'package:flutter/material.dart';

import 'http.service.dart';

class AccountService extends HttpService {
  AccountService(BuildContext context) : super(context: context);

  Future<LoginModelResult?> login(String email, String password) async {
    final result =
        await post('token', LoginModel(email: email, password: password));

    if (result.isValid()) return LoginModelResult.fromMap(result.data);

    return null;
  }

  Future<bool> validateToken() async {    
    await storage.init();
    try {
      await get('account');
    } catch (err) {
      storage.setToken('');
    }
    return true;
  }
}
