import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';
import '../services/account.service.dart';
import '../services/storage.service.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final StorageService storageService = StorageService();

  late AccountService accountService;
  late String email = '';
  late String password = '';
  late bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    accountService = AccountService(context);

    return Scaffold(
        appBar: AppBar(
          title: const Text("CASHFLOW"),
        ),
        body: Center(
            child: Container(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                onChanged: (text) {
                  setState(() {
                    email = text;
                  });
                },
                decoration: const InputDecoration(
                    icon: Icon(Icons.person), hintText: 'Email'),
              ),
              TextField(
                onChanged: (text) {
                  setState(() {
                    password = text;
                  });
                },
                autocorrect: false,
                obscureText: true,
                enableSuggestions: false,
                decoration: const InputDecoration(
                    icon: Icon(Icons.lock), hintText: 'Senha'),
              ),
              const SizedBox(
                height: 20,
                width: 20,
              ),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                        });
                        accountService.login(email, password).then((res) {
                          setState(() => {isLoading = false});
                          if (res != null) {
                            storageService.setToken(res.token);
                            Navigator.pushNamedAndRemoveUntil(
                                context, Routes.home, (_) => false);
                          }
                        }).catchError((error) {
                          setState(() => {isLoading = false});
                          handleHttpException(error, context);
                        });
                      },
                      child: const Text("Entrar")),
            ],
          ),
        )));
  }
}
