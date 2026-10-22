import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/earning/earning_model.dart';
import 'package:cashflow_app/src/services/earning.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/flutter_masked_text.dart';
import 'package:flutter/material.dart';

/// Formulário de ganho avulso. Recebe o [EarningModel] a editar como
/// argumento da rota; sem argumento, cria um novo.
class EarningDetailV2Screen extends StatelessWidget {
  const EarningDetailV2Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const V2Theme(child: _EarningDetailV2Body());
  }
}

class _EarningDetailV2Body extends StatefulWidget {
  const _EarningDetailV2Body({Key? key}) : super(key: key);

  @override
  State<_EarningDetailV2Body> createState() => _EarningDetailV2BodyState();
}

class _EarningDetailV2BodyState extends State<_EarningDetailV2Body> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');

  int _id = 0;
  DateTime? _date = DateTime.now();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final earning = ModalRoute.of(context)?.settings.arguments as EarningModel?;
    if (earning != null) {
      _id = earning.id;
      _descriptionController.text = earning.description;
      _valueController.updateValue(earning.value);
      _date = earning.date;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final model = EarningModel(
        id: _id,
        description: _descriptionController.text.trim(),
        value: _valueController.numberValue,
        date: _date!);

    setState(() => _isSaving = true);
    try {
      final result = await EarningService(context).save(model);
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
      appBar: AppBar(title: Text(_id > 0 ? 'Editar ganho' : 'Novo ganho')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ScreenIntro(
                'Registre qualquer dinheiro que entrou para você.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'De onde veio?',
                hintText: 'Ex.: Freela de design, venda da bicicleta',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Informe de onde veio o dinheiro'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quanto entrou?',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (_) => _valueController.numberValue <= 0
                  ? 'Informe um valor maior que zero'
                  : null,
            ),
            const SizedBox(height: 12),
            DateFormField(
              label: 'Quando entrou?',
              value: _date,
              helperText: 'A data em que o dinheiro caiu na sua conta.',
              onChanged: (date) => setState(() => _date = date),
              validator: (date) => date == null ? 'Informe a data' : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
          label: 'Salvar', isLoading: _isSaving, onPressed: _save),
    );
  }
}
