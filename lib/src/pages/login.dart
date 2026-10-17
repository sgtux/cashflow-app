import 'dart:math';

import 'package:cashflow_app/src/utils/app_settings.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
          title: const Text("Cashflow"),
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
                        setState(() => isLoading = true);
                        accountService.login(email, password).then((res) {
                          setState(() => isLoading = false);
                          if (res != null) {
                            storageService.setToken(res.token);
                            Navigator.pushNamedAndRemoveUntil(
                                context, Routes.home, (_) => false);
                          }
                        }).catchError((error) {
                          setState(() => isLoading = false);
                          handleHttpException(error, context);
                        });
                      },
                      child: const Text("Entrar")),
              const SizedBox(
                height: 20,
              ),
              const Divider(height: sqrt1_2),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton.icon(
                label: const Text('Entrar com Google'),
                icon: FaIcon(FontAwesomeIcons.google),
                onPressed: () {
                  setState(() => isLoading = true);
                  accountService.googleLogin().then((res) {
                    setState(() => isLoading = false);
                    if (res != null) {
                      storageService.setToken(res.token);
                      Navigator.pushNamedAndRemoveUntil(
                          context, Routes.home, (_) => false);
                    }
                  }).catchError((error, stackTrace) {
                    setState(() => isLoading = false);
                    if (error is GoogleSignInException) {
                      handleGoogleSignInException(error, stackTrace, context);
                    } else {
                      debugPrint('[GoogleLogin] Erro: $error\n$stackTrace');
                      handleHttpException(error, context);
                    }
                  });
                },
              ),
              const SizedBox(
                height: 20,
              ),
              TextButton.icon(
                onPressed: () {
                  AppSettings.setLoginVersion(2);
                  Navigator.pushReplacementNamed(context, Routes.login);
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Experimentar o novo login'),
              )
            ],
          ),
        )));
  }
}
