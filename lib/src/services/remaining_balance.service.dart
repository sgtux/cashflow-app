import 'package:cashflow_app/src/models/remaining-balance/remaining_balance_model.dart';
import 'package:cashflow_app/src/models/result_model.dart';
import 'package:flutter/material.dart';
import 'http.service.dart';

class RemainingBalanceService extends HttpService {
  RemainingBalanceService(BuildContext context) : super(context: context);

  /// Todos os meses, do mais recente para o mais antigo; o primeiro é a
  /// simulação do mês atual.
  Future<List<RemainingBalanceModel>> getAll() async {
    final result = await get('RemainingBalance');
    List<RemainingBalanceModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(RemainingBalanceModel.fromMap(e));
      }
    }
    return list;
  }

  /// Ajusta manualmente o valor de um mês.
  Future<ResultModel> update(RemainingBalanceModel model) async {
    return await put('RemainingBalance', model);
  }

  /// Refaz o cálculo do mês a partir do que está lançado.
  Future<ResultModel> recalculate(RemainingBalanceModel model) async {
    return await put('RemainingBalance/Recalculate', model);
  }
}
