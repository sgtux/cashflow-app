import 'package:cashflow_app/src/models/model_base.dart';

/// Ganhos fixos e contas fixas têm o mesmo comportamento; muda o vocabulário
/// e os nomes dos campos que a API espera.
enum RecurringKind { earning, expense }

extension RecurringKindApi on RecurringKind {
  String get resource =>
      this == RecurringKind.earning ? 'RecurringEarning' : 'RecurringExpense';

  /// Campo do valor no histórico.
  String get historyValueKey =>
      this == RecurringKind.earning ? 'value' : 'paidValue';

  /// Campo que liga o histórico ao item.
  String get parentKey => this == RecurringKind.earning
      ? 'recurringEarningId'
      : 'recurringExpenseId';

  /// Campo que indica se já foi recebido/pago no mês atual.
  String get doneKey => this == RecurringKind.earning ? 'received' : 'paid';
}

class RecurringModel extends ModelBase {
  final RecurringKind kind;
  final int id;
  final String description;

  /// Valor de costume por mês.
  final double value;
  final DateTime? inactiveAt;
  final int? creditCardId;
  final String? creditCardName;

  /// Recebido/pago no mês atual.
  final bool done;

  /// Do mais recente para o mais antigo.
  final List<RecurringHistoryModel> history;

  RecurringModel(
      {required this.kind,
      required this.id,
      required this.description,
      required this.value,
      this.inactiveAt,
      this.creditCardId,
      this.creditCardName,
      this.done = false,
      this.history = const []});

  bool get isActive => inactiveAt == null;

  factory RecurringModel.fromMap(RecurringKind kind, Map<String, dynamic> map) {
    final card = map['creditCard'] as Map<String, dynamic>?;
    final history = ((map['history'] ?? []) as List)
        .map((e) => RecurringHistoryModel.fromMap(kind, e))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return RecurringModel(
        kind: kind,
        id: map['id'],
        description: map['description'] ?? '',
        value: asDouble(map['value']),
        inactiveAt: asDate(map['inactiveAt']),
        creditCardId: map['creditCardId'] ?? card?['id'],
        creditCardName: card?['name'],
        done: map[kind.doneKey] ?? false,
        history: history);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'value': value,
      'inactiveAt': inactiveAt?.toIso8601String(),
      if (kind == RecurringKind.expense) 'creditCardId': creditCardId,
    };
  }
}

class RecurringHistoryModel extends ModelBase {
  final RecurringKind kind;
  final int id;
  final int parentId;
  final double value;
  final DateTime date;

  RecurringHistoryModel(
      {required this.kind,
      required this.id,
      required this.parentId,
      required this.value,
      required this.date});

  factory RecurringHistoryModel.fromMap(
      RecurringKind kind, Map<String, dynamic> map) {
    return RecurringHistoryModel(
        kind: kind,
        id: map['id'],
        parentId: map[kind.parentKey] ?? 0,
        value: asDouble(map[kind.historyValueKey]),
        date: asDate(map['date']) ?? DateTime.now());
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      kind.parentKey: parentId,
      kind.historyValueKey: value,
      'date': date.toIso8601String()
    };
  }
}
