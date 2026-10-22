import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/remaining-balance/remaining_balance_model.dart';
import 'package:cashflow_app/src/services/remaining_balance.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/flutter_masked_text.dart';
import 'package:flutter/material.dart';

/// Fechamento do mês: quanto realmente sobrou (ou faltou) em cada mês, com
/// ajuste manual e recálculo.
class RemainingBalanceV2Screen extends StatelessWidget {
  const RemainingBalanceV2Screen({Key? key, this.loadBalances})
      : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final Future<List<RemainingBalanceModel>> Function(BuildContext context)?
      loadBalances;

  @override
  Widget build(BuildContext context) {
    return V2Theme(child: _RemainingBalanceV2Body(loadBalances: loadBalances));
  }
}

class _RemainingBalanceV2Body extends StatefulWidget {
  const _RemainingBalanceV2Body({Key? key, required this.loadBalances})
      : super(key: key);

  final Future<List<RemainingBalanceModel>> Function(BuildContext context)?
      loadBalances;

  @override
  State<_RemainingBalanceV2Body> createState() =>
      _RemainingBalanceV2BodyState();
}

class _RemainingBalanceV2BodyState extends State<_RemainingBalanceV2Body> {
  static const _recentCount = 5;

  List<RemainingBalanceModel> _items = [];
  bool _showAll = false;
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
      final loader = widget.loadBalances ??
          (BuildContext c) => RemainingBalanceService(c).getAll();
      final items = await loader(context);
      if (mounted) setState(() => _items = items);
    } catch (error, stackTrace) {
      debugPrint('[Fechamento] Erro: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _hasError = true);
      handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _adjust(RemainingBalanceModel item) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _AdjustDialog(item: item),
    );
    if (value == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final result = await RemainingBalanceService(context).update(
          RemainingBalanceModel(
              id: item.id, month: item.month, year: item.year, value: value));
      if (mounted && result.isValid()) showSuccess(context, 'Valor ajustado!');
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    }
    if (mounted) _load();
  }

  Future<void> _recalculate(RemainingBalanceModel item) async {
    final label = monthYearLabel(item.month, item.year);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recalcular este mês?'),
        content: Text('O valor de $label será refeito a partir dos ganhos e '
            'gastos lançados, substituindo qualquer ajuste manual.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Recalcular'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final result = await RemainingBalanceService(context).recalculate(item);
      if (mounted && result.isValid()) {
        showSuccess(context, 'Mês recalculado!');
      }
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    }
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fechamento do mês')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const ScreenIntro(
                'Quanto realmente sobrou (ou faltou) no fim de cada mês, '
                'já contando a sobra do mês anterior.'),
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
            title: 'Não foi possível carregar o fechamento', onRetry: _load),
      ];
    }

    if (_items.isEmpty) {
      return const [
        MessageCard(
          icon: Icons.savings_rounded,
          title: 'Nenhum mês fechado ainda',
          message: 'Quando um mês termina, calculamos automaticamente quanto '
              'sobrou. Volte aqui no começo do próximo mês!',
        ),
      ];
    }

    final visible = _showAll ? _items : _items.take(_recentCount).toList();

    return [
      ...visible.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _BalanceTile(
              item: item,
              onAdjust: () => _adjust(item),
              onRecalculate: () => _recalculate(item),
            ),
          )),
      if (_items.length > _recentCount)
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showAll = !_showAll),
            child: Text(_showAll
                ? 'Mostrar só os últimos $_recentCount meses'
                : 'Mostrar todos os ${_items.length} meses'),
          ),
        ),
    ];
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile(
      {Key? key,
      required this.item,
      required this.onAdjust,
      required this.onRecalculate})
      : super(key: key);

  final RemainingBalanceModel item;
  final VoidCallback onAdjust;
  final VoidCallback onRecalculate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = signedColor(scheme, item.value);
    final caption = item.isSimulation
        ? 'Simulação do mês atual: muda conforme você lança ganhos e gastos.'
        : item.value >= 0
            ? 'Sobrou dinheiro neste mês'
            : 'Ficou devendo neste mês';

    return V2Card(
      color: item.isSimulation ? scheme.surfaceContainer : null,
      padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(monthYearLabel(item.month, item.year),
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(caption,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(money(item.value),
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: color, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            if (!item.isSimulation)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Ajustar valor manualmente',
                    onPressed: onAdjust,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Recalcular pelo que está lançado',
                    onPressed: onRecalculate,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Ajuste manual do saldo do mês, com a opção de marcar como devedor.
class _AdjustDialog extends StatefulWidget {
  const _AdjustDialog({Key? key, required this.item}) : super(key: key);

  final RemainingBalanceModel item;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  final _valueController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  late bool _debt = widget.item.value < 0;

  double get _finalValue =>
      _debt ? -_valueController.numberValue : _valueController.numberValue;

  @override
  void initState() {
    super.initState();
    _valueController.updateValue(widget.item.value.abs());
    _valueController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
          'Ajustar ${monthYearLabel(widget.item.month, widget.item.year)}'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Use quando o valor não bater com o saldo real da sua conta '
              'no fim do mês.',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Quanto sobrou (ou faltou)?'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fechei o mês devendo'),
            value: _debt,
            onChanged: (value) => setState(() => _debt = value),
          ),
          Text('Valor final: ${money(_finalValue)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: signedColor(theme.colorScheme, _finalValue),
                  fontWeight: FontWeight.w600)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
          onPressed: () => Navigator.pop(context, _finalValue),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
