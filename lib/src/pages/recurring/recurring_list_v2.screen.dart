import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/recurring/recurring_model.dart';
import 'package:cashflow_app/src/pages/recurring/recurring_texts.dart';
import 'package:cashflow_app/src/services/recurring.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';

typedef RecurringLoader = Future<List<RecurringModel>> Function(
    BuildContext context, bool showInactive);

/// Ganhos fixos ou contas fixas: total do mês, o que falta receber/pagar e
/// atalho para registrar o mês com o valor de costume.
class RecurringListV2Screen extends StatelessWidget {
  const RecurringListV2Screen({Key? key, required this.kind, this.loadItems})
      : super(key: key);

  final RecurringKind kind;

  /// Permite substituir a busca na API (usado nos testes).
  final RecurringLoader? loadItems;

  @override
  Widget build(BuildContext context) {
    return V2Theme(
        child: _RecurringListV2Body(kind: kind, loadItems: loadItems));
  }
}

class _RecurringListV2Body extends StatefulWidget {
  const _RecurringListV2Body(
      {Key? key, required this.kind, required this.loadItems})
      : super(key: key);

  final RecurringKind kind;
  final RecurringLoader? loadItems;

  @override
  State<_RecurringListV2Body> createState() => _RecurringListV2BodyState();
}

class _RecurringListV2BodyState extends State<_RecurringListV2Body> {
  List<RecurringModel> _items = [];
  bool _showInactive = false;
  bool _isLoading = true;
  bool _hasError = false;

  RecurringKind get _kind => widget.kind;
  RecurringTexts get _texts => RecurringTexts.of(_kind);
  bool get _isEarning => _kind == RecurringKind.earning;

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
      final loader = widget.loadItems ??
          (BuildContext c, bool showInactive) =>
              RecurringService(c, _kind).getAll(showInactive: showInactive);
      final items = await loader(context, _showInactive);
      if (mounted) setState(() => _items = items);
    } catch (error, stackTrace) {
      debugPrint('[${_texts.title}] Erro: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _hasError = true);
      handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetail([RecurringModel? item]) async {
    final saved = await Navigator.pushNamed(context, Routes.recurringDetail,
        arguments: item ??
            RecurringModel(kind: _kind, id: 0, description: '', value: 0));
    if (!mounted) return;
    if (saved == true) showSuccess(context, 'Salvo!');
    _load();
  }

  /// Registra o mês com o valor de costume e a data de hoje.
  Future<void> _quickDone(RecurringModel item) async {
    setState(() => _isLoading = true);
    try {
      final result = await RecurringService(context, _kind).saveHistory(
          RecurringHistoryModel(
              kind: _kind,
              id: 0,
              parentId: item.id,
              value: item.value,
              date: DateTime.now()));
      if (mounted && result.isValid()) {
        showSuccess(context, '${item.description}: registrado!');
      }
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    }
    if (mounted) _load();
  }

  Future<bool> _delete(RecurringModel item) async {
    try {
      final result = await RecurringService(context, _kind).remove(item.id);
      return result.isValid();
    } catch (error) {
      if (mounted) handleHttpException(error, context);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_texts.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            ScreenIntro(_texts.subtitle),
            const SizedBox(height: 16),
            ..._buildContent(),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_texts.showInactive),
              subtitle: const Text('Itens encerrados não entram mais nas '
                  'contas do mês nem na projeção.'),
              value: _showInactive,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() => _showInactive = value);
                      _load();
                    },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDetail(),
        icon: const Icon(Icons.add_rounded),
        label: Text(_texts.add),
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
            title: 'Não foi possível carregar ${_texts.title.toLowerCase()}',
            onRetry: _load),
      ];
    }

    if (_items.isEmpty) {
      return [
        MessageCard(
          icon: _texts.icon,
          title: _texts.emptyTitle,
          message: _texts.emptyMessage,
          actionLabel: _texts.add,
          onAction: () => _openDetail(),
        ),
      ];
    }

    final theme = Theme.of(context);
    final active = _items.where((p) => p.isActive).toList();

    return [
      if (active.isNotEmpty) ...[
        _SummaryCard(kind: _kind, active: active),
        const SectionTitle('Cadastrados'),
      ],
      Text(
          'Toque para editar e ver o histórico. Deslize para a esquerda '
          'para excluir.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      ..._items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SwipeToDelete(
              key: ValueKey('recurring-${item.id}'),
              confirmTitle: _texts.removeTitle,
              confirmMessage: '"${item.description}" e todo o histórico serão '
                  'apagados. Se só parou de existir, prefira encerrar '
                  '(editar → ${_texts.inactiveAtLabel.toLowerCase()}).',
              onDelete: () => _delete(item),
              onDeleted: () => setState(() => _items.remove(item)),
              child: _RecurringTile(
                item: item,
                texts: _texts,
                isEarning: _isEarning,
                onTap: () => _openDetail(item),
                onQuickDone: () => _quickDone(item),
              ),
            ),
          )),
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({Key? key, required this.kind, required this.active})
      : super(key: key);

  final RecurringKind kind;
  final List<RecurringModel> active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final texts = RecurringTexts.of(kind);
    final color =
        kind == RecurringKind.earning ? inColor(scheme) : outColor(scheme);
    final total = active.fold<double>(0, (sum, p) => sum + p.value);
    final pending = active.where((p) => !p.done).toList();
    final pendingTotal = pending.fold<double>(0, (sum, p) => sum + p.value);

    return V2Card(
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.totalLabel,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(money(total),
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(
                  pending.isEmpty
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  color:
                      pending.isEmpty ? scheme.primary : warningColor(theme)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    pending.isEmpty
                        ? 'Tudo certo por aqui este mês!'
                        : texts.pendingCount(pending.length),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (pending.isNotEmpty)
                Text(money(pendingTotal),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile(
      {Key? key,
      required this.item,
      required this.texts,
      required this.isEarning,
      required this.onTap,
      required this.onQuickDone})
      : super(key: key);

  final RecurringModel item;
  final RecurringTexts texts;
  final bool isEarning;
  final VoidCallback onTap;
  final VoidCallback onQuickDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isEarning ? inColor(scheme) : outColor(scheme);

    final status = !item.isActive
        ? StatusChip(texts.inactive, tone: StatusTone.inactive)
        : item.done
            ? StatusChip(texts.done, tone: StatusTone.done)
            : StatusChip(texts.pending, tone: StatusTone.pending);

    return Opacity(
      opacity: item.isActive ? 1 : 0.7,
      child: V2Card(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleIcon(texts.icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge),
                      if ((item.typeDescription ?? '').isNotEmpty)
                        Text(item.typeDescription!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      Text('${money(item.value)} por mês',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(child: status),
                if ((item.creditCardName ?? '').isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(child: CreditCardLabel(item.creditCardName!)),
                ],
                const Spacer(),
                if (item.isActive && !item.done)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12)),
                    onPressed: onQuickDone,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(texts.quickAction),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
