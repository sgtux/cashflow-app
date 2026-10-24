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

  /// Corrida dos ratos: quanto do custo de vida (saídas sem os aportes em
  /// investimento) a renda passiva cobre. 1 = 100%.
  final num totalPassiveInflows;
  final num totalLivingCosts;
  final num passiveIncomeCoverage;
  final bool outOfRatRace;

  HomeDataModel(
      {required this.month,
      required this.year,
      required this.pendingPayments,
      required this.limitValues,
      required this.inflows,
      required this.outflows,
      required this.totalInflows,
      required this.totalOutflows,
      this.totalPassiveInflows = 0,
      this.totalLivingCosts = 0,
      this.passiveIncomeCoverage = 0,
      this.outOfRatRace = false});

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
        totalOutflows: map['totalOutflows'],
        totalPassiveInflows: map['totalPassiveInflows'] ?? 0,
        totalLivingCosts: map['totalLivingCosts'] ?? 0,
        passiveIncomeCoverage: map['passiveIncomeCoverage'] ?? 0,
        outOfRatRace: map['outOfRatRace'] ?? false);
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
