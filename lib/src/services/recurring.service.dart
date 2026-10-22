import 'package:cashflow_app/src/models/recurring/recurring_model.dart';
import 'package:cashflow_app/src/models/result_model.dart';
import 'package:flutter/material.dart';
import 'http.service.dart';

/// Ganhos fixos (`RecurringEarning`) e contas fixas (`RecurringExpense`).
class RecurringService extends HttpService {
  RecurringService(BuildContext context, this.kind) : super(context: context);

  final RecurringKind kind;

  Future<List<RecurringModel>> getAll({bool showInactive = false}) async {
    final result = await get('${kind.resource}?active=${showInactive ? 0 : 1}');
    List<RecurringModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(RecurringModel.fromMap(kind, e));
      }
    }
    return list;
  }

  Future<RecurringModel?> getById(int id) async {
    final result = await get('${kind.resource}/$id');
    if (result.isValid() && result.data is Map) {
      return RecurringModel.fromMap(kind, result.data);
    }
    return null;
  }

  Future<ResultModel> save(RecurringModel item) async {
    if (item.id > 0) {
      return await put('${kind.resource}/${item.id}', item);
    } else {
      return await post(kind.resource, item);
    }
  }

  Future<ResultModel> remove(int id) async {
    return await delete('${kind.resource}/$id');
  }

  Future<ResultModel> saveHistory(RecurringHistoryModel history) async {
    if (history.id > 0) {
      return await put('${kind.resource}/History/${history.id}', history);
    } else {
      return await post('${kind.resource}/History', history);
    }
  }

  Future<ResultModel> removeHistory(RecurringHistoryModel history) async {
    return await delete(
        '${kind.resource}/${history.parentId}/History/${history.id}');
  }
}
