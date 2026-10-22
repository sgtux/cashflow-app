import 'package:cashflow_app/src/models/credit-card/credit_card_model.dart';
import 'package:flutter/material.dart';
import 'http.service.dart';

class CreditCardService extends HttpService {
  CreditCardService(BuildContext context) : super(context: context);

  Future<List<CreditCardModel>> getAll() async {
    final result = await get('CreditCard');
    List<CreditCardModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(CreditCardModel.fromMap(e));
      }
    }
    return list;
  }
}
