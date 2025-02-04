import 'package:cashflow_app/src/models/home/home_limit_value.dart';
import 'package:cashflow_app/src/models/home/home_description_value.dart';

class HomeDataModel {
  final int month;
  final int year;
  final List<HomeDescriptionValue> pendingPayments;
  final List<HomeLimitValue> limitValues;
  final List<HomeDescriptionValue> inflows;
  final List<HomeDescriptionValue> outflows;
  final num totalInflows;
  final num totalOutflows;

  HomeDataModel(
      {required this.month,
      required this.year,
      required this.pendingPayments,
      required this.limitValues,
      required this.inflows,
      required this.outflows,
      required this.totalInflows,
      required this.totalOutflows});

  factory HomeDataModel.fromMap(Map<String, dynamic> map) {
    List<HomeDescriptionValue> pendingPaymentsList = [];
    List<HomeLimitValue> limitValuesList = [];
    List<HomeDescriptionValue> inflowsList = [];
    List<HomeDescriptionValue> outflowsList = [];

    for (var e in (map['pendingPayments'] as List)) {
      pendingPaymentsList.add(HomeDescriptionValue.fromMap(e));
    }

    for (var e in (map['limitValues'] as List)) {
      limitValuesList.add(HomeLimitValue.fromMap(e));
    }

    for (var e in (map['inflows'] as List)) {
      inflowsList.add(HomeDescriptionValue.fromMap(e));
    }

    for (var e in (map['outflows'] as List)) {
      outflowsList.add(HomeDescriptionValue.fromMap(e));
    }

    return HomeDataModel(
        month: map['month'],
        year: map['year'],
        pendingPayments: pendingPaymentsList,
        limitValues: limitValuesList,
        inflows: inflowsList,
        outflows: outflowsList,
        totalInflows: map['totalInflows'],
        totalOutflows: map['totalOutflows']);
  }

  factory HomeDataModel.initialValue() {   

    return HomeDataModel(
        month: 0,
        year: 0,
        pendingPayments: [],
        limitValues: [],
        inflows: [],
        outflows: [],
        totalInflows: 0,
        totalOutflows: 0);
  }
}
