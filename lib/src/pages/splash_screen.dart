import 'package:cashflow_app/src/services/account.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AccountService accountService = AccountService(context);
    WidgetsBinding.instance?.addPostFrameCallback((_) => {
          accountService.validateToken().then((value) {
            final token = accountService.storage.getToken();
            if (token == null) {
              Navigator.pushNamedAndRemoveUntil(
                  context, Routes.login, (route) => false);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                  context, Routes.home, (route) => false);
            }
          })
        });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Carregando...",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(
              height: 20,
            ),
            const CircularProgressIndicator()
          ],
        ),
      ),
    );
  }
}
