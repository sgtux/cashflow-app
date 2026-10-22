import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/credit-card/credit_card_model.dart';
import 'package:cashflow_app/src/models/recurring/recurring_model.dart';
import 'package:cashflow_app/src/pages/recurring/recurring_texts.dart';
import 'package:cashflow_app/src/services/credit_card.service.dart';
import 'package:cashflow_app/src/services/recurring.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/flutter_masked_text.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

/// Formulário de ganho fixo ou conta fixa, com o histórico mês a mês.
/// Recebe o [RecurringModel] como argumento da rota (com `id` 0 para criar).
class RecurringDetailV2Screen extends StatelessWidget {
  const RecurringDetailV2Screen({Key? key, this.loadCreditCards})
      : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final Future<List<CreditCardModel>> Function(BuildContext context)?
      loadCreditCards;

  @override
  Widget build(BuildContext context) {
    return V2Theme(
        child: _RecurringDetailV2Body(loadCreditCards: loadCreditCards));
  }
}

class _RecurringDetailV2Body extends StatefulWidget {
  const _RecurringDetailV2Body({Key? key, required this.loadCreditCards})
      : super(key: key);

  final Future<List<CreditCardModel>> Function(BuildContext context)?
      loadCreditCards;

  @override
  State<_RecurringDetailV2Body> createState() => _RecurringDetailV2BodyState();
}

class _RecurringDetailV2BodyState extends State<_RecurringDetailV2Body> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');

  late RecurringModel _item;
  List<CreditCardModel> _cards = [];
  int _creditCardId = 0;
  DateTime? _inactiveAt;
  bool _initialized = false;
  bool _isSaving = false;

  RecurringKind get _kind => _item.kind;
  RecurringTexts get _texts => RecurringTexts.of(_kind);
  bool get _isEditing => _item.id > 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _item = ModalRoute.of(context)!.settings.arguments as RecurringModel;
    _descriptionController.text = _item.description;
    _valueController.updateValue(_item.value);
    _creditCardId = _item.creditCardId ?? 0;
    _inactiveAt = _item.inactiveAt;
    if (_kind == RecurringKind.expense) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCards());
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await (widget.loadCreditCards ??
          (BuildContext c) => CreditCardService(c).getAll())(context);
      if (mounted) setState(() => _cards = cards);
    } catch (error) {
      // Sem os cartões o formulário ainda funciona, só não oferece a opção.
      debugPrint('[${_texts.title}] Erro ao carregar cartões: $error');
    }
  }

  Future<void> _reloadItem() async {
    try {
      final item = await RecurringService(context, _kind).getById(_item.id);
      if (mounted && item != null) setState(() => _item = item);
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final model = RecurringModel(
      kind: _kind,
      id: _item.id,
      description: _descriptionController.text.trim(),
      value: _valueController.numberValue,
      inactiveAt: _inactiveAt,
      creditCardId: _creditCardId > 0 ? _creditCardId : null,
    );

    setState(() => _isSaving = true);
    try {
      final result = await RecurringService(context, _kind).save(model);
      if (mounted && result.isValid()) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editHistory([RecurringHistoryModel? history]) async {
    final saved = await showDialog<RecurringHistoryModel>(
      context: context,
      builder: (_) => _HistoryDialog(
        texts: _texts,
        history: history ??
            RecurringHistoryModel(
                kind: _kind,
                id: 0,
                parentId: _item.id,
                value: _item.value,
                date: DateTime.now()),
      ),
    );
    if (saved == null || !mounted) return;

    try {
      final result = await RecurringService(context, _kind).saveHistory(saved);
      if (!mounted || !result.isValid()) return;
      showSuccess(context, 'Histórico salvo!');
      await _reloadItem();
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    }
  }

  Future<bool> _deleteHistory(RecurringHistoryModel history) async {
    try {
      final result =
          await RecurringService(context, _kind).removeHistory(history);
      return result.isValid();
    } catch (error) {
      if (mounted) handleHttpException(error, context);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color =
        _kind == RecurringKind.earning ? inColor(scheme) : outColor(scheme);

    return Scaffold(
      appBar:
          AppBar(title: Text(_isEditing ? _texts.editTitle : _texts.newTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: _texts.descriptionLabel,
                hintText: _texts.descriptionHint,
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _texts.valueLabel,
                helperText: _texts.valueHelper,
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: (_) => _valueController.numberValue <= 0
                  ? 'Informe um valor maior que zero'
                  : null,
            ),
            if (_cards.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _cards.any((c) => c.id == _creditCardId)
                    ? _creditCardId
                    : 0,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'É cobrada no cartão de crédito?',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                  helperText: 'Se for no cartão, o valor entra na fatura dele.',
                ),
                items: [
                  const DropdownMenuItem(
                      value: 0,
                      child: Text('Não, pago por fora (boleto, Pix, débito)')),
                  ..._cards.map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (id) => setState(() => _creditCardId = id ?? 0),
              ),
            ],
            if (_isEditing) ...[
              const SizedBox(height: 12),
              DateFormField(
                label: _texts.inactiveAtLabel,
                value: _inactiveAt,
                clearable: true,
                helperText: _texts.inactiveAtHelper,
                onChanged: (date) => setState(() => _inactiveAt = date),
              ),
              SectionTitle(
                _texts.historyTitle,
                trailing: TextButton.icon(
                  onPressed: () => _editHistory(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar'),
                ),
              ),
              if (_item.history.isEmpty)
                Text(_texts.historyEmpty,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant))
              else ...[
                Text('Toque para editar. Deslize para a esquerda para excluir.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                ..._item.history.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SwipeToDelete(
                        key: ValueKey('history-${h.id}'),
                        confirmTitle: 'Remover este registro?',
                        confirmMessage:
                            'Registro de ${toDateString(value: h.date, separator: '/')} '
                            'será apagado do histórico.',
                        onDelete: () => _deleteHistory(h),
                        onDeleted: () =>
                            setState(() => _item.history.remove(h)),
                        child: V2Card(
                          onTap: () => _editHistory(h),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                    toDateString(value: h.date, separator: '/'),
                                    style: theme.textTheme.bodyLarge),
                              ),
                              Text(money(h.value),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
          label: 'Salvar', isLoading: _isSaving, onPressed: _save),
    );
  }
}

/// Adiciona ou edita um registro do histórico (valor e data).
class _HistoryDialog extends StatefulWidget {
  const _HistoryDialog({Key? key, required this.texts, required this.history})
      : super(key: key);

  final RecurringTexts texts;
  final RecurringHistoryModel history;

  @override
  State<_HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<_HistoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  late DateTime? _date = widget.history.date;

  @override
  void initState() {
    super.initState();
    _valueController.updateValue(widget.history.value);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final h = widget.history;
    Navigator.pop(
        context,
        RecurringHistoryModel(
            kind: h.kind,
            id: h.id,
            parentId: h.parentId,
            value: _valueController.numberValue,
            date: _date!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.history.id > 0 ? 'Editar registro' : 'Novo registro'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.texts.historyValueLabel,
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: (_) => _valueController.numberValue <= 0
                  ? 'Informe um valor maior que zero'
                  : null,
            ),
            const SizedBox(height: 12),
            DateFormField(
              label: 'Data',
              value: _date,
              helperText: 'Só pode haver um registro por mês.',
              onChanged: (date) => setState(() => _date = date),
              validator: (date) => date == null ? 'Informe a data' : null,
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
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
