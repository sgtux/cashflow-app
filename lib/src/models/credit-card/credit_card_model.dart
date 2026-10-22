import 'package:cashflow_app/src/models/model_base.dart';

class CreditCardModel extends ModelBase {
  final int id;
  final String name;
  final int invoiceClosingDay;
  final int invoiceDueDay;

  /// Compras que compõem as faturas do cartão.
  final List<CreditCardItemModel> items;

  /// Tudo o que ainda falta pagar, somando parcelas futuras.
  final double outstandingDebtTotal;

  /// Valor da fatura do mês atual.
  final double currentMonthDebt;
  final bool isCurrentMonthDebtPaid;

  CreditCardModel(
      {required this.id,
      required this.name,
      this.invoiceClosingDay = 0,
      this.invoiceDueDay = 0,
      this.items = const [],
      this.outstandingDebtTotal = 0,
      this.currentMonthDebt = 0,
      this.isCurrentMonthDebtPaid = false});

  factory CreditCardModel.fromMap(Map<String, dynamic> map) {
    return CreditCardModel(
        id: map['id'],
        name: map['name'],
        invoiceClosingDay: map['invoiceClosingDay'] ?? 0,
        invoiceDueDay: map['invoiceDueDay'] ?? 0,
        items: ((map['items'] ?? []) as List)
            .map((e) => CreditCardItemModel.fromMap(e))
            .toList(),
        outstandingDebtTotal: asDouble(map['outstandingDebtTotal']),
        currentMonthDebt: asDouble(map['currentMonthDebt']),
        isCurrentMonthDebtPaid: map['isCurrentMonthDebtPaid'] ?? false);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'invoiceClosingDay': invoiceClosingDay,
      'invoiceDueDay': invoiceDueDay
    };
  }
}

/// Origem de um item da fatura (`CreditCardExpenseType` na API).
class CreditCardItemType {
  static const int installment = 1;
  static const int household = 2;
  static const int recurring = 3;
}

class CreditCardItemModel {
  final int id;
  final int type;
  final String description;
  final double outstandingDebt;
  final double currentMonthDebt;
  final bool isCurrentMonthDebtPaid;

  /// Parcelas no formato "pagas/total" (só para parcelamentos).
  final String? plots;
  final double total;

  CreditCardItemModel(
      {required this.id,
      required this.type,
      required this.description,
      required this.outstandingDebt,
      required this.currentMonthDebt,
      required this.isCurrentMonthDebtPaid,
      this.plots,
      this.total = 0});

  /// Despesas do dia a dia no cartão não são pagas item a item.
  bool get canPay =>
      !isCurrentMonthDebtPaid && type != CreditCardItemType.household;

  factory CreditCardItemModel.fromMap(Map<String, dynamic> map) {
    return CreditCardItemModel(
        id: map['id'],
        type: map['type'],
        description: map['description'] ?? '',
        outstandingDebt: asDouble(map['outstandingDebt']),
        currentMonthDebt: asDouble(map['currentMonthDebt']),
        isCurrentMonthDebtPaid: map['isCurrentMonthDebtPaid'] ?? false,
        plots: map['plots'],
        total: asDouble(map['total']));
  }
}
