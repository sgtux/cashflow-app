import 'package:cashflow_app/src/models/home/home_data_model.dart';
import 'package:cashflow_app/src/models/home/projection_model.dart';
import 'package:flutter/material.dart';
import 'http.service.dart';

class HomeService extends HttpService {
  HomeService(BuildContext context) : super(context: context);

  Future<List<ProjectionModel>> getProjection() async {
    final result = await get('Projection');
    List<ProjectionModel> list = [];
    if (result.errors.isEmpty && result.data.isNotEmpty) {
      List monthYearList = result.data as List<dynamic>;
      for (var item in monthYearList) {
        list.add(ProjectionModel.fromMap(item));
      }
    }
    return list;
  }

  Future<HomeDataModel> getHomeData() async {
    final now = DateTime.now();
    final result = await get('Home?month=${now.month}&year=${now.year}');
    return HomeDataModel.fromMap(result.data);    
  }
}
