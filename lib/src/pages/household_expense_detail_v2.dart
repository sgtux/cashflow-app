import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/household-expense/household_expense_model.dart';
import 'package:cashflow_app/src/models/type_model.dart';
import 'package:cashflow_app/src/models/vehicle/vehicle.model.dart';
import 'package:cashflow_app/src/services/household_expense.service.dart';
import 'package:cashflow_app/src/services/vehicle.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/flutter_masked_text.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

/// Tipo de despesa que exige escolher um veículo.
const int vehicleExpenseTypeId = 6;

/// Tipo usado por padrão em uma nova despesa.
const int defaultExpenseTypeId = 20;

/// Novo formulário de despesa doméstica.
class HouseholdExpenseDetailV2 extends StatelessWidget {
  const HouseholdExpenseDetailV2({Key? key, this.loadTypes, this.loadVehicles})
      : super(key: key);

  /// Permitem substituir a busca na API (usados nos testes).
  final Future<List<TypeModel>> Function(BuildContext context)? loadTypes;
  final Future<List<VehicleModel>> Function(BuildContext context)? loadVehicles;

  @override
  Widget build(BuildContext context) {
    return V2Theme(
      child: _HouseholdExpenseDetailV2Body(
          loadTypes: loadTypes, loadVehicles: loadVehicles),
    );
  }
}

class _HouseholdExpenseDetailV2Body extends StatefulWidget {
  const _HouseholdExpenseDetailV2Body(
      {Key? key, required this.loadTypes, required this.loadVehicles})
      : super(key: key);

  final Future<List<TypeModel>> Function(BuildContext context)? loadTypes;
  final Future<List<VehicleModel>> Function(BuildContext context)? loadVehicles;

  @override
  State<_HouseholdExpenseDetailV2Body> createState() =>
      _HouseholdExpenseDetailV2BodyState();
}

class _HouseholdExpenseDetailV2BodyState
    extends State<_HouseholdExpenseDetailV2Body> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  final _dateController = TextEditingController();

  HouseholdExpenseModel? _expense;
  DateTime _date = DateTime.now();
  List<TypeModel> _types = [];
  List<VehicleModel> _vehicles = [];
  TypeModel? _selectedType;
  VehicleModel? _selectedVehicle;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditing => (_expense?.id ?? 0) > 0;

  bool get _needsVehicle =>
      _selectedType?.id == vehicleExpenseTypeId && _vehicles.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final expense =
        ModalRoute.of(context)?.settings.arguments as HouseholdExpenseModel? ??
            HouseholdExpenseModel(
                id: 0,
                description: '',
                date: DateTime.now(),
                value: 0,
                type: defaultExpenseTypeId);

    try {
      final typesTask = (widget.loadTypes ??
          (BuildContext c) => HouseholdExpenseService(c).getTypes())(context);
      final vehiclesTask = (widget.loadVehicles ??
          (BuildContext c) => VehicleService(c).getAll())(context);
      final types = await typesTask;
      final vehicles = await vehiclesTask;
      if (!mounted) return;

      _descriptionController.text = expense.description;
      _valueController.updateValue(expense.value);
      _setDate(expense.date);

      setState(() {
        _expense = expense;
        _types = types;
        _vehicles = vehicles;
        _selectedType = _firstOrNull(types.where((t) => t.id == expense.type));
        _selectedVehicle =
            _firstOrNull(vehicles.where((v) => v.id == expense.vehicleId));
      });
    } catch (error, stackTrace) {
      debugPrint('[Despesa] Erro: $error\n$stackTrace');
      if (mounted) handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  T? _firstOrNull<T>(Iterable<T> items) => items.isEmpty ? null : items.first;

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

    final model = HouseholdExpenseModel(
      id: _expense!.id,
      description: _descriptionController.text.trim(),
      value: _valueController.numberValue,
      date: _date,
      type: _selectedType!.id,
      vehicleId: _needsVehicle ? _selectedVehicle?.id : null,
    );

    setState(() => _isSaving = true);
    try {
      final result = await HouseholdExpenseService(context).save(model);
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
      appBar:
          AppBar(title: Text(_isEditing ? 'Editar despesa' : 'Nova despesa')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex.: Mercado, conta de luz',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Informe uma descrição'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (_) => _valueController.numberValue <= 0
                        ? 'Informe um valor maior que zero'
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TypeModel>(
                    initialValue: _selectedType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _types
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.description)))
                        .toList(),
                    onChanged: (type) => setState(() => _selectedType = type),
                    validator: (type) =>
                        type == null ? 'Escolha o tipo da despesa' : null,
                  ),
                  if (_needsVehicle) ...[
                    const SizedBox(height: 12),
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
                  ],
                  const SizedBox(height: 20),
                  const TipCard(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Dica',
                    message: 'Escolher o tipo certo ajuda a ver, no resumo de '
                        'despesas, onde dá para economizar.',
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : BottomActionBar(
              label: 'Salvar', isLoading: _isSaving, onPressed: _save),
    );
  }
}
