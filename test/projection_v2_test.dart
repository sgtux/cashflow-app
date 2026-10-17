import 'package:cashflow_app/src/models/home/payment_projection_model.dart';
import 'package:cashflow_app/src/models/home/projection_model.dart';
import 'package:cashflow_app/src/pages/resume/projection_screen_v2.dart';
import 'package:cashflow_app/src/utils/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PaymentProjectionModel payment(String description, num value,
    {bool isIn = false, String card = '', int installments = 0}) {
  return PaymentProjectionModel(
    description: description,
    number: installments > 0 ? '2' : null,
    qtdInstallments: installments,
    paidDate: null,
    value: value,
    isIn: isIn,
    type: 1,
    creditCardName: card,
  );
}

List<ProjectionModel> sampleMonths({bool withNegative = false}) {
  var accumulated = 1200.0;
  return List.generate(8, (i) {
    final totalIn = 5000.0;
    final totalOut = withNegative && i >= 3 ? 6800.0 : 4200.0 + i * 50;
    final total = totalIn - totalOut;
    accumulated += total;
    return ProjectionModel(
      monthYear: '${(i + 10) % 12 + 1}/${i < 2 ? 2026 : 2027}',
      totalIn: totalIn,
      totalOut: totalOut,
      total: total,
      accumulatedValue: accumulated,
      payments: [
        payment('Salário', totalIn, isIn: true),
        payment('Aluguel', 1800),
        payment('Luz', 230),
        payment('Mercado', 900, card: 'Nubank'),
        payment('Notebook parcelado em várias vezes', 450,
            card: 'Nubank', installments: 10),
        payment('Streaming', 55, card: 'Inter'),
      ],
    );
  });
}

void main() {
  const sizes = {
    '320x568': Size(320, 568),
    '412x915': Size(412, 915),
    '800x1280': Size(800, 1280),
  };

  Future<void> pump(
      WidgetTester tester, Size size, ProjectionLoader loader) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ProjectionScreenV2(loadProjection: loader))));
    await tester.pumpAndSettle();
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final entry in sizes.entries) {
      testWidgets('ProjectionV2 sem estouro de layout ($mode, ${entry.key})',
          (tester) async {
        AppSettings.themeModeV2.value = mode;
        await pump(tester, entry.value, (_) async => sampleMonths());

        final verticalList = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
        Future<void> scrollTo(Finder finder) =>
            tester.scrollUntilVisible(finder, 200, scrollable: verticalList);

        expect(find.text('Saldo acumulado em Junho/2027'), findsOneWidget);
        await scrollTo(find.text('Seu dinheiro pode render'));

        // Seleciona o primeiro mês no gráfico.
        final firstBar = find.byWidgetPredicate((w) =>
            w is Semantics &&
            (w.properties.label ?? '').startsWith('Novembro/2026'));
        await tester.ensureVisible(firstBar);
        await tester.pumpAndSettle();
        await tester.tap(firstBar);
        await tester.pumpAndSettle();
        expect(find.text('Saldo acumulado em Novembro/2026'), findsOneWidget);

        // Abre o detalhe do primeiro mês e a fatura do cartão.
        await scrollTo(find.text('Novembro/2026'));
        await tester.tap(find.text('Novembro/2026'));
        await tester.pumpAndSettle();
        await scrollTo(find.text('Nubank'));
        await tester.tap(find.text('Nubank'));
        await tester.pumpAndSettle();
        await scrollTo(find.text('Parcela 2/10'));

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('ProjectionV2 avisa quando o saldo fica negativo',
      (tester) async {
    await pump(tester, const Size(412, 915),
        (_) async => sampleMonths(withNegative: true));
    expect(find.text('Atenção ao seu saldo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProjectionV2 mostra estado vazio', (tester) async {
    await pump(tester, const Size(412, 915), (_) async => []);
    expect(find.text('Sua projeção aparece aqui'), findsOneWidget);
  });

  testWidgets('ProjectionV2 mostra erro e permite tentar de novo',
      (tester) async {
    var calls = 0;
    await pump(tester, const Size(412, 915), (_) async {
      calls++;
      throw Exception('falha de rede');
    });
    expect(find.text('Não foi possível carregar a projeção'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}
