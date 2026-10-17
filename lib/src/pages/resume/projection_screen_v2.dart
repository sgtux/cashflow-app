import 'dart:math';

import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/home/invoice_payment_model.dart';
import 'package:cashflow_app/src/models/home/payment_projection_model.dart';
import 'package:cashflow_app/src/models/home/projection_model.dart';
import 'package:cashflow_app/src/services/home.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

typedef ProjectionLoader = Future<List<ProjectionModel>> Function(
    BuildContext context);

/// Nova tela de projeção: mostra como o saldo evolui mês a mês, com gráfico,
/// dicas e o detalhamento de cada mês em linguagem simples.
class ProjectionScreenV2 extends StatelessWidget {
  const ProjectionScreenV2({Key? key, this.loadProjection}) : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final ProjectionLoader? loadProjection;

  @override
  Widget build(BuildContext context) {
    return V2Theme(child: _ProjectionV2Body(loadProjection: loadProjection));
  }
}

class _ProjectionV2Body extends StatefulWidget {
  const _ProjectionV2Body({Key? key, required this.loadProjection})
      : super(key: key);

  final ProjectionLoader? loadProjection;

  @override
  State<_ProjectionV2Body> createState() => _ProjectionV2BodyState();
}

class _ProjectionV2BodyState extends State<_ProjectionV2Body> {
  List<ProjectionModel> _months = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _selectedIndex = 0;
  String? _expandedMonth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final loader = widget.loadProjection ??
          (BuildContext c) => HomeService(c).getProjection();
      final months = await loader(context);
      if (!mounted) return;
      setState(() {
        _months = months;
        _selectedIndex = max(0, months.length - 1);
        _expandedMonth = null;
      });
    } catch (error, stackTrace) {
      debugPrint('[Projeção] Erro: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _hasError = true);
      handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const ScreenTitle(
              title: 'Projeção',
              subtitle: 'Veja como seu saldo deve evoluir nos próximos meses.',
            ),
            const SizedBox(height: 16),
            ..._buildContent(),
          ],
        ),
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
          title: 'Não foi possível carregar a projeção',
          onRetry: _load,
        ),
      ];
    }

    if (_months.isEmpty) {
      return const [
        MessageCard(
          icon: Icons.insights_rounded,
          title: 'Sua projeção aparece aqui',
          message: 'Cadastre suas receitas e despesas para ver como seu '
              'saldo vai evoluir nos próximos meses.',
        ),
      ];
    }

    final theme = Theme.of(context);
    return [
      _BalanceCard(
        months: _months,
        selectedIndex: _selectedIndex,
        onSelect: (index) => setState(() => _selectedIndex = index),
      ),
      const SizedBox(height: 12),
      _InsightCard(months: _months),
      const SizedBox(height: 24),
      Text('Mês a mês',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ..._months.map((month) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MonthCard(
              month: month,
              isExpanded: _expandedMonth == month.monthYear,
              onTap: () => setState(() {
                _expandedMonth =
                    _expandedMonth == month.monthYear ? null : month.monthYear;
              }),
            ),
          )),
    ];
  }
}

String _shortMonth(String monthYear) {
  final parts = monthYear.split('/');
  final month = getMonthList()[int.parse(parts[0]) - 1].substring(0, 3);
  final year = parts[1].length == 4 ? parts[1].substring(2) : parts[1];
  return '$month/$year';
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard(
      {Key? key,
      required this.months,
      required this.selectedIndex,
      required this.onSelect})
      : super(key: key);

  final List<ProjectionModel> months;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final month = months[selectedIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo acumulado em ${toMonthYearText(month.monthYear)}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(month.accumulatedValue),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: signedColor(scheme, month.accumulatedValue),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _AmountLabel(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Entra',
                  value: month.totalIn.abs(),
                  color: inColor(scheme)),
              _AmountLabel(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Sai',
                  value: month.totalOut.abs(),
                  color: outColor(scheme)),
            ],
          ),
          const SizedBox(height: 20),
          _BalanceChart(
              months: months, selectedIndex: selectedIndex, onSelect: onSelect),
          const SizedBox(height: 4),
          Text(
            'Toque em um mês do gráfico para ver o saldo dele.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel(
      {Key? key,
      required this.icon,
      required this.label,
      required this.value,
      required this.color})
      : super(key: key);

  final IconData icon;
  final String label;
  final num value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text('$label ', style: theme.textTheme.bodySmall),
        Text(
          money(value),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Gráfico de barras do saldo acumulado: barras acima da linha são saldo
/// positivo e abaixo, negativo.
class _BalanceChart extends StatelessWidget {
  const _BalanceChart(
      {Key? key,
      required this.months,
      required this.selectedIndex,
      required this.onSelect})
      : super(key: key);

  static const double _chartHeight = 120;
  static const double _barWidth = 22;
  static const double _minSlotWidth = 36;

  final List<ProjectionModel> months;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final values = months.map((m) => m.accumulatedValue.toDouble()).toList();
    final maxPositive = max(0.0, values.reduce(max));
    final maxNegative = max(0.0, -values.reduce(min));
    final range =
        maxPositive + maxNegative == 0 ? 1.0 : maxPositive + maxNegative;
    final positiveArea = _chartHeight * maxPositive / range;
    final negativeArea = _chartHeight - positiveArea;

    double barHeight(double value, double maxValue, double area) {
      if (value == 0 || maxValue == 0) return 0;
      return max(3.0, area * value.abs() / maxValue);
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Ocupa toda a largura quando os meses cabem; senão, rola na horizontal.
      final slotWidth =
          max(_minSlotWidth, constraints.maxWidth / months.length);

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Começa mostrando os últimos meses quando o gráfico não cabe na tela.
        reverse: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(months.length, (index) {
            final value = values[index];
            final selected = index == selectedIndex;
            final color = signedColor(scheme, value)
                .withValues(alpha: selected ? 1 : 0.35);

            return Semantics(
              button: true,
              selected: selected,
              label: '${toMonthYearText(months[index].monthYear)}: '
                  '${money(value)}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(index),
                child: SizedBox(
                  width: slotWidth,
                  child: Column(
                    children: [
                      SizedBox(
                        height: positiveArea,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _bar(
                              value > 0
                                  ? barHeight(value, maxPositive, positiveArea)
                                  : 0,
                              color,
                              top: true),
                        ),
                      ),
                      Container(height: 1, color: scheme.outlineVariant),
                      SizedBox(
                        height: negativeArea,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _bar(
                              value < 0
                                  ? barHeight(value, maxNegative, negativeArea)
                                  : 0,
                              color,
                              top: false),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _shortMonth(months[index].monthYear),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          color: selected
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _bar(double height, Color color, {required bool top}) {
    const radius = Radius.circular(6);
    return Container(
      width: _barWidth,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: top
            ? const BorderRadius.vertical(top: radius)
            : const BorderRadius.vertical(bottom: radius),
      ),
    );
  }
}

/// Dica em linguagem simples, calculada a partir da projeção.
class _InsightCard extends StatelessWidget {
  const _InsightCard({Key? key, required this.months}) : super(key: key);

  final List<ProjectionModel> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    IconData icon;
    String title;
    String message;
    Color background;
    Color foreground;

    final negativeMonths = months.where((m) => m.accumulatedValue < 0);
    final positiveNet = months.where((m) => m.total > 0).toList();

    if (negativeMonths.isNotEmpty) {
      final month = negativeMonths.first;
      icon = Icons.warning_amber_rounded;
      title = 'Atenção ao seu saldo';
      message = 'Em ${toMonthYearText(month.monthYear)} o saldo acumulado fica '
          'negativo (${money(month.accumulatedValue)}). '
          'Reveja gastos ou evite novas compras parceladas até lá.';
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
    } else if (positiveNet.isNotEmpty) {
      final average = positiveNet.map((m) => m.total).reduce((a, b) => a + b) /
          positiveNet.length;
      icon = Icons.savings_outlined;
      title = 'Seu dinheiro pode render';
      message = 'Seu saldo fica positivo em todos os meses, com sobra média de '
          '${money(average)} por mês. Que tal guardar parte '
          'dela numa reserva de emergência antes de começar a investir?';
      background = scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
    } else {
      icon = Icons.lightbulb_outline_rounded;
      title = 'Dica';
      message = 'Seu saldo segue positivo, mas as saídas estão próximas das '
          'entradas. Cortar pequenos gastos do dia a dia ajuda a sobrar mais.';
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: foreground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard(
      {Key? key,
      required this.month,
      required this.isExpanded,
      required this.onTap})
      : super(key: key);

  final ProjectionModel month;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totalIn = month.totalIn.abs();
    final totalOut = month.totalOut.abs();
    final spentRatio = totalIn == 0 ? null : totalOut / totalIn;

    Color ratioColor(num ratio) {
      if (ratio > 1) return scheme.error;
      if (ratio > 0.8) {
        return theme.brightness == Brightness.dark
            ? Colors.amber.shade300
            : Colors.amber.shade800;
      }
      return scheme.primary;
    }

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      toMonthYearText(month.monthYear),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _NetChip(value: month.total),
                  Icon(isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AmountColumn(
                        label: 'Entradas',
                        value: totalIn,
                        color: inColor(scheme)),
                  ),
                  Expanded(
                    child: _AmountColumn(
                        label: 'Saídas',
                        value: totalOut,
                        color: outColor(scheme)),
                  ),
                ],
              ),
              if (spentRatio != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: spentRatio.clamp(0, 1).toDouble(),
                    minHeight: 8,
                    color: ratioColor(spentRatio),
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  spentRatio > 1
                      ? 'Você gasta ${(spentRatio * 100).round()}% do que '
                          'entra: as saídas passam das entradas.'
                      : 'Você gasta ${(spentRatio * 100).round()}% do que entra.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Saldo acumulado: '
                '${money(month.accumulatedValue)}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: signedColor(scheme, month.accumulatedValue),
                    fontWeight: FontWeight.w600),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                _MonthDetails(month: month),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NetChip extends StatelessWidget {
  const _NetChip({Key? key, required this.value}) : super(key: key);

  final num value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = signedColor(scheme, value);

    return Tooltip(
      message: 'Quanto sobra (ou falta) neste mês',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          signedMoney(value),
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn(
      {Key? key, required this.label, required this.value, required this.color})
      : super(key: key);

  final String label;
  final num value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            money(value),
            style: theme.textTheme.titleSmall
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Lançamentos do mês: faturas de cartão agrupadas e os demais lançamentos.
class _MonthDetails extends StatelessWidget {
  const _MonthDetails({Key? key, required this.month}) : super(key: key);

  final ProjectionModel month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final invoices = <InvoicePaymentModel>[];
    for (final payment
        in month.payments.where((p) => p.creditCardName.isNotEmpty)) {
      var invoice = invoices
          .where((i) => i.creditCardName == payment.creditCardName)
          .toList();
      if (invoice.isEmpty) {
        invoices.add(InvoicePaymentModel(payment.creditCardName, []));
        invoice = [invoices.last];
      }
      invoice.first.payments.add(payment);
    }
    for (final invoice in invoices) {
      invoice.calculateTotal();
    }

    final others =
        month.payments.where((p) => p.creditCardName.isEmpty).toList()
          ..sort((a, b) {
            if (a.isIn != b.isIn) return a.isIn ? -1 : 1;
            return a.description.compareTo(b.description);
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invoices.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Faturas de cartão',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          ...invoices.map((invoice) => Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(left: 8),
                  leading: Icon(Icons.credit_card_rounded,
                      color: scheme.onSurfaceVariant),
                  title: Text(invoice.creditCardName),
                  subtitle: Text('${invoice.payments.length} '
                      '${invoice.payments.length == 1 ? 'lançamento' : 'lançamentos'}'),
                  trailing: Text(
                    '- ${money(invoice.total.abs())}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: outColor(scheme), fontWeight: FontWeight.bold),
                  ),
                  children: invoice.payments
                      .map((p) => _PaymentRow(payment: p))
                      .toList(),
                ),
              )),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Lançamentos',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          ...others.map((p) => _PaymentRow(payment: p)),
        ],
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({Key? key, required this.payment}) : super(key: key);

  final PaymentProjectionModel payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = payment.isIn ? inColor(scheme) : outColor(scheme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              payment.isIn
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium),
                if (payment.qtdInstallments > 0)
                  Text(
                    'Parcela ${payment.number}/${payment.qtdInstallments}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${payment.isIn ? '+' : '-'} '
            '${money(payment.value.abs())}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
