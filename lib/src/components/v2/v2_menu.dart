import 'package:cashflow_app/src/utils/constants.dart';
import 'package:flutter/material.dart';

/// Item do menu: abre uma aba da Home ([tab]) ou uma tela própria ([route]).
class _MenuItem {
  final IconData icon;
  final String label;
  final String hint;
  final int? tab;
  final String? route;

  const _MenuItem(this.icon, this.label, this.hint, {this.tab, this.route});
}

class _MenuGroup {
  final String? title;
  final List<_MenuItem> items;

  const _MenuGroup(this.title, this.items);
}

// Mesma ordem do menu do site: o que entra, o que sai e, por fim, planejar.
const _groups = [
  _MenuGroup(null, [
    _MenuItem(Icons.home_rounded, 'Início', 'Resumo do seu mês', tab: 0),
  ]),
  _MenuGroup('O que entra', [
    _MenuItem(Icons.trending_up_rounded, 'Ganhos', 'Freelas, vendas, bônus',
        route: Routes.earningList),
    _MenuItem(Icons.event_repeat_rounded, 'Ganhos fixos', 'Salário e afins',
        route: Routes.recurringEarningList),
  ]),
  _MenuGroup('O que sai', [
    _MenuItem(Icons.shopping_basket_rounded, 'Despesas do dia a dia',
        'Mercado, lanche, transporte',
        tab: 1),
    _MenuItem(
        Icons.receipt_long_rounded, 'Contas fixas', 'Aluguel, internet, luz',
        route: Routes.recurringExpenseList),
    _MenuItem(
        Icons.view_week_rounded, 'Parcelamentos', 'Compras em várias vezes',
        route: Routes.paymentList),
    _MenuItem(
        Icons.credit_card_rounded, 'Cartões e faturas', 'O que vence no cartão',
        route: Routes.creditCardList),
    _MenuItem(Icons.local_gas_station_rounded, 'Combustível',
        'Abastecimentos e consumo',
        tab: 2),
    _MenuItem(Icons.directions_car_rounded, 'Veículos', 'Seus carros e motos',
        tab: 3),
  ]),
  _MenuGroup('Planejar', [
    _MenuItem(Icons.query_stats_rounded, 'Projeção', 'Os próximos meses',
        tab: 4),
    _MenuItem(
        Icons.savings_rounded, 'Fechamento do mês', 'Quanto sobrou em cada mês',
        route: Routes.remainingBalance),
  ]),
  _MenuGroup('Conta e ajuda', [
    _MenuItem(Icons.tune_rounded, 'Minha conta e limites',
        'Limites de gastos e plano',
        route: Routes.account),
    _MenuItem(Icons.menu_book_rounded, 'Glossário', 'Termos explicados',
        route: Routes.glossary),
  ]),
];

/// Menu lateral das telas v2, com todas as funcionalidades do app.
class V2Menu extends StatelessWidget {
  const V2Menu({Key? key, required this.currentTab, required this.onSelectTab})
      : super(key: key);

  final int currentTab;
  final ValueChanged<int> onSelectTab;

  void _open(BuildContext context, _MenuItem item) {
    Navigator.pop(context);
    if (item.tab != null) {
      onSelectTab(item.tab!);
    } else {
      Navigator.pushNamed(context, item.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
              child: Text('CASHFLOW',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: scheme.primary)),
            ),
            for (final group in _groups) ...[
              if (group.title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 16, 4),
                  child: Text(group.title!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8)),
                ),
              ...group.items.map((item) {
                final selected = item.tab != null && item.tab == currentTab;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    selected: selected,
                    selectedTileColor: scheme.secondaryContainer,
                    selectedColor: scheme.onSecondaryContainer,
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    subtitle: Text(item.hint),
                    dense: true,
                    onTap: () => _open(context, item),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
