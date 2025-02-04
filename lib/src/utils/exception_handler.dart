import 'package:cashflow_app/src/services/storage.service.dart';
import 'package:flutter/material.dart';

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
