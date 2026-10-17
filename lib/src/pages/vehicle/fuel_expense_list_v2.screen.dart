import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/vehicle/fuel_expense.model.dart';
import 'package:cashflow_app/src/models/vehicle/vehicle.model.dart';
import 'package:cashflow_app/src/services/fuel_expense.service.dart';
import 'package:cashflow_app/src/services/vehicle.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';

typedef VehiclesLoader = Future<List<VehicleModel>> Function(
    BuildContext context);

/// Litros abastecidos, calculados a partir do valor e do preço por litro.
num litersOf(FuelExpenseModel fuel) =>
    fuel.pricePerLiter == 0 ? 0 : fuel.valueSupplied / fuel.pricePerLiter;

/// Nova lista de abastecimentos: gasto do mês, consumo médio, filtro por
/// veículo e histórico agrupado por mês.
class FuelExpenseListV2Screen extends StatelessWidget {
  const FuelExpenseListV2Screen({Key? key, this.loadVehicles})
      : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final VehiclesLoader? loadVehicles;

  @override
  Widget build(BuildContext context) {
    return V2Theme(child: _FuelExpenseListV2Body(loadVehicles: loadVehicles));
  }
}

class _FuelExpenseListV2Body extends StatefulWidget {
  const _FuelExpenseListV2Body({Key? key, required this.loadVehicles})
      : super(key: key);

  final VehiclesLoader? loadVehicles;

  @override
  State<_FuelExpenseListV2Body> createState() => _FuelExpenseListV2BodyState();
}

class _FuelExpenseListV2BodyState extends State<_FuelExpenseListV2Body> {
  List<VehicleModel> _vehicles = [];
  List<FuelExpenseModel> _fuels = [];
  int? _vehicleFilter;
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
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _fuels = vehicles.expand((v) => v.fuelExpenses).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        if (!vehicles.any((v) => v.id == _vehicleFilter)) {
          _vehicleFilter = null;
        }
      });
    } catch (error, stackTrace) {
      debugPrint('[Combustível] Erro: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _hasError = true);
      handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetail([FuelExpenseModel? fuel]) async {
    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Cadastre um veículo antes de registrar '
            'abastecimentos.'),
        action: SnackBarAction(
          label: 'Cadastrar',
          onPressed: () async {
            await Navigator.pushNamed(context, Routes.vehicleDetail);
            if (mounted) _load();
          },
        ),
      ));
      return;
    }

    final args = <String, dynamic>{
      'vehicles': _vehicles,
      'fuelExpenseModel': fuel ??
          FuelExpenseModel(
              id: 0,
              vehicleId: _vehicleFilter ?? 0,
              miliage: 0,
              pricePerLiter: 0,
              valueSupplied: 0,
              date: DateTime.now(),
              vehicleName: ''),
    };
    await Navigator.pushNamed(context, Routes.fuelExpenseDetail,
        arguments: args);
    if (mounted) _load();
  }

  Future<bool> _delete(FuelExpenseModel fuel) async {
    try {
      final result = await FuelExpenseService(context).remove(fuel.id);
      return result.isValid();
    } catch (error) {
      if (mounted) handleHttpException(error, context);
      return false;
    }
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
              title: 'Combustível',
              subtitle: 'Acompanhe quanto gasta e quanto seu veículo consome.',
            ),
            const SizedBox(height: 16),
            ..._buildContent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () => _openDetail(),
        icon: const Icon(Icons.local_gas_station_rounded),
        label: const Text('Abastecer'),
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
            title: 'Não foi possível carregar os abastecimentos',
            onRetry: _load),
      ];
    }

    if (_vehicles.isEmpty) {
      return [
        MessageCard(
          icon: Icons.directions_car_rounded,
          title: 'Nenhum veículo cadastrado',
          message: 'Cadastre seu veículo para registrar abastecimentos e '
              'descobrir quanto ele consome.',
          actionLabel: 'Cadastrar veículo',
          onAction: () async {
            await Navigator.pushNamed(context, Routes.vehicleDetail);
            if (mounted) _load();
          },
        ),
      ];
    }

    final fuels = _vehicleFilter == null
        ? _fuels
        : _fuels.where((f) => f.vehicleId == _vehicleFilter).toList();
    final vehicles = _vehicleFilter == null
        ? _vehicles
        : _vehicles.where((v) => v.id == _vehicleFilter).toList();

    final months = <DateTime, List<FuelExpenseModel>>{};
    for (final fuel in fuels) {
      months
          .putIfAbsent(DateTime(fuel.date.year, fuel.date.month), () => [])
          .add(fuel);
    }

    return [
      if (_vehicles.length > 1) ...[
        _VehicleFilter(
          vehicles: _vehicles,
          selectedId: _vehicleFilter,
          onSelected: (id) => setState(() => _vehicleFilter = id),
        ),
        const SizedBox(height: 12),
      ],
      _FuelSummaryCard(fuels: fuels, vehicles: vehicles),
      if (fuels.isEmpty) ...[
        const SizedBox(height: 12),
        const MessageCard(
          icon: Icons.local_gas_station_rounded,
          title: 'Nenhum abastecimento registrado',
          message: 'Registre cada abastecimento com a quilometragem do painel '
              'para o app calcular o consumo médio.',
        ),
      ] else ...[
        const SectionTitle('Histórico'),
        Text('Toque para editar. Deslize para a esquerda para excluir.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        for (final entry in months.entries) ...[
          _MonthHeader(month: entry.key, fuels: entry.value),
          ...entry.value.map((fuel) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SwipeToDelete(
                  key: ValueKey('fuel-${fuel.id}'),
                  confirmTitle: 'Excluir este abastecimento?',
                  confirmMessage:
                      '${fuel.vehicleName} · ${dayMonthLabel(fuel.date)}',
                  onDelete: () => _delete(fuel),
                  onDeleted: () => setState(() => _fuels.remove(fuel)),
                  child: _FuelTile(fuel: fuel, onTap: () => _openDetail(fuel)),
                ),
              )),
        ],
      ],
    ];
  }
}

class _VehicleFilter extends StatelessWidget {
  const _VehicleFilter(
      {Key? key,
      required this.vehicles,
      required this.selectedId,
      required this.onSelected})
      : super(key: key);

  final List<VehicleModel> vehicles;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todos'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          ...vehicles.map((v) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(v.description),
                  selected: selectedId == v.id,
                  onSelected: (_) => onSelected(v.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _FuelSummaryCard extends StatelessWidget {
  const _FuelSummaryCard(
      {Key? key, required this.fuels, required this.vehicles})
      : super(key: key);

  final List<FuelExpenseModel> fuels;
  final List<VehicleModel> vehicles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();

    final thisMonth = fuels
        .where((f) => f.date.year == now.year && f.date.month == now.month)
        .toList();
    final monthTotal =
        thisMonth.fold<num>(0, (sum, f) => sum + f.valueSupplied);
    final monthLiters = thisMonth.fold<num>(0, (sum, f) => sum + litersOf(f));
    final lastPrice = fuels.isEmpty ? null : fuels.first.pricePerLiter;

    final consumptions =
        vehicles.map((v) => v.miliagePerLiter).where((c) => c > 0).toList();
    final consumption = consumptions.isEmpty
        ? null
        : consumptions.reduce((a, b) => a + b) / consumptions.length;

    return V2Card(
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gasto em ${monthYearLabel(now.month, now.year)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(money(monthTotal),
                style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: outColor(scheme))),
          ),
          Text(
              '${thisMonth.length} ${thisMonth.length == 1 ? 'abastecimento' : 'abastecimentos'}'
              ' · ${number(monthLiters, decimals: 1)} litros',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.speed_rounded,
                  label: 'Consumo médio',
                  value: consumption == null
                      ? '—'
                      : '${number(consumption, decimals: 1)} km/l',
                ),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.sell_outlined,
                  label: 'Último preço',
                  value: lastPrice == null ? '—' : '${money(lastPrice)}/l',
                ),
              ),
            ],
          ),
          if (consumption == null && fuels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'O consumo médio aparece depois de alguns abastecimentos com a '
              'quilometragem preenchida.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {Key? key, required this.icon, required this.label, required this.value})
      : super(key: key);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        CircleIcon(icon, color: scheme.primary, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({Key? key, required this.month, required this.fuels})
      : super(key: key);

  final DateTime month;
  final List<FuelExpenseModel> fuels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = fuels.fold<num>(0, (sum, f) => sum + f.valueSupplied);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(monthYearLabel(month.month, month.year),
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text(money(total),
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _FuelTile extends StatelessWidget {
  const _FuelTile({Key? key, required this.fuel, required this.onTap})
      : super(key: key);

  final FuelExpenseModel fuel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = fuel.date.day.toString().padLeft(2, '0');
    final month = fuel.date.month.toString().padLeft(2, '0');

    return V2Card(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleIcon(Icons.local_gas_station_rounded, color: scheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fuel.vehicleName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge),
                Text(
                  '$day/$month · ${number(fuel.miliage)} km · '
                  '${number(litersOf(fuel), decimals: 1)} l',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money(fuel.valueSupplied),
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: outColor(scheme), fontWeight: FontWeight.w600)),
              Text('${money(fuel.pricePerLiter)}/l',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
