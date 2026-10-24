import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/earning/earning_model.dart';
import 'package:cashflow_app/src/models/type_model.dart';
import 'package:cashflow_app/src/services/earning.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/flutter_masked_text.dart';
import 'package:flutter/material.dart';

/// Formulário de ganho avulso. Recebe o [EarningModel] a editar como
/// argumento da rota; sem argumento, cria um novo.
class EarningDetailV2Screen extends StatelessWidget {
  const EarningDetailV2Screen({Key? key, this.loadTypes}) : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final Future<List<TypeModel>> Function(BuildContext context)? loadTypes;

  @override
  Widget build(BuildContext context) {
    return V2Theme(child: _EarningDetailV2Body(loadTypes: loadTypes));
  }
}

class _EarningDetailV2Body extends StatefulWidget {
  const _EarningDetailV2Body({Key? key, required this.loadTypes})
      : super(key: key);

  final Future<List<TypeModel>> Function(BuildContext context)? loadTypes;

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
  int _type = defaultEarningTypeId;
  List<TypeModel> _types = [];
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
      _type = earning.type;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTypes());
  }

  Future<void> _loadTypes() async {
    try {
      final types = await (widget.loadTypes ??
          (BuildContext c) => EarningService(c).getTypes())(context);
      if (mounted) setState(() => _types = types);
    } catch (error) {
      if (mounted) handleHttpException(error, context);
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
        date: _date!,
        type: _type);

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
            if (_types.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _types.any((t) => t.id == _type) ? _type : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de ganho',
                  prefixIcon: Icon(Icons.category_outlined),
                  helperText: 'Separar por tipo mostra quanto vem do seu '
                      'trabalho e quanto vem do seu patrimônio.',
                  helperMaxLines: 2,
                ),
                items: _types
                    .map((t) => DropdownMenuItem(
                        value: t.id, child: Text(t.description)))
                    .toList(),
                onChanged: (id) =>
                    setState(() => _type = id ?? defaultEarningTypeId),
                validator: (id) =>
                    id == null ? 'Escolha o tipo do ganho' : null,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
          label: 'Salvar', isLoading: _isSaving, onPressed: _save),
    );
  }
}
