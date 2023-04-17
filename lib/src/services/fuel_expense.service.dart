import 'package:cashflow_app/src/models/result_model.dart';
import 'package:cashflow_app/src/models/vehicle/fuel_expense.model.dart';
import 'package:flutter/material.dart';
import 'http.service.dart';

class FuelExpenseService extends HttpService {
  FuelExpenseService(BuildContext context) : super(context: context);

  Future<ResultModel> save(FuelExpenseModel fuelExpense) async {
    if (fuelExpense.id > 0) {
      return await put('FuelExpense/${fuelExpense.id}', fuelExpense);
    } else {
      return await post('FuelExpense', fuelExpense);
    }
  }

  Future<ResultModel> remove(int id) async {
    return await delete('FuelExpense/$id');
  }
}
