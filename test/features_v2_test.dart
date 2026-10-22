import 'package:cashflow_app/src/components/v2/v2_menu.dart';
import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/account/account_model.dart';
import 'package:cashflow_app/src/models/credit-card/credit_card_model.dart';
import 'package:cashflow_app/src/models/earning/earning_model.dart';
import 'package:cashflow_app/src/models/payment/payment_model.dart';
import 'package:cashflow_app/src/models/recurring/recurring_model.dart';
import 'package:cashflow_app/src/models/remaining-balance/remaining_balance_model.dart';
import 'package:cashflow_app/src/models/type_model.dart';
import 'package:cashflow_app/src/pages/account_v2.screen.dart';
import 'package:cashflow_app/src/pages/credit-card/credit_card_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/credit-card/credit_card_list_v2.screen.dart';
import 'package:cashflow_app/src/pages/earning/earning_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/earning/earning_list_v2.screen.dart';
import 'package:cashflow_app/src/pages/glossary_v2.screen.dart';
import 'package:cashflow_app/src/pages/payment/payment_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/payment/payment_list_v2.screen.dart';
import 'package:cashflow_app/src/pages/recurring/recurring_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/recurring/recurring_list_v2.screen.dart';
import 'package:cashflow_app/src/pages/remaining_balance_v2.screen.dart';
import 'package:cashflow_app/src/services/payment.service.dart';
import 'package:cashflow_app/src/utils/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime.now();

List<EarningModel> sampleEarnings() => [
      EarningModel(
          id: 1,
          description: 'Freela de design com nome bem comprido',
          value: 1200,
          date: DateTime(now.year, now.month, 5)),
      EarningModel(
          id: 2,
          description: 'Venda da bicicleta',
          value: 450.5,
          date: DateTime(now.year, now.month - 2, 20)),
    ];

RecurringModel sampleRecurring(RecurringKind kind,
        {int id = 1, bool done = false, DateTime? inactiveAt}) =>
    RecurringModel(
      kind: kind,
      id: id,
      description: kind == RecurringKind.earning ? 'Salário' : 'Aluguel',
      value: kind == RecurringKind.earning ? 5000 : 1800,
      done: done,
      inactiveAt: inactiveAt,
      creditCardId: kind == RecurringKind.expense ? 1 : null,
      creditCardName: kind == RecurringKind.expense ? 'Nubank' : null,
      history: [
        RecurringHistoryModel(
            kind: kind,
            id: 10 + id,
            parentId: id,
            value: 1750,
            date: DateTime(now.year, now.month - 1, 10)),
      ],
    );

List<RecurringModel> sampleRecurringList(RecurringKind kind) => [
      sampleRecurring(kind, id: 1),
      sampleRecurring(kind, id: 2, done: true),
      sampleRecurring(kind, id: 3, inactiveAt: DateTime(now.year - 1)),
    ];

PaymentModel samplePayment({bool done = false}) {
  final first = DateTime(now.year, now.month - 2, 10);
  return PaymentModel(
    id: done ? 2 : 1,
    description: done ? 'Celular' : 'Geladeira Frost Free 2 portas',
    type: 2,
    creditCardId: 1,
    creditCardName: 'Nubank',
    date: first,
    installments: List.generate(
        6,
        (i) => InstallmentModel(
              id: i + 1,
              number: i + 1,
              value: 350.25,
              date: DateTime(first.year, first.month + i, first.day),
              paidValue: done || i < 2 ? 350.25 : null,
              paidDate: done || i < 2
                  ? DateTime(first.year, first.month + i, first.day)
                  : null,
              exempt: !done && i == 5,
            )),
  );
}

final paymentTypes = [
  TypeModel(id: 2, description: 'Mercado'),
  TypeModel(id: 20, description: 'Outros'),
];

List<CreditCardModel> sampleCards() => [
      CreditCardModel(
        id: 1,
        name: 'Nubank Ultravioleta com nome comprido',
        invoiceClosingDay: 3,
        invoiceDueDay: 10,
        currentMonthDebt: 1580.4,
        outstandingDebtTotal: 4200,
        items: [
          CreditCardItemModel(
              id: 1,
              type: CreditCardItemType.installment,
              description: 'Geladeira (Parcelado)',
              outstandingDebt: 1400,
              currentMonthDebt: 350,
              isCurrentMonthDebtPaid: false,
              plots: '2/6',
              total: 2100),
          CreditCardItemModel(
              id: 2,
              type: CreditCardItemType.household,
              description: 'Mercado',
              outstandingDebt: 230,
              currentMonthDebt: 230,
              isCurrentMonthDebtPaid: false),
          CreditCardItemModel(
              id: 3,
              type: CreditCardItemType.recurring,
              description: 'Streaming',
              outstandingDebt: 0,
              currentMonthDebt: 40,
              isCurrentMonthDebtPaid: true),
        ],
      ),
      CreditCardModel(
          id: 2,
          name: 'Itaú',
          invoiceClosingDay: 25,
          invoiceDueDay: 5,
          isCurrentMonthDebtPaid: true),
    ];

List<RemainingBalanceModel> sampleBalances() => [
      RemainingBalanceModel(
          id: 0, month: now.month, year: now.year, value: 320),
      for (var i = 1; i <= 7; i++)
        RemainingBalanceModel(
            id: i,
            month: DateTime(now.year, now.month - i).month,
            year: DateTime(now.year, now.month - i).year,
            value: i.isEven ? -150.0 * i : 210.0 * i),
    ];

AccountModel sampleAccount() => AccountModel(
    email: 'pessoa@exemplo.com',
    expenseLimit: 1200,
    fuelExpenseLimit: 400,
    plan: 1,
    recordsUsed: 8700);

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

      testWidgets('Ganhos v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(
            tester,
            entry.value,
            EarningListV2Screen(
                loadEarnings: (_, __) async => sampleEarnings()));
        expect(find.text('Total no período'), findsOneWidget);
        await scrollTo(tester, find.text('Venda da bicicleta'));
        // Só o ganho de outro mês pode ser repetido no mês atual.
        expect(
            find.byTooltip('Repetir este ganho no mês atual'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Formulário de ganho v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(tester, entry.value, const EarningDetailV2Screen(),
            arguments: sampleEarnings().first);
        expect(find.text('Editar ganho'), findsOneWidget);
        expect(find.text('Freela de design com nome bem comprido'),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      for (final kind in RecurringKind.values) {
        final name = kind == RecurringKind.earning ? 'Ganhos' : 'Contas';

        testWidgets('$name fixos v2 $suffix', (tester) async {
          AppSettings.themeModeV2.value = mode;
          await pumpScreen(
              tester,
              entry.value,
              RecurringListV2Screen(
                  kind: kind,
                  loadItems: (_, __) async => sampleRecurringList(kind)));
          expect(find.textContaining('por mês'), findsWidgets);
          await scrollTo(tester,
              find.text(kind == RecurringKind.earning ? 'Recebi' : 'Paguei'));
          await scrollTo(tester, find.byType(SwitchListTile));
          expect(tester.takeException(), isNull);
        });

        testWidgets('Formulário de $name fixos v2 $suffix', (tester) async {
          AppSettings.themeModeV2.value = mode;
          await pumpScreen(
              tester,
              entry.value,
              RecurringDetailV2Screen(
                  loadCreditCards: (_) async => sampleCards()),
              arguments: sampleRecurring(kind));
          await scrollTo(tester, find.textContaining('1.750,00'));
          if (kind == RecurringKind.expense) {
            expect(
                find.text('É cobrada no cartão de crédito?'), findsOneWidget);
          } else {
            expect(find.text('É cobrada no cartão de crédito?'), findsNothing);
          }
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('Parcelamentos v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(
            tester,
            entry.value,
            PaymentListV2Screen(
                loadPayments: (_, __) async =>
                    [samplePayment(), samplePayment(done: true)],
                loadTypes: (_) async => paymentTypes));
        expect(find.text('Em andamento'), findsOneWidget);
        await scrollTo(tester, find.text('Geladeira Frost Free 2 portas'));
        expect(find.textContaining('3 de 6 parcelas pagas'), findsOneWidget);
        await scrollTo(tester, find.text('Quitado'));
        expect(tester.takeException(), isNull);
      });

      testWidgets('Formulário de parcelamento v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(
            tester,
            entry.value,
            PaymentDetailV2Screen(
              loadTypes: (_) async => paymentTypes,
              loadCreditCards: (_) async => sampleCards(),
              loadPayment: (_, __) async => samplePayment(),
            ),
            arguments: samplePayment());
        expect(find.text('Editar parcelamento'), findsOneWidget);
        await scrollTo(tester, find.text('Parcela 1'));
        expect(find.text('Paga'), findsWidgets);
        await scrollTo(tester, find.text('Parcela 6'));
        expect(find.text('Isenta'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Cartões v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(tester, entry.value,
            CreditCardListV2Screen(loadCards: (_) async => sampleCards()));
        expect(find.text('Fatura atual'), findsWidgets);
        await tester.tap(find.text('Compras (3)'));
        await tester.pumpAndSettle();
        await scrollTo(tester, find.text('Streaming'));
        // Despesa do dia a dia no cartão não é paga item a item.
        expect(find.text('Pagar'), findsOneWidget);
        expect(find.text('Mês pago'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Formulário de cartão v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(tester, entry.value, const CreditCardDetailV2Screen());
        expect(find.text('Novo cartão de crédito'), findsOneWidget);
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();
        expect(find.text('Informe o nome do cartão'), findsOneWidget);
        expect(find.text('Informe um dia de 1 a 30'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      });

      testWidgets('Fechamento do mês v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(
            tester,
            entry.value,
            RemainingBalanceV2Screen(
                loadBalances: (_) async => sampleBalances()));
        expect(find.textContaining('Simulação do mês atual'), findsOneWidget);
        await scrollTo(tester, find.text('Mostrar todos os 8 meses'));
        await tester.tap(find.text('Mostrar todos os 8 meses'));
        await tester.pumpAndSettle();
        await scrollTo(tester, find.text('Mostrar só os últimos 5 meses'));
        expect(tester.takeException(), isNull);
      });

      testWidgets('Minha conta v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(tester, entry.value,
            AccountV2Screen(loadAccount: (_) async => sampleAccount()));
        expect(find.text('pessoa@exemplo.com'), findsOneWidget);
        await scrollTo(tester, find.text('Seu plano'));
        expect(tester.takeException(), isNull);
      });

      testWidgets('Glossário v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pumpScreen(tester, entry.value, const GlossaryV2Screen());
        await tester.tap(find.text('Ganho (provento)'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Recebeu R\$ 300'), findsOneWidget);
        await scrollTo(tester, find.text('Média (km/l)'));
        expect(tester.takeException(), isNull);
      });

      testWidgets('Menu v2 $suffix', (tester) async {
        AppSettings.themeModeV2.value = mode;
        final key = GlobalKey<ScaffoldState>();
        await pumpScreen(
            tester,
            entry.value,
            V2Theme(
                child: Scaffold(
                    key: key,
                    drawer: V2Menu(currentTab: 0, onSelectTab: (_) {}))));
        key.currentState!.openDrawer();
        await tester.pumpAndSettle();
        await scrollTo(tester, find.text('Glossário'));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Ganhos v2 recarrega ao trocar o mês inicial', (tester) async {
    final requested = <DateTime>[];
    await pumpScreen(tester, const Size(412, 915),
        EarningListV2Screen(loadEarnings: (_, from) async {
      requested.add(from);
      return [];
    }));
    expect(find.text('Nenhum ganho neste período'), findsOneWidget);
    await tester.tap(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<DateTime>));
    await tester.pumpAndSettle();
    final previous = DateTime(now.year, now.month - 1);
    await tester
        .tap(find.text(monthYearLabel(previous.month, previous.year)).last);
    await tester.pumpAndSettle();
    expect(requested, [DateTime(now.year, now.month), previous]);
  });

  testWidgets('Parcelamentos v2 envia o filtro de situação', (tester) async {
    final filters = <bool?>[];
    await pumpScreen(
        tester,
        const Size(412, 915),
        PaymentListV2Screen(
            loadPayments: (_, PaymentFilter filter) async {
              filters.add(filter.done);
              return [];
            },
            loadTypes: (_) async => []));
    expect(find.text('Nenhum parcelamento em andamento'), findsOneWidget);
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(filters, [false, null]);
    expect(find.text('Nada encontrado com esses filtros'), findsOneWidget);
  });

  testWidgets('Parcela marcada como paga usa valor e vencimento',
      (tester) async {
    await pumpScreen(
        tester,
        const Size(412, 3000),
        PaymentDetailV2Screen(
          loadTypes: (_) async => paymentTypes,
          loadCreditCards: (_) async => [],
          loadPayment: (_, __) async => samplePayment(),
        ),
        arguments: samplePayment());
    await scrollTo(tester, find.text('Paguei').first);
    expect(find.text('Paguei'), findsNWidgets(3));
    expect(find.textContaining('350,25 em'), findsNWidgets(2));
    await tester.tap(find.text('Paguei').first);
    await tester.pumpAndSettle();
    expect(find.text('Paguei'), findsNWidgets(2));
    final third = samplePayment().installments[2].date;
    expect(
        find.textContaining('350,25 em ${third.day.toString().padLeft(2, '0')}/'
            '${third.month.toString().padLeft(2, '0')}/${third.year}'),
        findsOneWidget);
  });

  testWidgets('Mudar o valor exige gerar as parcelas de novo', (tester) async {
    await pumpScreen(
        tester,
        const Size(412, 915),
        PaymentDetailV2Screen(
          loadTypes: (_) async => paymentTypes,
          loadCreditCards: (_) async => [],
          loadPayment: (_, __) async => samplePayment(),
        ),
        arguments: samplePayment());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor total da compra'), '999');
    await tester.pumpAndSettle();
    expect(find.text('Gere as parcelas de novo'), findsOneWidget);
  });

  test('Modelos aceitam valores inteiros vindos da API', () {
    final card = CreditCardModel.fromMap({
      'id': 1,
      'name': 'Nubank',
      'invoiceClosingDay': 3,
      'invoiceDueDay': 10,
      'outstandingDebtTotal': 800,
      'currentMonthDebt': 0,
      'isCurrentMonthDebtPaid': true,
      'items': [
        {
          'id': 5,
          'type': 3,
          'description': 'Streaming',
          'outstandingDebt': 0,
          'currentMonthDebt': 40,
          'isCurrentMonthDebtPaid': true,
          'plots': null,
          'total': 0
        }
      ]
    });
    expect(card.outstandingDebtTotal, 800.0);
    expect(card.items.single.currentMonthDebt, 40.0);

    final expense = RecurringModel.fromMap(RecurringKind.expense, {
      'id': 1,
      'description': 'Aluguel',
      'value': 1800,
      'inactiveAt': null,
      'creditCard': {'id': 2, 'name': 'Itaú'},
      'paid': true,
      'history': [
        {
          'id': 1,
          'paidValue': 1800,
          'date': '2026-09-10T00:00:00',
          'recurringExpenseId': 1
        },
        {
          'id': 2,
          'paidValue': 1750,
          'date': '2026-10-10T00:00:00',
          'recurringExpenseId': 1
        },
      ]
    });
    expect(expense.done, isTrue);
    expect(expense.creditCardId, 2);
    expect(expense.creditCardName, 'Itaú');
    expect(expense.history.first.value, 1750.0);
    expect(expense.history.first.toMap(), containsPair('paidValue', 1750.0));

    final earning = RecurringModel.fromMap(RecurringKind.earning, {
      'id': 3,
      'description': 'Salário',
      'value': 5000,
      'received': false,
      'history': [
        {'id': 1, 'value': 5000, 'date': '2026-09-05T00:00:00'}
      ]
    });
    expect(
        earning.history.single.toMap(), containsPair('recurringEarningId', 0));
    expect(earning.toMap().containsKey('creditCardId'), isFalse);

    final payment = PaymentModel.fromMap({
      'id': 1,
      'description': 'TV',
      'type': 25,
      'creditCardText': '',
      'installments': [
        {'id': 2, 'number': 2, 'value': 100, 'date': '2026-11-10T00:00:00'},
        {
          'id': 1,
          'number': 1,
          'value': 100,
          'date': '2026-10-10T00:00:00',
          'paidValue': 100,
          'paidDate': '2026-10-10T00:00:00',
          'exempt': false
        },
      ]
    });
    expect(payment.installments.first.number, 1);
    expect(payment.paidInstallments, 1);
    expect(payment.total, 200.0);
    expect(payment.creditCardName, isNull);
  });

  test('Filtro de parcelamentos monta a query', () {
    expect(const PaymentFilter().toQuery(), 'done=false');
    expect(const PaymentFilter(description: ' tv ', done: null).toQuery(),
        'description=tv');
  });
}
