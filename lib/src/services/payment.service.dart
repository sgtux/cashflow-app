import 'package:cashflow_app/src/models/payment/payment_model.dart';
import 'package:cashflow_app/src/models/result_model.dart';
import 'package:cashflow_app/src/models/type_model.dart';
import 'package:flutter/material.dart';
import 'http.service.dart';

/// Filtro da lista de parcelamentos. `done` nulo traz todos.
class PaymentFilter {
  final String description;
  final bool? done;
  final DateTime? startDate;
  final DateTime? endDate;

  const PaymentFilter(
      {this.description = '', this.done = false, this.startDate, this.endDate});

  String toQuery() {
    final params = <String, String>{
      if (description.trim().isNotEmpty) 'description': description.trim(),
      if (done != null) 'done': done.toString(),
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
    return Uri(queryParameters: params).query;
  }
}

class PaymentService extends HttpService {
  PaymentService(BuildContext context) : super(context: context);

  Future<List<PaymentModel>> getSome(PaymentFilter filter) async {
    final result = await get('Payment?${filter.toQuery()}');
    List<PaymentModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(PaymentModel.fromMap(e));
      }
    }
    return list;
  }

  Future<PaymentModel?> getById(int id) async {
    final result = await get('Payment/$id');
    if (result.isValid() && result.data is Map) {
      return PaymentModel.fromMap(result.data);
    }
    return null;
  }

  Future<List<TypeModel>> getTypes() async {
    final result = await get('Payment/Types');
    List<TypeModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(TypeModel.fromMap(e));
      }
    }
    return list;
  }

  /// Pré-visualização das parcelas: divide o total e, no cartão, ajusta o
  /// primeiro vencimento conforme o fechamento da fatura.
  Future<List<InstallmentModel>> generateInstallments(
      {required double value,
      required int amount,
      required DateTime date,
      int? creditCardId}) async {
    final query = Uri(queryParameters: {
      'value': value.toString(),
      'amount': amount.toString(),
      'date': date.toIso8601String(),
      if ((creditCardId ?? 0) > 0) 'creditCardId': creditCardId.toString(),
    }).query;
    final result = await get('Payment/GenerateInstallments?$query');
    List<InstallmentModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(InstallmentModel.fromMap(e));
      }
    }
    return list;
  }

  Future<ResultModel> save(PaymentModel payment) async {
    if (payment.id > 0) {
      return await put('Payment', payment);
    } else {
      return await post('Payment', payment);
    }
  }

  Future<ResultModel> remove(int id) async {
    return await delete('Payment/$id');
  }
}
