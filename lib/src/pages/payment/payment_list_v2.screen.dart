import 'dart:async';

import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/payment/payment_model.dart';
import 'package:cashflow_app/src/models/type_model.dart';
import 'package:cashflow_app/src/services/payment.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

typedef PaymentsLoader = Future<List<PaymentModel>> Function(
    BuildContext context, PaymentFilter filter);

/// Parcelamentos: busca, filtro por situação e período, e o progresso de
/// cada compra até quitar.
class PaymentListV2Screen extends StatelessWidget {
  const PaymentListV2Screen({Key? key, this.loadPayments, this.loadTypes})
      : super(key: key);

  /// Permitem substituir a busca na API (usados nos testes).
  final PaymentsLoader? loadPayments;
  final Future<List<TypeModel>> Function(BuildContext context)? loadTypes;

  @override
  Widget build(BuildContext context) {
    return V2Theme(
        child: _PaymentListV2Body(
            loadPayments: loadPayments, loadTypes: loadTypes));
  }
}

class _PaymentListV2Body extends StatefulWidget {
  const _PaymentListV2Body(
      {Key? key, required this.loadPayments, required this.loadTypes})
      : super(key: key);

  final PaymentsLoader? loadPayments;
  final Future<List<TypeModel>> Function(BuildContext context)? loadTypes;

  @override
  State<_PaymentListV2Body> createState() => _PaymentListV2BodyState();
}

/// Situação filtrada → parâmetro `done` da API.
enum _Status { inProgress, done, all }

class _PaymentListV2BodyState extends State<_PaymentListV2Body> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  _Status _status = _Status.inProgress;
  DateTimeRange? _period;
  List<PaymentModel> _payments = [];
  Map<int, String> _typeNames = {};
  bool _isLoading = true;
  bool _hasError = false;

  bool get _hasFilters =>
      _searchController.text.trim().isNotEmpty ||
      _status != _Status.inProgress ||
      _period != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTypes();
      _load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await (widget.loadTypes ??
          (BuildContext c) => PaymentService(c).getTypes())(context);
      if (mounted) {
        setState(
            () => _typeNames = {for (final t in types) t.id: t.description});
      }
    } catch (error) {
      // Sem os tipos a lista funciona, só não mostra a categoria.
      debugPrint('[Parcelamentos] Erro ao carregar tipos: $error');
    }
  }

  PaymentFilter get _filter => PaymentFilter(
        description: _searchController.text,
        done: _status == _Status.all ? null : _status == _Status.done,
        startDate: _period?.start,
        endDate: _period?.end,
      );

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final loader = widget.loadPayments ??
          (BuildContext c, PaymentFilter f) => PaymentService(c).getSome(f);
      final payments = await loader(context, _filter);
      if (mounted) setState(() => _payments = payments);
    } catch (error, stackTrace) {
      debugPrint('[Parcelamentos] Erro: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _hasError = true);
      handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Espera a pessoa parar de digitar antes de buscar.
  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 600), _load);
    setState(() {});
  }

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final period = await showDateRangePicker(
      context: context,
      initialDateRange: _period,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      helpText: 'Comprados entre',
    );
    if (period == null) return;
    setState(() => _period = period);
    _load();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _status = _Status.inProgress;
      _period = null;
    });
    _load();
  }

  Future<void> _openDetail([PaymentModel? payment]) async {
    final saved = await Navigator.pushNamed(context, Routes.paymentDetail,
        arguments: payment);
    if (!mounted) return;
    if (saved == true) showSuccess(context, 'Parcelamento salvo!');
    _load();
  }

  Future<bool> _delete(PaymentModel payment) async {
    try {
      final result = await PaymentService(context).remove(payment.id);
      return result.isValid();
    } catch (error) {
      if (mounted) handleHttpException(error, context);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Parcelamentos')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            const ScreenIntro(
                'Compras e empréstimos divididos em parcelas mensais.'),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Buscar pelo nome',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_Status>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: _Status.inProgress, label: Text('Em andamento')),
                ButtonSegment(value: _Status.done, label: Text('Quitados')),
                ButtonSegment(value: _Status.all, label: Text('Todos')),
              ],
              selected: {_status},
              onSelectionChanged: (selected) {
                setState(() => _status = selected.first);
                _load();
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InputChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text(_period == null
                      ? 'Qualquer data de compra'
                      : '${toDateString(value: _period!.start, separator: '/')} – '
                          '${toDateString(value: _period!.end, separator: '/')}'),
                  onPressed: _pickPeriod,
                  onDeleted: _period == null
                      ? null
                      : () {
                          setState(() => _period = null);
                          _load();
                        },
                ),
                if (_hasFilters)
                  TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Limpar filtros')),
              ],
            ),
            const SizedBox(height: 12),
            ..._buildContent(theme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDetail(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo parcelamento'),
      ),
    );
  }

  List<Widget> _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const [
        SizedBox(
            height: 240, child: Center(child: CircularProgressIndicator())),
      ];
    }

    if (_hasError) {
      return [
        MessageCard.error(
            title: 'Não foi possível carregar os parcelamentos',
            onRetry: _load),
      ];
    }

    if (_payments.isEmpty) {
      return [
        _hasFilters
            ? MessageCard(
                icon: Icons.search_off_rounded,
                title: 'Nada encontrado com esses filtros',
                message: 'Tente limpar os filtros ou buscar por outro nome.',
                actionLabel: 'Limpar filtros',
                onAction: _clearFilters,
              )
            : MessageCard(
                icon: Icons.view_week_rounded,
                title: 'Nenhum parcelamento em andamento',
                message: 'Comprou algo em várias vezes ou fez um empréstimo? '
                    'Cadastre aqui e veja quando cada parcela vence.',
                actionLabel: 'Cadastrar parcelamento',
                onAction: () => _openDetail(),
              ),
      ];
    }

    return [
      Text(
          'Toque para ver e editar as parcelas. Deslize para a esquerda '
          'para excluir.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      ..._payments.map((payment) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SwipeToDelete(
              key: ValueKey('payment-${payment.id}'),
              confirmTitle: 'Remover parcelamento?',
              confirmMessage: '"${payment.description}" e todas as suas '
                  'parcelas serão apagados.',
              onDelete: () => _delete(payment),
              onDeleted: () => setState(() => _payments.remove(payment)),
              child: _PaymentTile(
                payment: payment,
                typeName: _typeNames[payment.type],
                onTap: () => _openDetail(payment),
              ),
            ),
          )),
    ];
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile(
      {Key? key, required this.payment, required this.onTap, this.typeName})
      : super(key: key);

  final PaymentModel payment;
  final String? typeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = payment.installments.length;
    final paid = payment.paidInstallments;
    final left = count - paid;
    final subtle =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return V2Card(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (typeName != null) Text(typeName!, style: subtle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${count}x ${money(payment.installmentValue)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: outColor(scheme),
                          fontWeight: FontWeight.w600)),
                  Text('total ${money(payment.total)}', style: subtle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (payment.done)
                const StatusChip('Quitado', tone: StatusTone.done)
              else if (payment.currentMonthPaid)
                const StatusChip('Parcela do mês paga', tone: StatusTone.done),
              if (payment.creditCardName != null)
                CreditCardLabel(payment.creditCardName!),
            ],
          ),
          const SizedBox(height: 12),
          V2ProgressBar(value: count == 0 ? 0 : paid / count),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                    '$paid de $count parcelas pagas'
                    '${!payment.done && left > 0 ? ' · faltam $left' : ''}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (payment.firstDate != null)
                Text(
                    '${_shortMonth(payment.firstDate!)} → '
                    '${_shortMonth(payment.lastDate!)}',
                    style: subtle),
            ],
          ),
        ],
      ),
    );
  }

  static String _shortMonth(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
