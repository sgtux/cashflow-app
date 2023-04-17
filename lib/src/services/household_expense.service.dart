import 'package:cashflow_app/src/models/household-expense/household_expense_model.dart';
import 'package:cashflow_app/src/models/result_model.dart';
import 'package:cashflow_app/src/models/type_model.dart';
import 'package:flutter/material.dart';
import 'http.service.dart';

class HouseholdExpenseService extends HttpService {
  HouseholdExpenseService(BuildContext context) : super(context: context);

  Future<List<TypeModel>> getTypes() async {
    final result = await get('HouseholdExpense/Types');
    List<TypeModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(TypeModel.fromMap(e));
      }
    }
    return list;
  }

  Future<List<HouseholdExpenseModel>> getSome(String month, String year) async {
    final result = await get('HouseholdExpense?month=$month&year=$year');
    List<HouseholdExpenseModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(HouseholdExpenseModel.fromMap(e));
      }
    }
    return list;
  }

  Future<ResultModel> save(HouseholdExpenseModel householdExpense) async {
    if (householdExpense.id > 0) {
      return await put('HouseholdExpense', householdExpense);
    } else {
      return await post('HouseholdExpense', householdExpense);
    }
  }

  Future<ResultModel> remove(int id) async {
    return await delete('HouseholdExpense/$id');
  }
}
