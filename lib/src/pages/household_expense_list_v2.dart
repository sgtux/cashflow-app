import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/household-expense/household_expense_model.dart';
import 'package:cashflow_app/src/services/household_expense.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';

typedef HouseholdExpensesLoader = Future<List<HouseholdExpenseModel>> Function(
    BuildContext context, int month, int year);

/// Nova lista de despesas: navegação por mês, total, para onde foi o dinheiro
/// (por tipo) e lançamentos agrupados por dia.
class HouseholdExpenseListV2 extends StatelessWidget {
  const HouseholdExpenseListV2({Key? key, this.loadExpenses}) : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final HouseholdExpensesLoader? loadExpenses;

  @override
  Widget build(BuildContext context) {
    return V2Theme(
        child: _HouseholdExpenseListV2Body(loadExpenses: loadExpenses));
  }
}

class _HouseholdExpenseListV2Body extends StatefulWidget {
  const _HouseholdExpenseListV2Body({Key? key, required this.loadExpenses})
      : super(key: key);

  final HouseholdExpensesLoader? loadExpenses;

  @override
  State<_HouseholdExpenseListV2Body> createState() =>
      _HouseholdExpenseListV2BodyState();
}

class _HouseholdExpenseListV2BodyState
    extends State<_HouseholdExpenseListV2Body> {
  late int _month;
  late int _year;
  List<HouseholdExpenseModel> _expenses = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final loader = widget.loadExpenses ??
          (BuildContext c, int month, int year) => HouseholdExpenseService(c)
              .getSome(month.toString(), year.toString());
      final expenses = await loader(context, _month, _year);
      if (mounted) setState(() => _expenses = expenses);
    } catch (error, stackTrace) {
      debugPrint('[Despesas] Erro: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _hasError = true);
      handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int month, int year) {
    setState(() {
      _month = month;
      _year = year;
    });
    _load();
  }

  Future<void> _openDetail([HouseholdExpenseModel? expense]) async {
    await Navigator.pushNamed(context, Routes.householdExpenseDetail,
        arguments: expense);
    if (mounted) _load();
  }

  Future<bool> _delete(HouseholdExpenseModel expense) async {
    try {
      final result = await HouseholdExpenseService(context).remove(expense.id);
      return result.isValid();
    } catch (error) {
      if (mounted) handleHttpException(error, context);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            const ScreenTitle(
              title: 'Despesas',
              subtitle: 'Registre seus gastos e veja para onde vai o dinheiro.',
            ),
            const SizedBox(height: 16),
            MonthSelector(
              month: _month,
              year: _year,
              enabled: !_isLoading,
              onChanged: _changeMonth,
            ),
            const SizedBox(height: 12),
            ..._buildContent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDetail(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova despesa'),
      ),
    );
  }

  List<Widget> _buildContent() {
    if (_isLoading) {
      return const [
        SizedBox(
            height: 280, child: Center(child: CircularProgressIndicator())),
      ];
    }

    if (_hasError) {
      return [
        MessageCard.error(
            title: 'Não foi possível carregar as despesas', onRetry: _load),
      ];
    }

    if (_expenses.isEmpty) {
      return [
        MessageCard(
          icon: Icons.receipt_long_rounded,
          title: 'Nenhuma despesa em ${monthYearLabel(_month, _year)}',
          message: 'Toque em "Nova despesa" para registrar seus gastos. '
              'Anotar tudo é o primeiro passo para economizar.',
        ),
      ];
    }

    final sorted = [..._expenses]..sort((a, b) => b.date.compareTo(a.date));
    final days = <DateTime, List<HouseholdExpenseModel>>{};
    for (final expense in sorted) {
      final day =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      days.putIfAbsent(day, () => []).add(expense);
    }

    return [
      _SummaryCard(expenses: _expenses, month: _month, year: _year),
      const SectionTitle('Lançamentos'),
      Text('Toque para editar. Deslize para a esquerda para excluir.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      for (final entry in days.entries) ...[
        _DayHeader(date: entry.key, expenses: entry.value),
        ...entry.value.map((expense) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SwipeToDelete(
                key: ValueKey('expense-${expense.id}'),
                confirmTitle: 'Excluir esta despesa?',
                confirmMessage: expense.description,
                onDelete: () => _delete(expense),
                onDeleted: () => setState(() => _expenses.remove(expense)),
                child: _ExpenseTile(
                    expense: expense, onTap: () => _openDetail(expense)),
              ),
            )),
      ],
    ];
  }
}

/// Total do mês e divisão por tipo de despesa.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {Key? key,
      required this.expenses,
      required this.month,
      required this.year})
      : super(key: key);

  static const _maxCategories = 4;

  final List<HouseholdExpenseModel> expenses;
  final int month;
  final int year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = expenses.fold<double>(0, (sum, e) => sum + e.value.abs());

    final byType = <String, double>{};
    for (final e in expenses) {
      final type =
          (e.typeDescription ?? '').isEmpty ? 'Outros' : e.typeDescription!;
      byType[type] = (byType[type] ?? 0) + e.value.abs();
    }
    final categories = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (categories.length > _maxCategories) {
      final rest = categories
          .skip(_maxCategories - 1)
          .fold<double>(0, (sum, e) => sum + e.value);
      categories
        ..removeRange(_maxCategories - 1, categories.length)
        ..add(MapEntry('Outros', rest));
    }

    return V2Card(
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total gasto em ${monthYearLabel(month, year)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(money(total),
                style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: outColor(scheme))),
          ),
          Text(
              '${expenses.length} ${expenses.length == 1 ? 'despesa' : 'despesas'}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Text('Para onde foi o dinheiro',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...categories.map((category) {
            final share = total == 0 ? 0.0 : category.value / total;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(category.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium),
                      ),
                      Text(
                          '${money(category.value)} · ${(share * 100).round()}%',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: share,
                      minHeight: 6,
                      color: scheme.tertiary,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({Key? key, required this.date, required this.expenses})
      : super(key: key);

  final DateTime date;
  final List<HouseholdExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = expenses.fold<double>(0, (sum, e) => sum + e.value.abs());

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(dayMonthLabel(date),
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text(money(total),
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({Key? key, required this.expense, required this.onTap})
      : super(key: key);

  final HouseholdExpenseModel expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasVehicle = expense.vehicleId != null;

    return V2Card(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleIcon(
              hasVehicle
                  ? Icons.directions_car_rounded
                  : Icons.receipt_long_rounded,
              color: scheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge),
                if ((expense.typeDescription ?? '').isNotEmpty)
                  Text(expense.typeDescription!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(money(expense.value.abs()),
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: outColor(scheme), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
