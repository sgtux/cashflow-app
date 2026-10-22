import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/credit-card/credit_card_model.dart';
import 'package:cashflow_app/src/services/credit_card.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formulário de cartão de crédito: nome e dias de fechamento e vencimento.
/// Recebe o [CreditCardModel] a editar como argumento da rota.
class CreditCardDetailV2Screen extends StatelessWidget {
  const CreditCardDetailV2Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const V2Theme(child: _CreditCardDetailV2Body());
  }
}

class _CreditCardDetailV2Body extends StatefulWidget {
  const _CreditCardDetailV2Body({Key? key}) : super(key: key);

  @override
  State<_CreditCardDetailV2Body> createState() =>
      _CreditCardDetailV2BodyState();
}

class _CreditCardDetailV2BodyState extends State<_CreditCardDetailV2Body> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _closingDayController = TextEditingController();
  final _dueDayController = TextEditingController();

  int _id = 0;
  bool _initialized = false;
  bool _isSaving = false;

  int get _closingDay => int.tryParse(_closingDayController.text) ?? 0;
  int get _dueDay => int.tryParse(_dueDayController.text) ?? 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final card = ModalRoute.of(context)?.settings.arguments as CreditCardModel?;
    if (card != null) {
      _id = card.id;
      _nameController.text = card.name;
      _closingDayController.text = '${card.invoiceClosingDay}';
      _dueDayController.text = '${card.invoiceDueDay}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _closingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  String? _validateDay(String? value) {
    final day = int.tryParse(value ?? '') ?? 0;
    return day < 1 || day > 30 ? 'Informe um dia de 1 a 30' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final model = CreditCardModel(
        id: _id,
        name: _nameController.text.trim(),
        invoiceClosingDay: _closingDay,
        invoiceDueDay: _dueDay);

    setState(() => _isSaving = true);
    try {
      final result = await CreditCardService(context).save(model);
      if (mounted && result.isValid()) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDays = _closingDay > 0 && _dueDay > 0;

    return Scaffold(
      appBar: AppBar(
          title: Text(_id > 0 ? 'Editar cartão' : 'Novo cartão de crédito')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ScreenIntro('Essas datas estão no aplicativo do banco ou na '
                'própria fatura.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome do cartão',
                hintText: 'Ex.: Nubank, Itaú Visa',
                prefixIcon: Icon(Icons.credit_card_outlined),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Informe o nome do cartão'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _closingDayController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Dia do fechamento',
                      hintText: 'Ex.: 5',
                    ),
                    validator: _validateDay,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dueDayController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Dia do vencimento',
                      hintText: 'Ex.: 15',
                    ),
                    validator: _validateDay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TipCard(
              icon: Icons.info_outline_rounded,
              title: 'Fechamento e vencimento',
              message: 'Fechamento: depois desse dia, as compras vão para a '
                  'fatura do mês seguinte.\nVencimento: último dia para pagar '
                  'sem juros.'
                  '${hasDays ? '\n\nExemplo: uma compra no dia ${_closingDay >= 30 ? 30 : _closingDay + 1} '
                      'só será paga no vencimento do dia $_dueDay do mês '
                      'seguinte.' : ''}',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
          label: 'Salvar', isLoading: _isSaving, onPressed: _save),
    );
  }
}
