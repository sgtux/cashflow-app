import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/credit-card/credit_card_model.dart';
import 'package:cashflow_app/src/services/credit_card.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/flutter_masked_text.dart';
import 'package:flutter/material.dart';

/// Cartões de crédito: fatura do mês, crédito devedor e as compras de cada
/// cartão, com a opção de registrar o pagamento de um item da fatura.
class CreditCardListV2Screen extends StatelessWidget {
  const CreditCardListV2Screen({Key? key, this.loadCards}) : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final Future<List<CreditCardModel>> Function(BuildContext context)? loadCards;

  @override
  Widget build(BuildContext context) {
    return V2Theme(child: _CreditCardListV2Body(loadCards: loadCards));
  }
}

class _CreditCardListV2Body extends StatefulWidget {
  const _CreditCardListV2Body({Key? key, required this.loadCards})
      : super(key: key);

  final Future<List<CreditCardModel>> Function(BuildContext context)? loadCards;

  @override
  State<_CreditCardListV2Body> createState() => _CreditCardListV2BodyState();
}

class _CreditCardListV2BodyState extends State<_CreditCardListV2Body> {
  List<CreditCardModel> _cards = [];
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
      final loader =
          widget.loadCards ?? (BuildContext c) => CreditCardService(c).getAll();
      final cards = await loader(context);
      if (mounted) setState(() => _cards = cards);
    } catch (error, stackTrace) {
      debugPrint('[Cartões] Erro: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _hasError = true);
      handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetail([CreditCardModel? card]) async {
    final saved = await Navigator.pushNamed(context, Routes.creditCardDetail,
        arguments: card);
    if (!mounted) return;
    if (saved == true) showSuccess(context, 'Cartão salvo!');
    _load();
  }

  Future<void> _delete(CreditCardModel card) async {
    final confirmed = await confirmDelete(context,
        title: 'Remover cartão?',
        message: 'O cartão "${card.name}" será removido. Cartões com compras '
            'ou contas vinculadas não podem ser removidos.');
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final result = await CreditCardService(context).remove(card.id);
      if (mounted && result.isValid()) showSuccess(context, 'Cartão removido.');
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    }
    if (mounted) _load();
  }

  Future<void> _pay(CreditCardModel card, CreditCardItemModel item) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _PayItemDialog(item: item),
    );
    if (value == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final result =
          await CreditCardService(context).payInvoiceItem(card, item, value);
      if (mounted && result.isValid()) {
        showSuccess(context, 'Pagamento registrado!');
      }
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    }
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cartões e faturas')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            const ScreenIntro('Veja quanto vai pagar em cada cartão neste mês '
                'e o que ainda falta quitar.'),
            const SizedBox(height: 16),
            ..._buildContent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDetail(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar cartão'),
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
            title: 'Não foi possível carregar os cartões', onRetry: _load),
      ];
    }

    if (_cards.isEmpty) {
      return [
        MessageCard(
          icon: Icons.credit_card_rounded,
          title: 'Nenhum cartão cadastrado',
          message: 'Cadastrar seus cartões ajuda a lembrar que cada compra no '
              'crédito é um dinheiro que sairá do seu bolso no mês seguinte.',
          actionLabel: 'Adicionar meu cartão',
          onAction: () => _openDetail(),
        ),
      ];
    }

    return [
      for (var i = 0; i < _cards.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _CreditCardPanel(
            card: _cards[i],
            index: i,
            onEdit: () => _openDetail(_cards[i]),
            onDelete: () => _delete(_cards[i]),
            onPay: (item) => _pay(_cards[i], item),
          ),
        ),
      const TipCard(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Dica',
        message: 'Pagar a fatura inteira evita juros, que no cartão estão '
            'entre os mais altos do mercado.',
      ),
    ];
  }
}

class _CreditCardPanel extends StatelessWidget {
  const _CreditCardPanel(
      {Key? key,
      required this.card,
      required this.index,
      required this.onEdit,
      required this.onDelete,
      required this.onPay})
      : super(key: key);

  static const _gradients = [
    [Color(0xFF0B6E4F), Color(0xFF0F9D6E)],
    [Color(0xFF3A3F7A), Color(0xFF5D63B8)],
    [Color(0xFF7A3A4E), Color(0xFFB85D79)],
    [Color(0xFF2F4F6F), Color(0xFF4F7FA8)],
    [Color(0xFF5A4A1E), Color(0xFFA7832F)],
  ];

  final CreditCardModel card;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<CreditCardItemModel> onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = _gradients[index % _gradients.length];
    const onCard = Colors.white;

    return V2Card(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: onCard, fontWeight: FontWeight.bold)),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Opções do cartão',
                      iconColor: onCard,
                      onSelected: (action) =>
                          action == 'edit' ? onEdit() : onDelete(),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Remover')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Fatura atual',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: onCard.withValues(alpha: 0.85))),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(money(card.currentMonthDebt),
                      style: theme.textTheme.headlineMedium?.copyWith(
                          color: onCard, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    Text('Fecha dia ${card.invoiceClosingDay}',
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: onCard)),
                    Text('Vence dia ${card.invoiceDueDay}',
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: onCard)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fatura deste mês',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      card.isCurrentMonthDebtPaid
                          ? const StatusChip('Paga', tone: StatusTone.done)
                          : const StatusChip('Em aberto',
                              tone: StatusTone.pending),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Crédito devedor',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(money(card.outstandingDebtTotal),
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: card.outstandingDebtTotal > 0
                                  ? outColor(scheme)
                                  : inColor(scheme))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              childrenPadding: EdgeInsets.zero,
              title: Text('Compras (${card.items.length})',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              children: card.items.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('Nenhuma compra neste cartão.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                    ]
                  : card.items
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _InvoiceItemTile(
                                item: item, onPay: () => onPay(item)),
                          ))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceItemTile extends StatelessWidget {
  const _InvoiceItemTile({Key? key, required this.item, required this.onPay})
      : super(key: key);

  final CreditCardItemModel item;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtle =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final details = [
      (item.plots ?? '').isNotEmpty
          ? 'Parcelas: ${item.plots}'
          : 'À vista ou conta fixa',
      if (item.total > 0) 'total ${money(item.total)}',
    ].join(' · ');

    return V2Card(
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(12),
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
                    Text(item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(details, style: subtle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('falta pagar', style: subtle),
                  Text(money(item.outstandingDebt),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: outColor(scheme),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Neste mês: ${money(item.currentMonthDebt)}',
                    style: subtle),
              ),
              if (item.isCurrentMonthDebtPaid)
                const StatusChip('Mês pago', tone: StatusTone.done)
              else if (item.canPay)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12)),
                  onPressed: onPay,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Pagar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pergunta quanto foi pago de um item na fatura do mês.
class _PayItemDialog extends StatefulWidget {
  const _PayItemDialog({Key? key, required this.item}) : super(key: key);

  final CreditCardItemModel item;

  @override
  State<_PayItemDialog> createState() => _PayItemDialogState();
}

class _PayItemDialogState extends State<_PayItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');

  @override
  void initState() {
    super.initState();
    _valueController.updateValue(widget.item.currentMonthDebt);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pagamento'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.description),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quanto você pagou na fatura?',
                helperText: 'Já vem preenchido com o valor deste mês.',
              ),
              validator: (_) => _valueController.numberValue <= 0
                  ? 'Informe um valor maior que zero'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _valueController.numberValue);
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
