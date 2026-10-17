import 'package:cashflow_app/src/services/storage.service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'constants.dart';

void handleHttpException(dynamic error, BuildContext context) {
  if (error is Map) {
    if (error.containsKey('code') && error['code'] == 401) {
      final storage = StorageService();
      storage.setToken('');
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
    }
  } else {
    String errorMessage;
    
    if(error is Exception){
      errorMessage = "Erro inesperado: $error";
    }else{
      errorMessage = "Erro inesperado ocorreu.";
      print(error);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errorMessage),
      backgroundColor: Colors.red,
    ));
  }
}

void handleGoogleSignInException(
    GoogleSignInException error, StackTrace stackTrace, BuildContext context) {
  final code = error.code.toString().split('.').last;
  debugPrint('[GoogleLogin] Falha no login com Google\n'
      '  código:    $code\n'
      '  descrição: ${error.description}\n'
      '  detalhes:  ${error.details}\n'
      '$stackTrace');

  // O usuário fechou a tela de login: não é erro, não exibe nada.
  if (error.code == GoogleSignInExceptionCode.canceled &&
      !(error.description ?? '').contains('reauth')) {
    return;
  }

  String message;
  switch (error.code) {
    case GoogleSignInExceptionCode.canceled:
      message = 'Não foi possível autenticar com o Google. '
          'Verifique se o SHA-1 do app está cadastrado no Firebase.';
      break;
    case GoogleSignInExceptionCode.clientConfigurationError:
    case GoogleSignInExceptionCode.providerConfigurationError:
      message = 'Login com Google mal configurado neste app.';
      break;
    case GoogleSignInExceptionCode.uiUnavailable:
      message = 'Não foi possível abrir a tela de login do Google.';
      break;
    case GoogleSignInExceptionCode.interrupted:
      message = 'Login com Google interrompido. Tente novamente.';
      break;
    default:
      message = 'Erro no login com Google.';
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('$message\n($code: ${error.description})'),
    backgroundColor: Colors.red,
  ));
}
