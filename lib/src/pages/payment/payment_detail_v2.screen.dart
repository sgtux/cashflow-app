import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/credit-card/credit_card_model.dart';
import 'package:cashflow_app/src/models/payment/payment_model.dart';
import 'package:cashflow_app/src/models/type_model.dart';
import 'package:cashflow_app/src/services/credit_card.service.dart';
import 'package:cashflow_app/src/services/payment.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/flutter_masked_text.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

/// Tipo usado por padrão em um novo parcelamento ("Outros").
const int defaultPaymentTypeId = 20;

/// Limite de parcelas aceito pela API.
const int maxInstallments = 72;

/// Formulário de parcelamento em três etapas: o que foi comprado, como foi
/// pago (gera as parcelas) e a situação de cada parcela. Recebe o
/// [PaymentModel] a editar como argumento da rota.
class PaymentDetailV2Screen extends StatelessWidget {
  const PaymentDetailV2Screen(
      {Key? key, this.loadTypes, this.loadCreditCards, this.loadPayment})
      : super(key: key);

  /// Permitem substituir a busca na API (usados nos testes).
  final Future<List<TypeModel>> Function(BuildContext context)? loadTypes;
  final Future<List<CreditCardModel>> Function(BuildContext context)?
      loadCreditCards;
  final Future<PaymentModel?> Function(BuildContext context, int id)?
      loadPayment;

  @override
  Widget build(BuildContext context) {
    return V2Theme(
      child: _PaymentDetailV2Body(
          loadTypes: loadTypes,
          loadCreditCards: loadCreditCards,
          loadPayment: loadPayment),
    );
  }
}

class _PaymentDetailV2Body extends StatefulWidget {
  const _PaymentDetailV2Body(
      {Key? key,
      required this.loadTypes,
      required this.loadCreditCards,
      required this.loadPayment})
      : super(key: key);

  final Future<List<TypeModel>> Function(BuildContext context)? loadTypes;
  final Future<List<CreditCardModel>> Function(BuildContext context)?
      loadCreditCards;
  final Future<PaymentModel?> Function(BuildContext context, int id)?
      loadPayment;

  @override
  State<_PaymentDetailV2Body> createState() => _PaymentDetailV2BodyState();
}

class _PaymentDetailV2BodyState extends State<_PaymentDetailV2Body> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  final _amountController = TextEditingController(text: '1');

  int _id = 0;
  int _type = defaultPaymentTypeId;
  int _creditCardId = 0;
  DateTime? _purchaseDate = DateTime.now();
  List<TypeModel> _types = [];
  List<CreditCardModel> _cards = [];
  List<InstallmentModel> _installments = [];

  /// As parcelas refletem os dados da etapa 2. Mudou valor, data, cartão ou
  /// quantidade? É preciso gerar de novo antes de salvar.
  bool _installmentsUpdated = false;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSaving = false;

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  bool get _canGenerate =>
      _valueController.numberValue > 0 &&
      _purchaseDate != null &&
      _amount >= 1 &&
      _amount <= maxInstallments;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final argument =
        ModalRoute.of(context)?.settings.arguments as PaymentModel?;

    try {
      final typesTask = (widget.loadTypes ??
          (BuildContext c) => PaymentService(c).getTypes())(context);
      // Sem os cartões o formulário ainda funciona, só não oferece a opção.
      final cardsTask = (widget.loadCreditCards ??
              (BuildContext c) => CreditCardService(c).getAll())(context)
          .catchError((Object error) {
        debugPrint('[Parcelamento] Erro ao carregar cartões: $error');
        return <CreditCardModel>[];
      });
      final paymentTask = (argument?.id ?? 0) > 0
          ? (widget.loadPayment ??
              (BuildContext c, int id) =>
                  PaymentService(c).getById(id))(context, argument!.id)
          : Future<PaymentModel?>.value(null);

      final types = await typesTask;
      final cards = await cardsTask;
      final payment = await paymentTask ?? argument;
      if (!mounted) return;

      setState(() {
        _types = types;
        _cards = cards;
        if (payment != null) _fill(payment);
      });
    } catch (error, stackTrace) {
      debugPrint('[Parcelamento] Erro: $error\n$stackTrace');
      if (mounted) handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fill(PaymentModel payment) {
    _id = payment.id;
    _descriptionController.text = payment.description;
    _type = payment.type;
    _creditCardId = payment.creditCardId ?? 0;
    _installments = [...payment.installments];
    _valueController.updateValue(payment.total);
    _amountController.text =
        '${_installments.isEmpty ? 1 : _installments.length}';
    _purchaseDate = payment.date ?? payment.firstDate ?? DateTime.now();
    _installmentsUpdated = payment.id > 0;
  }

  void _paymentDataChanged() {
    if (_installmentsUpdated) setState(() => _installmentsUpdated = false);
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGenerating = true);
    try {
      final installments = await PaymentService(context).generateInstallments(
          value: _valueController.numberValue,
          amount: _amount,
          date: _purchaseDate!,
          creditCardId: _creditCardId);
      if (mounted && installments.isNotEmpty) {
        setState(() {
          _installments = installments;
          _installmentsUpdated = true;
        });
      }
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _replaceInstallment(InstallmentModel installment) {
    setState(() {
      _installments = _installments
          .map((p) => p.number == installment.number ? installment : p)
          .toList();
    });
  }

  Future<void> _editInstallment(InstallmentModel installment) async {
    final edited = await showDialog<InstallmentModel>(
      context: context,
      builder: (_) => _InstallmentDialog(installment: installment),
    );
    if (edited != null) _replaceInstallment(edited);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if (_installments.isEmpty || !_installmentsUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gere as parcelas (etapa 2) antes de salvar.')));
      return;
    }

    final model = PaymentModel(
      id: _id,
      description: _descriptionController.text.trim(),
      type: _type,
      creditCardId: _creditCardId > 0 ? _creditCardId : null,
      date: _purchaseDate,
      installments: _installments,
    );

    setState(() => _isSaving = true);
    try {
      final result = await PaymentService(context).save(model);
      if (mounted && result.isValid()) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_id > 0 ? 'Editar parcelamento' : 'Novo parcelamento')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const ScreenIntro('Cadastre uma vez e acompanhe cada '
                      'parcela até quitar.'),
                  const _StepTitle(number: 1, title: 'O que foi comprado?'),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex.: Geladeira, Curso de inglês',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Informe uma descrição'
                        : null,
                  ),
                  if (_types.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue:
                          _types.any((t) => t.id == _type) ? _type : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _types
                          .map((t) => DropdownMenuItem(
                              value: t.id, child: Text(t.description)))
                          .toList(),
                      onChanged: (type) =>
                          setState(() => _type = type ?? _type),
                      validator: (type) =>
                          type == null ? 'Escolha o tipo' : null,
                    ),
                  ],
                  const _StepTitle(number: 2, title: 'Como foi pago?'),
                  TextFormField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _paymentDataChanged();
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      labelText: 'Valor total da compra',
                      helperText:
                          'Some todas as parcelas, se a loja cobrou juros.',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DateFormField(
                    label: 'Data da compra',
                    value: _purchaseDate,
                    onChanged: (date) {
                      _paymentDataChanged();
                      setState(() => _purchaseDate = date);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _paymentDataChanged();
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Em quantas vezes?',
                      prefixIcon: const Icon(Icons.view_week_outlined),
                      helperText: _amount < 1 || _amount > maxInstallments
                          ? 'De 1 a $maxInstallments parcelas'
                          : _valueController.numberValue > 0
                              ? 'Fica ${_amount}x de '
                                  '${money(_valueController.numberValue / _amount)}'
                              : 'Ex.: 10 para 10x',
                    ),
                  ),
                  if (_cards.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _cards.any((c) => c.id == _creditCardId)
                          ? _creditCardId
                          : 0,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Foi no cartão de crédito?',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                        helperText:
                            'No cartão, as parcelas caem nas faturas certas.',
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: 0,
                            child: Text('Não (boleto, carnê, empréstimo)')),
                        ..._cards.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (id) {
                        _paymentDataChanged();
                        setState(() => _creditCardId = id ?? 0);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed:
                        _canGenerate && !_isGenerating ? _generate : null,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.autorenew_rounded),
                    label: const Text('Gerar parcelas'),
                  ),
                  if (!_installmentsUpdated && _installments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TipCard(
                      icon: Icons.warning_amber_rounded,
                      title: 'Gere as parcelas de novo',
                      message: _id > 0
                          ? 'Você mudou os dados acima. Ao gerar de novo, os '
                              'pagamentos já marcados serão apagados.'
                          : 'Você mudou os dados acima: gere as parcelas de '
                              'novo antes de salvar.',
                      isWarning: true,
                    ),
                  ],
                  const _StepTitle(number: 3, title: 'Parcelas'),
                  if (_installments.isEmpty)
                    Text(
                        'Preencha a etapa 2 e toque em "Gerar parcelas" para '
                        'ver cada mês.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant))
                  else ...[
                    Text(
                        '"Paguei" considera o valor e a data de vencimento. '
                        'Pagou diferente? Toque na parcela para ajustar. As '
                        'mudanças só valem depois de salvar.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 8),
                    ..._installments.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _InstallmentTile(
                            installment: p,
                            onTap: () => _editInstallment(p),
                            onPaid: () => _replaceInstallment(p.withPayment(
                                paidValue: p.value, paidDate: p.date)),
                            onExempt: () => _replaceInstallment(
                                p.withPayment(exempt: true)),
                          ),
                        )),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : BottomActionBar(
              label: 'Salvar parcelamento',
              isLoading: _isSaving,
              onPressed: _save),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({Key? key, required this.number, required this.title})
      : super(key: key);

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            child: Text('$number',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile(
      {Key? key,
      required this.installment,
      required this.onTap,
      required this.onPaid,
      required this.onExempt})
      : super(key: key);

  final InstallmentModel installment;
  final VoidCallback onTap;
  final VoidCallback onPaid;
  final VoidCallback onExempt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = installment;
    final subtle =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    final status = p.exempt
        ? const StatusChip('Isenta', tone: StatusTone.inactive)
        : p.paidDate != null
            ? const StatusChip('Paga', tone: StatusTone.done)
            : const StatusChip('A pagar', tone: StatusTone.pending);

    return V2Card(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleIcon(Icons.tag_rounded, color: scheme.tertiary, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parcela ${p.number}',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                        'Vence em ${toDateString(value: p.date, separator: '/')}',
                        style: subtle),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(money(p.value),
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    status,
                    if (p.paidDate != null && !p.exempt) ...[
                      const SizedBox(height: 2),
                      Text(
                          '${money(p.paidValue ?? 0)} em '
                          '${toDateString(value: p.paidDate, separator: '/')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subtle),
                    ],
                  ],
                ),
              ),
              if (!p.isSettled) ...[
                IconButton(
                  tooltip: 'Isentar (não precisa pagar)',
                  visualDensity: VisualDensity.compact,
                  onPressed: onExempt,
                  icon: const Icon(Icons.do_not_disturb_on_outlined),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12)),
                  onPressed: onPaid,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Paguei'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Ajusta o pagamento de uma parcela: valor pago e data, ou isenção.
class _InstallmentDialog extends StatefulWidget {
  const _InstallmentDialog({Key? key, required this.installment})
      : super(key: key);

  final InstallmentModel installment;

  @override
  State<_InstallmentDialog> createState() => _InstallmentDialogState();
}

class _InstallmentDialogState extends State<_InstallmentDialog> {
  final _valueController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  late bool _exempt = widget.installment.exempt;
  late DateTime? _paidDate = widget.installment.paidDate;

  @override
  void initState() {
    super.initState();
    _valueController.updateValue(widget.installment.paidValue ?? 0);
    _valueController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  /// Valor pago e data de pagamento andam juntos: ou os dois, ou nenhum.
  bool get _isInvalid =>
      !_exempt && ((_paidDate != null) != (_valueController.numberValue > 0));

  void _apply() {
    final paidValue = _valueController.numberValue;
    Navigator.pop(
        context,
        widget.installment.withPayment(
            paidValue: paidValue > 0 ? paidValue : null,
            paidDate: _paidDate,
            exempt: _exempt));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.installment;

    return AlertDialog(
      title: Text('Parcela nº ${p.number}'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Vence em ${toDateString(value: p.date, separator: '/')} · '
              '${money(p.value)}',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Isentar esta parcela'),
            subtitle: const Text('Foi perdoada, cancelada ou estornada.'),
            value: _exempt,
            onChanged: (value) => setState(() => _exempt = value),
          ),
          if (!_exempt) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor pago',
                helperText:
                    'Pagou com desconto ou juros? Coloque o valor real.',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 12),
            DateFormField(
              label: 'Data do pagamento',
              value: _paidDate,
              clearable: true,
              onChanged: (date) => setState(() => _paidDate = date),
            ),
          ],
          if (_isInvalid) ...[
            const SizedBox(height: 12),
            Text(
                'Preencha o valor pago e a data juntos (ou deixe os dois '
                'vazios).',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
          onPressed: _isInvalid ? null : _apply,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
