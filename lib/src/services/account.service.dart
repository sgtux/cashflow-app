import 'package:cashflow_app/src/models/account/account_model.dart';
import 'package:cashflow_app/src/models/account/google_login_model.dart';
import 'package:cashflow_app/src/models/account/login_model.dart';
import 'package:cashflow_app/src/models/account/login_model_result.dart';
import 'package:cashflow_app/src/models/result_model.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'http.service.dart';

class AccountService extends HttpService {
  AccountService(BuildContext context) : super(context: context);

  Future<LoginModelResult?> login(String email, String password) async {
    final result =
        await post('token', LoginModel(email: email, password: password));

    if (result.isValid()) return LoginModelResult.fromMap(result.data);

    return null;
  }

  Future<LoginModelResult?> googleLogin() async {
    await GoogleSignIn.instance.initialize();

    if (GoogleSignIn.instance.supportsAuthenticate()) {
      final googleAuth =
          await GoogleSignIn.instance.authenticate(scopeHint: ['email']);

      String idToken = googleAuth.authentication.idToken ?? '';
      if (idToken != '') {
        final result = await post(
            'account/GoogleSignIn', GoogleLoginModel(idToken: idToken));
        return LoginModelResult.fromMap(result.data);
      }
    }

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

  Future<AccountModel?> getAccount() async {
    final result = await get('Account');
    if (result.isValid() && result.data is Map) {
      return AccountModel.fromMap(result.data);
    }
    return null;
  }

  /// Salva os limites mensais de despesas e combustível.
  Future<ResultModel> updateLimits(AccountModel account) async {
    return await put('Account', account);
  }
}
