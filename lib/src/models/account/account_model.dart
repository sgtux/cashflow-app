import 'package:cashflow_app/src/models/model_base.dart';

/// Dados da conta: limites mensais e uso do plano.
class AccountModel extends ModelBase {
  final String email;
  final double expenseLimit;
  final double fuelExpenseLimit;
  final int plan;
  final int recordsUsed;

  AccountModel(
      {required this.email,
      required this.expenseLimit,
      required this.fuelExpenseLimit,
      required this.plan,
      required this.recordsUsed});

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
        email: map['email'] ?? '',
        expenseLimit: asDouble(map['expenseLimit']),
        fuelExpenseLimit: asDouble(map['fuelExpenseLimit']),
        plan: map['plan'] ?? 1,
        recordsUsed: map['recordsUsed'] ?? 0);
  }

  /// Só os limites são alterados pelo app.
  @override
  Map<String, dynamic> toMap() {
    return {'expenseLimit': expenseLimit, 'fuelExpenseLimit': fuelExpenseLimit};
  }
}
