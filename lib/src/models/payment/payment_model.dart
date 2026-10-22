import 'package:cashflow_app/src/models/model_base.dart';

/// Compra ou empréstimo dividido em parcelas.
class PaymentModel extends ModelBase {
  final int id;
  final String description;
  final int type;
  final int? creditCardId;
  final String? creditCardName;

  /// Data da compra.
  final DateTime? date;
  final List<InstallmentModel> installments;

  PaymentModel(
      {required this.id,
      required this.description,
      required this.type,
      required this.installments,
      this.creditCardId,
      this.creditCardName,
      this.date});

  /// Parcelas pagas ou isentas.
  int get paidInstallments => installments.where((p) => p.isSettled).length;

  bool get done =>
      installments.isNotEmpty && paidInstallments == installments.length;

  double get total => installments.fold(0, (sum, p) => sum + p.value);

  InstallmentModel? get currentMonthInstallment {
    final now = DateTime.now();
    for (final p in installments) {
      if (p.date.year == now.year && p.date.month == now.month) return p;
    }
    return null;
  }

  /// Valor da parcela do mês atual (ou da primeira, se não houver).
  double get installmentValue =>
      currentMonthInstallment?.value ??
      (installments.isEmpty ? 0 : installments.first.value);

  bool get currentMonthPaid => currentMonthInstallment?.paidDate != null;

  DateTime? get firstDate =>
      installments.isEmpty ? null : installments.first.date;

  DateTime? get lastDate =>
      installments.isEmpty ? null : installments.last.date;

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    final installments = ((map['installments'] ?? []) as List)
        .map((e) => InstallmentModel.fromMap(e))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final cardName = (map['creditCardText'] as String?) ??
        (map['creditCard'] as Map<String, dynamic>?)?['name'];
    return PaymentModel(
        id: map['id'],
        description: map['description'] ?? '',
        type: map['type'] ?? 0,
        creditCardId: map['creditCardId'],
        creditCardName: (cardName ?? '').isEmpty ? null : cardName,
        date: asDate(map['date']),
        installments: installments);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'type': type,
      'creditCardId': creditCardId,
      'date': date?.toIso8601String(),
      'installments': installments.map((p) => p.toMap()).toList()
    };
  }
}

class InstallmentModel extends ModelBase {
  final int id;
  final int paymentId;
  final int number;
  final double value;

  /// Vencimento.
  final DateTime date;
  final double? paidValue;
  final DateTime? paidDate;

  /// Parcela que não precisa ser paga (perdoada, cancelada ou estornada).
  final bool exempt;

  InstallmentModel(
      {this.id = 0,
      this.paymentId = 0,
      required this.number,
      required this.value,
      required this.date,
      this.paidValue,
      this.paidDate,
      this.exempt = false});

  bool get isSettled => paidDate != null || exempt;

  /// Cópia com uma nova situação de pagamento.
  InstallmentModel withPayment(
      {double? paidValue, DateTime? paidDate, bool exempt = false}) {
    return InstallmentModel(
        id: id,
        paymentId: paymentId,
        number: number,
        value: value,
        date: date,
        paidValue: exempt ? null : paidValue,
        paidDate: exempt ? null : paidDate,
        exempt: exempt);
  }

  factory InstallmentModel.fromMap(Map<String, dynamic> map) {
    return InstallmentModel(
        id: map['id'] ?? 0,
        paymentId: map['paymentId'] ?? 0,
        number: map['number'],
        value: asDouble(map['value']),
        date: asDate(map['date']) ?? DateTime.now(),
        paidValue: map['paidValue'] == null ? null : asDouble(map['paidValue']),
        paidDate: asDate(map['paidDate']),
        exempt: map['exempt'] ?? false);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'number': number,
      'value': value,
      'date': date.toIso8601String(),
      'paidValue': paidValue,
      'paidDate': paidDate?.toIso8601String(),
      'exempt': exempt
    };
  }
}
