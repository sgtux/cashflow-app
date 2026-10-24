import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/earning/earning_model.dart';
import 'package:cashflow_app/src/services/earning.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

typedef EarningsLoader = Future<List<EarningModel>> Function(
    BuildContext context, DateTime fromDate);

/// Ganhos avulsos (freelas, vendas, bônus) desde o mês escolhido.
class EarningListV2Screen extends StatelessWidget {
  const EarningListV2Screen({Key? key, this.loadEarnings}) : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final EarningsLoader? loadEarnings;

  @override
  Widget build(BuildContext context) {
    return V2Theme(child: _EarningListV2Body(loadEarnings: loadEarnings));
  }
}

class _EarningListV2Body extends StatefulWidget {
  const _EarningListV2Body({Key? key, required this.loadEarnings})
      : super(key: key);

  final EarningsLoader? loadEarnings;

  @override
  State<_EarningListV2Body> createState() => _EarningListV2BodyState();
}

class _EarningListV2BodyState extends State<_EarningListV2Body> {
  /// Últimos 12 meses, do atual para o mais antigo.
  final List<DateTime> _months = List.generate(12, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - i);
  });

  late DateTime _since = _months.first;
  List<EarningModel> _earnings = [];
  bool _isLoading = true;
  bool _hasError = false;

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
      final loader = widget.loadEarnings ??
          (BuildContext c, DateTime from) => EarningService(c).getSome(from);
      final earnings = await loader(context, _since);
      earnings.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) setState(() => _earnings = earnings);
    } catch (error, stackTrace) {
      debugPrint('[Ganhos] Erro: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _hasError = true);
      handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetail([EarningModel? earning]) async {
    final saved = await Navigator.pushNamed(context, Routes.earningDetail,
        arguments: earning);
    if (!mounted) return;
    if (saved == true) showSuccess(context, 'Ganho salvo!');
    _load();
  }

  Future<bool> _delete(EarningModel earning) async {
    try {
      final result = await EarningService(context).remove(earning.id);
      return result.isValid();
    } catch (error) {
      if (mounted) handleHttpException(error, context);
      return false;
    }
  }

  /// Repete o ganho no mês atual, no mesmo dia do mês.
  Future<void> _copyToCurrentMonth(EarningModel earning) async {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final day = earning.date.day > lastDay ? lastDay : earning.date.day;
    final copy = EarningModel(
        id: 0,
        description: earning.description,
        value: earning.value,
        date: DateTime(now.year, now.month, day),
        type: earning.type);

    setState(() => _isLoading = true);
    try {
      final result = await EarningService(context).save(copy);
      if (mounted && result.isValid()) {
        showSuccess(context, 'Ganho copiado para este mês.');
      }
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    }
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganhos')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            const ScreenIntro('Dinheiro que entrou de forma avulsa: freelas, '
                'vendas, bônus, presentes.'),
            const SizedBox(height: 16),
            DropdownButtonFormField<DateTime>(
              initialValue: _since,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Mostrar ganhos desde',
                prefixIcon: Icon(Icons.filter_list_rounded),
              ),
              items: _months
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(monthYearLabel(m.month, m.year))))
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (month) {
                      if (month == null) return;
                      setState(() => _since = month);
                      _load();
                    },
            ),
            const SizedBox(height: 12),
            ..._buildContent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDetail(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar ganho'),
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
            title: 'Não foi possível carregar os ganhos', onRetry: _load),
      ];
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = _earnings.fold<double>(0, (sum, e) => sum + e.value);
    final now = DateTime.now();

    return [
      V2Card(
        color: scheme.surfaceContainerHigh,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total no período',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(money(total),
                  style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: inColor(scheme))),
            ),
            Text(
                '${_earnings.length} ${_earnings.length == 1 ? 'ganho' : 'ganhos'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      TipCard(
        icon: Icons.event_repeat_rounded,
        title: 'O salário entra todo mês?',
        message: 'Cadastre em Ganhos fixos para não precisar lançar de novo.',
        actionLabel: 'Ir para Ganhos fixos',
        onAction: () =>
            Navigator.pushNamed(context, Routes.recurringEarningList),
      ),
      if (_earnings.isEmpty) ...[
        const SizedBox(height: 12),
        const MessageCard(
          icon: Icons.trending_up_rounded,
          title: 'Nenhum ganho neste período',
          message: 'Fez um trabalho extra, vendeu algo ou ganhou um bônus? '
              'Toque em "Registrar ganho" para saber exatamente quanto entrou.',
        ),
      ] else ...[
        const SectionTitle('Lançamentos'),
        Text('Toque para editar. Deslize para a esquerda para excluir.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        ..._earnings.map((earning) {
          final isCurrentMonth =
              earning.date.year == now.year && earning.date.month == now.month;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SwipeToDelete(
              key: ValueKey('earning-${earning.id}'),
              confirmTitle: 'Excluir este ganho?',
              confirmMessage:
                  '"${earning.description}" deixará de contar nas suas entradas.',
              onDelete: () => _delete(earning),
              onDeleted: () => setState(() => _earnings.remove(earning)),
              child: V2Card(
                onTap: () => _openDetail(earning),
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                child: Row(
                  children: [
                    CircleIcon(Icons.trending_up_rounded,
                        color: inColor(scheme)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(earning.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge),
                          Text(
                              [
                                if ((earning.typeDescription ?? '').isNotEmpty)
                                  earning.typeDescription!,
                                'Recebido em ${toDateString(value: earning.date, separator: '/')}',
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(money(earning.value),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: inColor(scheme),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (!isCurrentMonth)
                      IconButton(
                        tooltip: 'Repetir este ganho no mês atual',
                        onPressed: () => _copyToCurrentMonth(earning),
                        icon: const Icon(Icons.content_copy_rounded),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    ];
  }
}
