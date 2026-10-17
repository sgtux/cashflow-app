import 'package:cashflow_app/src/models/home/home_data_model.dart';
import 'package:cashflow_app/src/models/home/home_description_value.dart';
import 'package:cashflow_app/src/models/home/home_limit_value.dart';
import 'package:cashflow_app/src/models/household-expense/household_expense_model.dart';
import 'package:cashflow_app/src/models/type_model.dart';
import 'package:cashflow_app/src/models/vehicle/fuel_expense.model.dart';
import 'package:cashflow_app/src/models/vehicle/vehicle.model.dart';
import 'package:cashflow_app/src/pages/household_expense_detail_v2.dart';
import 'package:cashflow_app/src/pages/household_expense_list_v2.dart';
import 'package:cashflow_app/src/pages/resume/resume_screen_v2.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_list_v2.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_list_v2.screen.dart';
import 'package:cashflow_app/src/utils/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime.now();

HomeDataModel sampleHomeData({bool overspent = false}) => HomeDataModel(
      month: now.month,
      year: now.year,
      pendingPayments: [
        HomeDescriptionValue(description: 'Aluguel (Recorrente)', value: 800),
        HomeDescriptionValue(description: 'Luz (Recorrente)', value: 230),
      ],
      limitValues: [
        HomeLimitValue.fromMap(
            {'description': 'Despesas Domésticas', 'limit': 500, 'spent': 58}),
        HomeLimitValue.fromMap(
            {'description': 'Combustível', 'limit': 300, 'spent': 320}),
      ],
      inflows: [
        HomeDescriptionValue(description: 'Salário', value: 5000),
        HomeDescriptionValue(description: 'Freela', value: 600),
      ],
      outflows: List.generate(
          7,
          (i) => HomeDescriptionValue(
              description: 'Gasto número ${i + 1} com nome bem comprido',
              value: 100.0 * (i + 1))),
      totalInflows: 5600,
      totalOutflows: overspent ? 6400 : 2800,
    );

List<HouseholdExpenseModel> sampleExpenses() => [
      HouseholdExpenseModel(
          id: 1,
          description: 'Mercado do mês',
          value: 650.4,
          date: DateTime(now.year, now.month, 3),
          type: 20,
          typeDescription: 'Alimentação'),
      HouseholdExpenseModel(
          id: 2,
          description: 'Troca de óleo',
          value: 180,
          date: DateTime(now.year, now.month, 3),
          type: 6,
          vehicleId: 1,
          typeDescription: 'Veículo'),
      for (var i = 3; i < 9; i++)
        HouseholdExpenseModel(
            id: i,
            description: 'Despesa $i',
            value: 20.0 * i,
            date: DateTime(now.year, now.month, i),
            type: 20 + i,
            typeDescription: 'Categoria $i'),
    ];

FuelExpenseModel fuel(int id, int vehicleId, String name, DateTime date) =>
    FuelExpenseModel(
        id: id,
        miliage: 45000 + id * 400,
        valueSupplied: 250,
        pricePerLiter: 5.89,
        date: date,
        vehicleId: vehicleId,
        vehicleName: name);

List<VehicleModel> sampleVehicles() => [
      VehicleModel(
          id: 1,
          description: 'Onix 2020',
          miliageTraveled: 12340,
          miliagePerLiter: 11.4,
          fuelExpenses: [
            fuel(1, 1, 'Onix 2020', now),
            fuel(2, 1, 'Onix 2020', DateTime(now.year, now.month - 1, 10)),
          ]),
      VehicleModel(
          id: 2,
          description: 'Moto CG 160',
          miliageTraveled: 0,
          miliagePerLiter: 0,
          fuelExpenses: [fuel(3, 2, 'Moto CG 160', now)]),
    ];

final types = [
  TypeModel(id: 6, description: 'Veículo'),
  TypeModel(id: 20, description: 'Alimentação'),
];

void main() {
  const sizes = {'320x568': Size(320, 568), '412x915': Size(412, 915)};

  Future<void> pumpScreen(WidgetTester tester, Size size, Widget screen,
      {Object? arguments}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (_) => MaterialPageRoute(
        settings: RouteSettings(arguments: arguments),
        builder: (_) => screen,
      ),
    ));
    await tester.pumpAndSettle();
  }

  final verticalList = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down);

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200,
        scrollable: verticalList.first);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final entry in sizes.entries) {
      final suffix = '($mode, ${entry.key})';

      testWidgets('Resumo v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(
            tester,
            entry.value,
            ResumeScreenV2(
                loadHomeData: (_, __, ___) async => sampleHomeData()));
        expect(find.text('Saldo do mês'), findsOneWidget);
        await scrollTo(tester, find.textContaining('Passou'));
        await scrollTo(tester, find.text('Ver todas (7)'));
        await tester.tap(find.text('Ver todas (7)'));
        await tester.pumpAndSettle();
        await scrollTo(tester, find.text('Mostrar menos'));
        expect(tester.takeException(), isNull);
      });

      testWidgets('Despesas v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(
            tester,
            entry.value,
            HouseholdExpenseListV2(
                loadExpenses: (_, __, ___) async => sampleExpenses()));
        expect(find.text('Para onde foi o dinheiro'), findsOneWidget);
        await scrollTo(tester, find.text('Mercado do mês'));
        expect(tester.takeException(), isNull);
      });

      testWidgets('Combustível v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(
            tester,
            entry.value,
            FuelExpenseListV2Screen(
                loadVehicles: (_) async => sampleVehicles()));
        expect(find.text('Todos'), findsOneWidget);
        await tester.tap(find.text('Moto CG 160').first);
        await tester.pumpAndSettle();
        await scrollTo(tester, find.text('Histórico'));
        expect(tester.takeException(), isNull);
      });

      testWidgets('Veículos v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(tester, entry.value,
            VehicleListV2Screen(loadVehicles: (_) async => sampleVehicles()));
        expect(find.text('Onix 2020'), findsOneWidget);
        await scrollTo(tester, find.text('Custo por km').last);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Formulário de despesa v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(
          tester,
          entry.value,
          HouseholdExpenseDetailV2(
            loadTypes: (_) async => types,
            loadVehicles: (_) async => sampleVehicles(),
          ),
          arguments: sampleExpenses()[1],
        );
        expect(find.text('Editar despesa'), findsOneWidget);
        expect(find.text('Veículo'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Formulário de abastecimento v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        final vehicles = sampleVehicles();
        await pumpScreen(tester, entry.value, const FuelExpenseDetailV2Screen(),
            arguments: {
              'vehicles': vehicles,
              'fuelExpenseModel': vehicles.first.fuelExpenses.first,
            });
        expect(find.text('Editar abastecimento'), findsOneWidget);
        expect(
            find.textContaining('Aproximadamente 42,4 litros'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Formulário de veículo v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(tester, entry.value, const VehicleDetailV2Screen());
        expect(find.text('Novo veículo'), findsOneWidget);
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();
        expect(find.text('Informe um nome para o veículo'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Resumo v2 avisa quando saiu mais do que entrou', (tester) async {
    await pumpScreen(
        tester,
        const Size(412, 915),
        ResumeScreenV2(
            loadHomeData: (_, __, ___) async =>
                sampleHomeData(overspent: true)));
    expect(find.text('Saiu mais do que entrou'), findsOneWidget);
  });

  testWidgets('Despesas v2 mostra estado vazio', (tester) async {
    await pumpScreen(tester, const Size(412, 915),
        HouseholdExpenseListV2(loadExpenses: (_, __, ___) async => []));
    expect(find.textContaining('Nenhuma despesa em'), findsOneWidget);
  });

  testWidgets('Despesas v2 troca de mês e recarrega', (tester) async {
    final requested = <String>[];
    await pumpScreen(tester, const Size(412, 915),
        HouseholdExpenseListV2(loadExpenses: (_, month, year) async {
      requested.add('$month/$year');
      return [];
    }));
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();
    final previous = DateTime(now.year, now.month - 1);
    expect(requested,
        ['${now.month}/${now.year}', '${previous.month}/${previous.year}']);
  });

  testWidgets('Veículos v2 mostra estado vazio', (tester) async {
    await pumpScreen(tester, const Size(412, 915),
        VehicleListV2Screen(loadVehicles: (_) async => []));
    expect(find.text('Nenhum veículo cadastrado'), findsOneWidget);
  });
}
