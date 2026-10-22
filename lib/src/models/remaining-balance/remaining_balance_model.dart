import 'package:cashflow_app/src/models/model_base.dart';

/// Quanto sobrou (ou faltou) no fim de um mês. Sem `id`, é a simulação do
/// mês atual, que ainda não foi fechado.
class RemainingBalanceModel extends ModelBase {
  final int id;
  final int month;
  final int year;
  final double value;

  RemainingBalanceModel(
      {required this.id,
      required this.month,
      required this.year,
      required this.value});

  bool get isSimulation => id == 0;

  factory RemainingBalanceModel.fromMap(Map<String, dynamic> map) {
    return RemainingBalanceModel(
        id: map['id'] ?? 0,
        month: map['month'],
        year: map['year'],
        value: asDouble(map['value']));
  }

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'month': month, 'year': year, 'value': value};
  }
}
