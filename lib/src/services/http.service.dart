import 'dart:convert';
import 'package:cashflow_app/src/models/model_base.dart';
import 'package:cashflow_app/src/services/storage.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../models/result_model.dart';

class HttpService {
  final BuildContext context;
  final StorageService storage = StorageService();

  HttpService({required this.context});

  Future<ResultModel> get(String url) async {
    final response =
        await http.get(Uri.parse("$urlApi/$url"), headers: getHeaders());
    return handleReponse(response, url);
  }

  Future<ResultModel> post(String url, ModelBase body) async {
    final response = await http.post(Uri.parse("$urlApi/$url"),
        headers: getHeaders(), body: json.encode(body.toMap()));

    return handleReponse(response, url);
  }

  Future<ResultModel> postString(String url, String body) async {
    final response = await http.post(Uri.parse("$urlApi/$url"),
        headers: getHeaders(), body: body);

    return handleReponse(response, url);
  }

  Future<ResultModel> put(String url, ModelBase model) async {
    final response = await http.put(Uri.parse("$urlApi/$url"),
        headers: getHeaders(), body: json.encode(model.toMap()));

    return handleReponse(response, url);
  }

  Future<ResultModel> delete(String url) async {
    final response =
        await http.delete(Uri.parse("$urlApi/$url"), headers: getHeaders());
    return handleReponse(response, url);
  }

  Map<String, String> getHeaders() {
    final token = storage.getToken();
    return {
      "Content-Type": "application/json",
      'Authorization': 'Bearer $token'
    };
  }

  ResultModel handleReponse(Response response, String url) {
    if (response.statusCode == 401 && url != 'token') {
      throw {'code': 401};
    }

    final resultModel = ResultModel.fromJson(json.decode(response.body));

    if (response.statusCode != 200) {
      for (var error in resultModel.errors) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ));
      }
    }
    return resultModel;
  }
}
