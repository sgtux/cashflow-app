import 'package:cashflow_app/src/models/home/payment_projection_model.dart';

class ProjectionModel {
  final String monthYear;
  final num totalIn;
  final num totalOut;
  final num total;
  final num accumulatedValue;
  final List<PaymentProjectionModel> payments;

  ProjectionModel(
      {required this.monthYear,
      required this.totalIn,
      required this.totalOut,
      required this.total,
      required this.accumulatedValue,
      required this.payments});

  factory ProjectionModel.fromMap(Map<String, dynamic> map) {
    List<PaymentProjectionModel> list = [];
    for (var e in (map['payments'] as List)) {
      list.add(PaymentProjectionModel.fromMap(e));
    }
    return ProjectionModel(
        monthYear: map['monthYear'],
        accumulatedValue: map['accumulatedValue'],
        total: map['total'],
        totalIn: map['totalIn'],
        totalOut: map['totalOut'],
        payments: list);
  }
}
