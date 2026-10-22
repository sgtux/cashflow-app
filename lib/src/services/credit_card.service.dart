import 'package:cashflow_app/src/models/credit-card/credit_card_model.dart';
import 'package:cashflow_app/src/models/model_base.dart';
import 'package:cashflow_app/src/models/result_model.dart';
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

  Future<ResultModel> save(CreditCardModel card) async {
    if (card.id > 0) {
      return await put('CreditCard', card);
    } else {
      return await post('CreditCard', card);
    }
  }

  Future<ResultModel> remove(int id) async {
    return await delete('CreditCard/$id');
  }

  /// Registra o pagamento de um item da fatura do mês atual.
  Future<ResultModel> payInvoiceItem(
      CreditCardModel card, CreditCardItemModel item, double paidValue) async {
    return await put(
        'CreditCard/PayCurrentInvoicePayment',
        MapModel({
          'itemId': item.id,
          'type': item.type,
          'creditCardId': card.id,
          'paidValue': paidValue
        }));
  }
}
