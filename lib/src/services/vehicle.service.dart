import 'package:cashflow_app/src/models/vehicle/vehicle.model.dart';
import 'package:flutter/material.dart';
import 'http.service.dart';

class VehicleService extends HttpService {
  VehicleService(BuildContext context) : super(context: context);

  Future<List<VehicleModel>> getAll() async {
    final result = await get('Vehicle');
    List<VehicleModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      for (var e in (result.data as List)) {
        list.add(VehicleModel.fromMap(e));
      }
    }
    return list;
  }

  Future save(VehicleModel vehicle) async {
    if (vehicle.id > 0) {
      await put('Vehicle', vehicle);
    } else {
      await post('Vehicle', vehicle);
    }
  }

  Future remove(int id) async {
    await delete('Vehicle/$id');
  }
}
