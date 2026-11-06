import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/recurring/recurring_model.dart';
import 'package:cashflow_app/src/pages/recurring/recurring_texts.dart';
import 'package:cashflow_app/src/utils/flutter_masked_text.dart';
import 'package:flutter/material.dart';

/// Adiciona ou edita um registro do histórico (valor e data). Devolve o
/// registro preenchido ou `null` se o usuário cancelar.
class RecurringHistoryDialog extends StatefulWidget {
  const RecurringHistoryDialog(
      {Key? key,
      required this.texts,
      required this.history,
      this.title,
      this.subtitle,
      this.valueHelper,
      this.dateLabel = 'Data',
      this.dateHelper = 'Só pode haver um registro por mês.',
      this.saveLabel = 'Salvar'})
      : super(key: key);

  final RecurringTexts texts;
  final RecurringHistoryModel history;
  final String? title;
  final String? subtitle;
  final String? valueHelper;
  final String dateLabel;
  final String? dateHelper;
  final String saveLabel;

  @override
  State<RecurringHistoryDialog> createState() => _RecurringHistoryDialogState();
}

class _RecurringHistoryDialogState extends State<RecurringHistoryDialog> {
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
    final theme = Theme.of(context);
    final title = widget.title ??
        (widget.history.id > 0 ? 'Editar registro' : 'Novo registro');

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((widget.subtitle ?? '').isNotEmpty) ...[
              Text(widget.subtitle!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.texts.historyValueLabel,
                helperText: widget.valueHelper,
                helperMaxLines: 3,
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: (_) => _valueController.numberValue <= 0
                  ? 'Informe um valor maior que zero'
                  : null,
            ),
            const SizedBox(height: 12),
            DateFormField(
              label: widget.dateLabel,
              value: _date,
              helperText: widget.dateHelper,
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
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}
