import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/vehicle/vehicle.model.dart';
import 'package:cashflow_app/src/services/vehicle.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';

/// Novo formulário de veículo.
class VehicleDetailV2Screen extends StatelessWidget {
  const VehicleDetailV2Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const V2Theme(child: _VehicleDetailV2Body());
  }
}

class _VehicleDetailV2Body extends StatefulWidget {
  const _VehicleDetailV2Body({Key? key}) : super(key: key);

  @override
  State<_VehicleDetailV2Body> createState() => _VehicleDetailV2BodyState();
}

class _VehicleDetailV2BodyState extends State<_VehicleDetailV2Body> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  VehicleModel? _vehicle;
  bool _isSaving = false;

  bool get _isEditing => (_vehicle?.id ?? 0) > 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vehicle != null) return;
    _vehicle = ModalRoute.of(context)?.settings.arguments as VehicleModel? ??
        VehicleModel(
            id: 0,
            description: '',
            fuelExpenses: [],
            miliagePerLiter: 0,
            miliageTraveled: 0);
    _descriptionController.text = _vehicle!.description;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final model = VehicleModel(
        id: _vehicle!.id,
        description: _descriptionController.text.trim(),
        fuelExpenses: [],
        miliageTraveled: 0,
        miliagePerLiter: 0);

    setState(() => _isSaving = true);
    try {
      await VehicleService(context).save(model);
      if (mounted) Navigator.of(context).pop(true);
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
          AppBar(title: Text(_isEditing ? 'Editar veículo' : 'Novo veículo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descriptionController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Nome do veículo',
                hintText: 'Ex.: Onix 2020, Moto CG',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Informe um nome para o veículo'
                  : null,
            ),
            const SizedBox(height: 20),
            const TipCard(
              icon: Icons.lightbulb_outline_rounded,
              title: 'O que acontece depois',
              message: 'Com o veículo cadastrado, registre os abastecimentos '
                  'na aba Combustível. O app calcula a quilometragem, o '
                  'consumo médio e o custo por km automaticamente.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
          label: 'Salvar', isLoading: _isSaving, onPressed: _save),
    );
  }
}
