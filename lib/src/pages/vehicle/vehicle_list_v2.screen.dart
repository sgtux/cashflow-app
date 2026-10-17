import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/vehicle/vehicle.model.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_list_v2.screen.dart';
import 'package:cashflow_app/src/services/vehicle.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';

/// Nova lista de veículos: quilometragem, consumo e quanto cada quilômetro
/// custa em combustível.
class VehicleListV2Screen extends StatelessWidget {
  const VehicleListV2Screen({Key? key, this.loadVehicles}) : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final VehiclesLoader? loadVehicles;

  @override
  Widget build(BuildContext context) {
    return V2Theme(child: _VehicleListV2Body(loadVehicles: loadVehicles));
  }
}

class _VehicleListV2Body extends StatefulWidget {
  const _VehicleListV2Body({Key? key, required this.loadVehicles})
      : super(key: key);

  final VehiclesLoader? loadVehicles;

  @override
  State<_VehicleListV2Body> createState() => _VehicleListV2BodyState();
}

class _VehicleListV2BodyState extends State<_VehicleListV2Body> {
  List<VehicleModel> _vehicles = [];
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
          widget.loadVehicles ?? (BuildContext c) => VehicleService(c).getAll();
      final vehicles = await loader(context);
      if (mounted) setState(() => _vehicles = vehicles);
    } catch (error, stackTrace) {
      debugPrint('[Veículos] Erro: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _hasError = true);
      handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetail([VehicleModel? vehicle]) async {
    await Navigator.pushNamed(context, Routes.vehicleDetail,
        arguments: vehicle);
    if (mounted) _load();
  }

  Future<void> _delete(VehicleModel vehicle) async {
    final confirmed = await confirmDelete(context,
        title: 'Excluir este veículo?',
        message: '${vehicle.description} e seus abastecimentos deixarão de '
            'aparecer no app.');
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await VehicleService(context).remove(vehicle.id);
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    }
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            const ScreenTitle(
              title: 'Veículos',
              subtitle: 'Saiba quanto seu veículo consome e custa por km.',
            ),
            const SizedBox(height: 16),
            ..._buildContent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDetail(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo veículo'),
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
            title: 'Não foi possível carregar os veículos', onRetry: _load),
      ];
    }

    if (_vehicles.isEmpty) {
      return const [
        MessageCard(
          icon: Icons.directions_car_rounded,
          title: 'Nenhum veículo cadastrado',
          message: 'Cadastre seu carro ou moto para acompanhar abastecimentos, '
              'consumo e o custo de cada quilômetro.',
        ),
      ];
    }

    return [
      ..._vehicles.map((vehicle) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _VehicleCard(
              vehicle: vehicle,
              onEdit: () => _openDetail(vehicle),
              onDelete: () => _delete(vehicle),
            ),
          )),
      const SizedBox(height: 4),
      const TipCard(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Para que serve o custo por km?',
        message: 'Ele mostra quanto você gasta de combustível a cada '
            'quilômetro. Compare com transporte público ou aplicativos para '
            'decidir o que vale mais a pena em cada trajeto.',
      ),
    ];
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard(
      {Key? key,
      required this.vehicle,
      required this.onEdit,
      required this.onDelete})
      : super(key: key);

  final VehicleModel vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fuels = vehicle.fuelExpenses;
    final totalSpent = fuels.fold<num>(0, (sum, f) => sum + f.valueSupplied);
    final costPerKm = vehicle.miliageTraveled > 0
        ? totalSpent / vehicle.miliageTraveled
        : null;

    return V2Card(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleIcon(Icons.directions_car_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                        '${fuels.length} ${fuels.length == 1 ? 'abastecimento' : 'abastecimentos'}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                        contentPadding: EdgeInsets.zero),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Excluir'),
                        contentPadding: EdgeInsets.zero),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatBox(
                    label: 'Km rodados',
                    value: '${number(vehicle.miliageTraveled)} km'),
                _StatBox(
                    label: 'Consumo médio',
                    value: vehicle.miliagePerLiter > 0
                        ? '${number(vehicle.miliagePerLiter, decimals: 1)} km/l'
                        : '—'),
                _StatBox(label: 'Gasto total', value: money(totalSpent)),
                _StatBox(
                    label: 'Custo por km',
                    value: costPerKm == null ? '—' : money(costPerKm)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({Key? key, required this.label, required this.value})
      : super(key: key);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      // Dois por linha, ocupando a largura disponível.
      final width = (constraints.maxWidth - 8) / 2;
      return Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }
}
