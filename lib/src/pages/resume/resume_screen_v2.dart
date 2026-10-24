import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/home/home_data_model.dart';
import 'package:cashflow_app/src/models/home/home_description_value.dart';
import 'package:cashflow_app/src/models/home/home_limit_value.dart';
import 'package:cashflow_app/src/services/home.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';

typedef HomeDataLoader = Future<HomeDataModel> Function(
    BuildContext context, int month, int year);

/// Novo resumo do mês: saldo, limites de gastos, contas pendentes, entradas e
/// saídas, com dicas em linguagem simples.
class ResumeScreenV2 extends StatelessWidget {
  const ResumeScreenV2({Key? key, this.loadHomeData}) : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final HomeDataLoader? loadHomeData;

  @override
  Widget build(BuildContext context) {
    return V2Theme(child: _ResumeV2Body(loadHomeData: loadHomeData));
  }
}

class _ResumeV2Body extends StatefulWidget {
  const _ResumeV2Body({Key? key, required this.loadHomeData}) : super(key: key);

  final HomeDataLoader? loadHomeData;

  @override
  State<_ResumeV2Body> createState() => _ResumeV2BodyState();
}

class _ResumeV2BodyState extends State<_ResumeV2Body> {
  late int _month;
  late int _year;
  HomeDataModel? _data;
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
      final loader = widget.loadHomeData ??
          (BuildContext c, int month, int year) =>
              HomeService(c).getHomeData(month: month, year: year);
      final data = await loader(context, _month, _year);
      if (mounted) setState(() => _data = data);
    } catch (error, stackTrace) {
      debugPrint('[Resumo] Erro: $error\n$stackTrace');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const ScreenTitle(
              title: 'Resumo',
              subtitle: 'Como está o seu dinheiro neste mês.',
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
    );
  }

  List<Widget> _buildContent() {
    if (_isLoading) {
      return const [
        SizedBox(
            height: 280, child: Center(child: CircularProgressIndicator())),
      ];
    }

    final data = _data;
    if (_hasError || data == null) {
      return [
        MessageCard.error(
            title: 'Não foi possível carregar o resumo', onRetry: _load),
      ];
    }

    final totalIn = data.totalInflows.abs();
    final totalOut = data.totalOutflows.abs();
    final pendingTotal =
        data.pendingPayments.fold<num>(0, (sum, p) => sum + p.value.abs());

    return [
      _BalanceCard(totalIn: totalIn, totalOut: totalOut),
      const SizedBox(height: 12),
      _SavingsTip(totalIn: totalIn, totalOut: totalOut),
      SectionTitle('Corrida dos ratos',
          trailing: Text('${(data.passiveIncomeCoverage * 100).round()}%',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: data.outOfRatRace
                      ? inColor(Theme.of(context).colorScheme)
                      : null,
                  fontWeight: FontWeight.bold))),
      _RatRaceCard(data: data),
      if (data.limitValues.isNotEmpty) ...[
        const SectionTitle('Limites de gastos'),
        ...data.limitValues.map((limit) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LimitCard(limit: limit),
            )),
      ],
      SectionTitle(
        'Contas pendentes',
        trailing: data.pendingPayments.isEmpty
            ? null
            : Text(money(pendingTotal),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: outColor(Theme.of(context).colorScheme),
                    fontWeight: FontWeight.bold)),
      ),
      _PendingCard(payments: data.pendingPayments),
      SectionTitle('Entradas',
          trailing: _SectionTotal(value: totalIn, isIn: true)),
      _ValueListCard(
        items: data.inflows,
        total: totalIn,
        isIn: true,
        emptyMessage: 'Nenhuma entrada registrada neste mês.',
      ),
      SectionTitle('Saídas',
          trailing: _SectionTotal(value: totalOut, isIn: false)),
      _ValueListCard(
        items: data.outflows,
        total: totalOut,
        isIn: false,
        emptyMessage: 'Nenhuma saída registrada neste mês.',
      ),
    ];
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({Key? key, required this.totalIn, required this.totalOut})
      : super(key: key);

  final num totalIn;
  final num totalOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final balance = totalIn - totalOut;
    final ratio = totalIn == 0 ? null : totalOut / totalIn;

    return V2Card(
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo do mês',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(balance),
              style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: signedColor(scheme, balance)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Amount(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Entrou',
                    value: totalIn,
                    color: inColor(scheme)),
              ),
              Expanded(
                child: _Amount(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Saiu',
                    value: totalOut,
                    color: outColor(scheme)),
              ),
            ],
          ),
          if (ratio != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1).toDouble(),
                minHeight: 8,
                color: usageColor(theme, ratio),
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Você usou ${(ratio * 100).round()}% do que entrou.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount(
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
      children: [
        CircleIcon(icon, color: color, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(money(value),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dica sobre quanto da renda sobrou no mês.
class _SavingsTip extends StatelessWidget {
  const _SavingsTip({Key? key, required this.totalIn, required this.totalOut})
      : super(key: key);

  final num totalIn;
  final num totalOut;

  @override
  Widget build(BuildContext context) {
    if (totalIn == 0 && totalOut == 0) {
      return const TipCard(
        icon: Icons.edit_note_rounded,
        title: 'Comece pelo básico',
        message: 'Registre o que entra e o que sai. Saber para onde vai o '
            'dinheiro é o primeiro passo para conseguir guardar.',
      );
    }

    if (totalOut > totalIn) {
      return TipCard(
        isWarning: true,
        icon: Icons.warning_amber_rounded,
        title: 'Saiu mais do que entrou',
        message: 'Neste mês faltaram ${money(totalOut - totalIn)}. Veja as '
            'saídas abaixo e procure gastos que dá para cortar ou adiar.',
      );
    }

    final saved = (totalIn - totalOut) / totalIn;
    final percent = (saved * 100).round();
    if (saved >= 0.2) {
      return TipCard(
        icon: Icons.trending_up_rounded,
        title: 'Ótimo, você guardou $percent% da renda',
        message: 'Com a reserva de emergência montada, uma parte dessa sobra '
            'pode começar a ser investida para render ao longo do tempo.',
      );
    }
    if (saved >= 0.1) {
      return TipCard(
        icon: Icons.savings_outlined,
        title: 'Sobrou $percent% da renda',
        message: 'Bom trabalho! Guardar de 10% a 20% do que entra é uma meta '
            'comum para construir uma reserva.',
      );
    }
    return TipCard(
      icon: Icons.lightbulb_outline_rounded,
      title: 'Sobrou $percent% da renda',
      message: 'Tente chegar a 10%: revise gastos pequenos e assinaturas que '
          'você quase não usa.',
    );
  }
}

/// Quanto do custo de vida do mês a renda passiva já paga. A partir de 100%,
/// saiu da corrida dos ratos.
class _RatRaceCard extends StatelessWidget {
  const _RatRaceCard({Key? key, required this.data}) : super(key: key);

  final HomeDataModel data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final passive = data.totalPassiveInflows;
    final coverage = data.passiveIncomeCoverage;
    final percent = (coverage * 100).round();
    final color = data.outOfRatRace ? inColor(scheme) : warningColor(theme);

    final String message;
    if (data.outOfRatRace) {
      message = 'Sua renda passiva já paga todo o seu custo de vida do mês. '
          'Você saiu da corrida dos ratos!';
    } else if (passive > 0) {
      message = 'Sua renda passiva de ${money(passive)} cobre $percent% do '
          'seu custo de vida (as saídas, sem contar os aportes). Faltam '
          '${money(data.totalLivingCosts - passive)} por mês para sair da '
          'corrida.';
    } else {
      message = 'Nenhuma renda passiva neste mês. Aluguéis, dividendos e '
          'juros que você recebe aparecem aqui.';
    }

    return V2Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleIcon(Icons.directions_run_rounded, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: coverage.clamp(0, 1).toDouble(),
              minHeight: 10,
              color: color,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitCard extends StatelessWidget {
  const _LimitCard({Key? key, required this.limit}) : super(key: key);

  final HomeLimitValue limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratio = limit.limit == 0 ? 0 : limit.spent / limit.limit;
    final color = usageColor(theme, ratio);
    final remaining = limit.limit - limit.spent;

    return V2Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(limit.description,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Text('${(ratio * 100).round()}%',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1).toDouble(),
              minHeight: 10,
              color: color,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${money(limit.spent)} de ${money(limit.limit)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              Text(
                remaining >= 0
                    ? 'Resta ${money(remaining)}'
                    : 'Passou ${money(-remaining)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({Key? key, required this.payments}) : super(key: key);

  final List<HomeDescriptionValue> payments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (payments.isEmpty) {
      return V2Card(
        child: Row(
          children: [
            CircleIcon(Icons.check_rounded, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Tudo em dia: nenhuma conta pendente.',
                  style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
    }

    return V2Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: payments
            .map((p) => _ValueRow(
                  icon: Icons.schedule_rounded,
                  description: p.description,
                  value: p.value.abs(),
                  color: warningColor(theme),
                  valueColor: outColor(scheme),
                ))
            .toList(),
      ),
    );
  }
}

class _SectionTotal extends StatelessWidget {
  const _SectionTotal({Key? key, required this.value, required this.isIn})
      : super(key: key);

  final num value;
  final bool isIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      money(value),
      style: theme.textTheme.titleSmall?.copyWith(
        color: isIn ? inColor(theme.colorScheme) : outColor(theme.colorScheme),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Lista de entradas ou saídas, do maior para o menor valor, mostrando
/// quanto cada item representa do total.
class _ValueListCard extends StatefulWidget {
  const _ValueListCard(
      {Key? key,
      required this.items,
      required this.total,
      required this.isIn,
      required this.emptyMessage})
      : super(key: key);

  final List<HomeDescriptionValue> items;
  final num total;
  final bool isIn;
  final String emptyMessage;

  @override
  State<_ValueListCard> createState() => _ValueListCardState();
}

class _ValueListCardState extends State<_ValueListCard> {
  static const _collapsedCount = 5;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = widget.isIn ? inColor(scheme) : outColor(scheme);

    if (widget.items.isEmpty) {
      return V2Card(
        child: Text(widget.emptyMessage,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
      );
    }

    final sorted = [...widget.items]
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final visible = _showAll ? sorted : sorted.take(_collapsedCount).toList();

    return V2Card(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          ...visible.map((item) => _ValueRow(
                icon: widget.isIn
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                description: item.description,
                value: item.value.abs(),
                color: color,
                share:
                    widget.total == 0 ? null : item.value.abs() / widget.total,
              )),
          if (sorted.length > _collapsedCount)
            TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(
                  _showAll ? 'Mostrar menos' : 'Ver todas (${sorted.length})'),
            ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow(
      {Key? key,
      required this.icon,
      required this.description,
      required this.value,
      required this.color,
      this.valueColor,
      this.share})
      : super(key: key);

  final IconData icon;
  final String description;
  final num value;
  final Color color;
  final Color? valueColor;

  /// Fração do total (0 a 1), exibida como percentual.
  final num? share;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleIcon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium),
                if (share != null)
                  Text('${(share! * 100).round()}% do total',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(money(value),
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
