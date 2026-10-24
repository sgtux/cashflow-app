import 'package:cashflow_app/src/models/earning/earning_model.dart';
import 'package:cashflow_app/src/models/result_model.dart';
import 'package:cashflow_app/src/models/type_model.dart';
import 'package:flutter/material.dart';
import 'http.service.dart';

class EarningService extends HttpService {
  EarningService(BuildContext context) : super(context: context);

  Future<List<TypeModel>> getTypes() async {
    final result = await get('Earning/Types');
    List<TypeModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(TypeModel.fromMap(e));
      }
    }
    return list;
  }

  /// Ganhos a partir de [fromDate].
  Future<List<EarningModel>> getSome(DateTime fromDate) async {
    final from = Uri.encodeQueryComponent(fromDate.toIso8601String());
    final result = await get('Earning?fromDate=$from');
    List<EarningModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(EarningModel.fromMap(e));
      }
    }
    return list;
  }

  Future<ResultModel> save(EarningModel earning) async {
    if (earning.id > 0) {
      return await put('Earning', earning);
    } else {
      return await post('Earning', earning);
    }
  }

  Future<ResultModel> remove(int id) async {
    return await delete('Earning/$id');
  }
}
