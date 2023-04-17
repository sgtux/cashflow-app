import 'package:cashflow_app/src/models/model_base.dart';

class FuelExpenseModel extends ModelBase {
  final int id;
  final int miliage;
  final num valueSupplied;
  final num pricePerLiter;
  final DateTime date;
  final int vehicleId;
  final String vehicleName;
  late num litersSupplied;  

  FuelExpenseModel(
      {required this.id,
      required this.miliage,
      required this.valueSupplied,
      required this.pricePerLiter,
      required this.date,
      required this.vehicleId,
      required this.vehicleName,
      litersSupplied});

  factory FuelExpenseModel.fromMap(Map<String, dynamic> map, String vehicleName) {
    return FuelExpenseModel(
      id: map['id'],
      miliage: map['miliage'],
      valueSupplied: map['valueSupplied'],
      pricePerLiter: map['pricePerLiter'],
      date: DateTime.parse(map['date']),
      vehicleId: map['vehicleId'],
      vehicleName: vehicleName,
      litersSupplied: map['litersSupplied'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "miliage": miliage,
      "valueSupplied": valueSupplied,
      "pricePerLiter": pricePerLiter,
      "date": date.toIso8601String(),
      "vehicleId": vehicleId
    };
  }
}
