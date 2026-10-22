import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/credit-card/credit_card_model.dart';
import 'package:cashflow_app/src/models/vehicle/fuel_expense.model.dart';
import 'package:cashflow_app/src/models/vehicle/vehicle.model.dart';
import 'package:cashflow_app/src/services/credit_card.service.dart';
import 'package:cashflow_app/src/services/fuel_expense.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/flutter_masked_text.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Novo formulário de abastecimento. Recebe pela rota um mapa com
/// `vehicles` (`List<VehicleModel>`) e `fuelExpenseModel` (`FuelExpenseModel`).
class FuelExpenseDetailV2Screen extends StatelessWidget {
  const FuelExpenseDetailV2Screen({Key? key, this.loadCreditCards})
      : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final Future<List<CreditCardModel>> Function(BuildContext context)?
      loadCreditCards;

  @override
  Widget build(BuildContext context) {
    return V2Theme(
        child: _FuelExpenseDetailV2Body(loadCreditCards: loadCreditCards));
  }
}

class _FuelExpenseDetailV2Body extends StatefulWidget {
  const _FuelExpenseDetailV2Body({Key? key, required this.loadCreditCards})
      : super(key: key);

  final Future<List<CreditCardModel>> Function(BuildContext context)?
      loadCreditCards;

  @override
  State<_FuelExpenseDetailV2Body> createState() =>
      _FuelExpenseDetailV2BodyState();
}

class _FuelExpenseDetailV2BodyState extends State<_FuelExpenseDetailV2Body> {
  final _formKey = GlobalKey<FormState>();
  final _miliageController = TextEditingController();
  final _pricePerLiterController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  final _valueSuppliedController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  final _dateController = TextEditingController();

  FuelExpenseModel? _fuel;
  List<VehicleModel> _vehicles = [];
  VehicleModel? _selectedVehicle;
  List<CreditCardModel> _cards = [];
  int _creditCardId = 0;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  bool get _isEditing => (_fuel?.id ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _pricePerLiterController.addListener(_refreshLiters);
    _valueSuppliedController.addListener(_refreshLiters);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCreditCards());
  }

  /// Sem os cartões o formulário ainda funciona, só não oferece a opção.
  Future<void> _loadCreditCards() async {
    try {
      final cards = await (widget.loadCreditCards ??
          (BuildContext c) => CreditCardService(c).getAll())(context);
      if (mounted) setState(() => _cards = cards);
    } catch (error) {
      debugPrint('[Abastecimento] Erro ao carregar cartões: $error');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fuel != null) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final fuel = args?['fuelExpenseModel'] as FuelExpenseModel?;
    final vehicles = (args?['vehicles'] as List?)?.cast<VehicleModel>() ?? [];
    if (fuel == null) return;

    _fuel = fuel;
    _vehicles = vehicles;
    final matches = vehicles.where((v) => v.id == fuel.vehicleId);
    _selectedVehicle = matches.isNotEmpty
        ? matches.first
        : (vehicles.isNotEmpty ? vehicles.first : null);
    _miliageController.text = fuel.miliage > 0 ? fuel.miliage.toString() : '';
    _pricePerLiterController.updateValue(fuel.pricePerLiter.toDouble());
    _valueSuppliedController.updateValue(fuel.valueSupplied.toDouble());
    _creditCardId = fuel.creditCardId ?? 0;
    _setDate(fuel.date);
  }

  @override
  void dispose() {
    _miliageController.dispose();
    _pricePerLiterController.dispose();
    _valueSuppliedController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _refreshLiters() => setState(() {});

  void _setDate(DateTime date) {
    _date = date;
    _dateController.text = toDateString(value: date, separator: '/');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 4),
      lastDate: DateTime(now.year + 2),
    );
    if (date != null) setState(() => _setDate(date));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final model = FuelExpenseModel(
      id: _fuel!.id,
      vehicleId: _selectedVehicle!.id,
      miliage: int.parse(_miliageController.text),
      pricePerLiter: _pricePerLiterController.numberValue,
      valueSupplied: _valueSuppliedController.numberValue,
      date: _date,
      vehicleName: _selectedVehicle!.description,
      creditCardId: _creditCardId > 0 ? _creditCardId : null,
    );

    setState(() => _isSaving = true);
    try {
      final result = await FuelExpenseService(context).save(model);
      if (mounted && result.isValid()) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = _pricePerLiterController.numberValue;
    final value = _valueSuppliedController.numberValue;
    final liters = price > 0 && value > 0 ? value / price : null;

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Editar abastecimento' : 'Abastecimento')),
      body: _fuel == null
          ? const Center(child: Text('Abastecimento não encontrado.'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<VehicleModel>(
                    initialValue: _selectedVehicle,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Veículo',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                    ),
                    items: _vehicles
                        .map((v) => DropdownMenuItem(
                            value: v, child: Text(v.description)))
                        .toList(),
                    onChanged: (vehicle) =>
                        setState(() => _selectedVehicle = vehicle),
                    validator: (vehicle) =>
                        vehicle == null ? 'Escolha o veículo' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _miliageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Quilometragem do painel',
                      suffixText: 'km',
                      prefixIcon: Icon(Icons.speed_outlined),
                    ),
                    validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                        ? 'Informe a quilometragem'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pricePerLiterController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Preço por litro',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    validator: (_) => _pricePerLiterController.numberValue <= 0
                        ? 'Informe o preço por litro'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valueSuppliedController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Valor abastecido',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      helperText: liters == null
                          ? null
                          : 'Aproximadamente ${number(liters, decimals: 1)} litros',
                    ),
                    validator: (_) => _valueSuppliedController.numberValue <= 0
                        ? 'Informe o valor abastecido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  if (_cards.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    CreditCardField(
                      cards: _cards,
                      value: _creditCardId,
                      onChanged: (id) => setState(() => _creditCardId = id),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const TipCard(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Dica',
                    message: 'Anote a quilometragem do painel em todo '
                        'abastecimento. É com ela que o app calcula quantos '
                        'km seu veículo faz por litro.',
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _fuel == null
          ? null
          : BottomActionBar(
              label: 'Salvar', isLoading: _isSaving, onPressed: _save),
    );
  }
}
