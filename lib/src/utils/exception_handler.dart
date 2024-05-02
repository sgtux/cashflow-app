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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Erro inesperado ocorreu."),
      backgroundColor: Colors.red,
    ));
  }
}
