import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:flutter/material.dart';

class _Term {
  final String term;
  final String short;
  final String example;

  const _Term(this.term, this.short, this.example);
}

class _Group {
  final String title;
  final List<_Term> terms;

  const _Group(this.title, this.terms);
}

// Mesmo conteúdo do glossário do site, em linguagem simples.
const _groups = [
  _Group('O básico', [
    _Term(
        'Ganho (provento)',
        'Todo dinheiro que entra para você: salário, um freela, uma venda, um '
            'presente em dinheiro.',
        'Recebeu R\$ 300 por um trabalho extra no dia 12? Isso é um ganho do '
            'dia 12.'),
    _Term(
        'Despesa',
        'Todo dinheiro que sai: mercado, lanche, farmácia, transporte, lazer.',
        'Gastou R\$ 45 na padaria hoje? Registre como despesa do tipo '
            '"Lanche".'),
    _Term('Entradas', 'Soma de tudo que entrou (ou vai entrar) no mês.',
        'Salário + freela = entradas do mês.'),
    _Term(
        'Saídas',
        'Soma de tudo que saiu (ou vai sair) no mês: despesas, contas fixas, '
            'parcelas e combustível.',
        'Quando as saídas ficam maiores que as entradas, o mês fecha no '
            'vermelho.'),
    _Term(
        'Saldo do mês (líquido)',
        'Entradas menos saídas. Positivo: sobrou dinheiro. Negativo: gastou '
            'mais do que ganhou.',
        'Entrou R\$ 3.000 e saiu R\$ 2.700? O saldo do mês é R\$ 300.'),
  ]),
  _Group('Contas que se repetem', [
    _Term(
        'Ganho recorrente',
        'Um ganho que se repete todo mês com valor parecido, como o salário '
            'ou uma aposentadoria.',
        'Cadastre o salário uma vez e, a cada mês, só confirme que recebeu.'),
    _Term(
        'Despesa recorrente (conta fixa)',
        'Uma conta que chega todo mês: aluguel, internet, luz, academia, '
            'streaming.',
        'Cadastre a internet de R\$ 100 uma vez e marque como paga a cada '
            'mês.'),
    _Term(
        'Pendência',
        'Conta do mês que ainda não foi marcada como paga.',
        'A parcela do notebook vence este mês e ainda não foi paga? Ela '
            'aparece em Pendências.'),
  ]),
  _Group('Cartão e parcelas', [
    _Term(
        'Cartão de crédito',
        'Você compra agora e paga depois, tudo junto, em uma conta mensal '
            'chamada fatura.',
        'O cartão não é dinheiro extra: é dinheiro do seu mês que vem.'),
    _Term(
        'Fatura',
        'A "conta" mensal do cartão: soma tudo o que você comprou nele '
            'naquele período.',
        'Se a fatura de outubro deu R\$ 800, esse é o valor a pagar no '
            'vencimento.'),
    _Term(
        'Dia de fechamento',
        'Dia em que o cartão "fecha a conta" do mês. Compras feitas depois '
            'desse dia vão para a fatura seguinte.',
        'Fechamento dia 5: uma compra no dia 6 só será cobrada na fatura do '
            'mês seguinte.'),
    _Term(
        'Dia de vencimento',
        'Último dia para pagar sem juros. Atrasar gera multa e juros altos.',
        'Vencimento dia 15: pague até o dia 15 para não ter juros.'),
    _Term(
        'Crédito devedor',
        'Tudo que você ainda deve no cartão, somando as parcelas futuras que '
            'já estão comprometidas.',
        'Comprou um celular em 10x e pagou 2? As 8 restantes ainda contam '
            'aqui.'),
    _Term(
        'Parcelamento',
        'Uma compra (ou empréstimo) dividida em várias parcelas que vencem '
            'mês a mês.',
        'Uma TV de R\$ 2.400 em 12x vira 12 parcelas de R\$ 200, uma por '
            'mês.'),
    _Term(
        'Parcela',
        'Cada pedacinho de um parcelamento. Cada parcela tem um valor e uma '
            'data de vencimento.',
        'Na compra em 10x, a "parcela 3/10" é a terceira das dez.'),
    _Term(
        'Isentar parcela',
        'Marcar que uma parcela não precisa ser paga (foi perdoada, cancelada '
            'ou estornada).',
        'A loja cancelou a última parcela? Marque-a como isenta.'),
  ]),
  _Group('Planejamento', [
    _Term(
        'Limite de gastos (orçamento)',
        'Um teto que você mesmo define para um tipo de gasto no mês. Ajuda a '
            'perceber quando está exagerando.',
        'Limite de R\$ 1.200 para despesas do dia a dia: a barra fica '
            'amarela perto de 80%.'),
    _Term(
        'Projeção',
        'Uma previsão de como seu dinheiro vai estar nos próximos meses, com '
            'base no que você já cadastrou.',
        'Se a projeção mostra saldo negativo em março, dá tempo de se '
            'planejar agora.'),
    _Term(
        'Saldo acumulado',
        'O que sobra somando mês após mês. A sobra de um mês "passa" para o '
            'próximo.',
        'Sobrou R\$ 200 em janeiro e R\$ 300 em fevereiro? O acumulado é '
            'R\$ 500.'),
    _Term(
        'Saldo remanescente',
        'Quanto realmente sobrou (ou faltou) ao final de cada mês, já '
            'contando a sobra do mês anterior.',
        'É como "fechar o caixa" do mês e anotar o resultado.'),
    _Term(
        'Devedor',
        'Quando o mês terminou com saldo negativo, ou seja, faltou dinheiro.',
        'Fechou o mês devendo R\$ 150 no cheque especial? Marque como '
            'devedor.'),
    _Term(
        'Valor residual (estimado)',
        'Quando você ainda não lançou gastos, a projeção usa o seu limite '
            'como estimativa.',
        'Limite de combustível R\$ 400 e nada lançado? A projeção considera '
            'R\$ 400.'),
    _Term(
        'Reserva de emergência',
        'Dinheiro guardado para imprevistos (saúde, conserto, desemprego). '
            'Uma meta comum é juntar de 3 a 6 meses de gastos.',
        'Gasta R\$ 2.000 por mês? Uma boa reserva fica entre R\$ 6.000 e '
            'R\$ 12.000.'),
  ]),
  _Group('Liberdade financeira', [
    _Term(
        'Renda passiva',
        'Dinheiro que entra sem você precisar trabalhar por ele: aluguéis, '
            'dividendos (inclusive de FIIs), juros, royalties, lucro de um '
            'negócio que roda sozinho e aposentadoria.',
        'Um FII que paga R\$ 80 por mês é renda passiva. O salário não é: se '
            'você parar de trabalhar, ele para.'),
    _Term(
        'Corrida dos ratos',
        'Quando todo o dinheiro que paga suas contas depende do seu trabalho. '
            'Você sai dela quando a renda passiva cobre todo o seu custo de '
            'vida: as saídas do mês, sem contar o que você investe.',
        'Saídas de R\$ 3.500, sendo R\$ 500 de aporte, e renda passiva de '
            'R\$ 750: o custo de vida é R\$ 3.000 e você cobre 25%. Ao '
            'chegar em 100%, saiu da corrida.'),
  ]),
  _Group('Veículos', [
    _Term(
        'Abastecimento',
        'Cada vez que você coloca combustível no veículo. Com a '
            'quilometragem, calculamos o consumo. Se pagou no cartão, o valor '
            'vai para a fatura.',
        'Abasteceu R\$ 200 a R\$ 5,80 o litro com o painel marcando '
            '45.300 km.'),
    _Term(
        'Média (km/l)',
        'Quantos quilômetros o veículo anda com 1 litro. Quanto maior, mais '
            'econômico.',
        '12 km/l significa que 10 litros levam você por cerca de 120 km.'),
  ]),
];

/// Glossário com os termos financeiros usados no app.
class GlossaryV2Screen extends StatelessWidget {
  const GlossaryV2Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return V2Theme(
      child: Builder(builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return Scaffold(
          appBar: AppBar(title: const Text('Glossário')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const ScreenIntro('Os termos do app explicados sem complicação, '
                  'com um exemplo do dia a dia.'),
              for (final group in _groups) ...[
                SectionTitle(group.title),
                ...group.terms.map((term) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: V2Card(
                        padding: EdgeInsets.zero,
                        child: Theme(
                          data:
                              theme.copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(term.term,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(term.short,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lightbulb_outline_rounded,
                                      size: 18, color: scheme.tertiary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(term.example,
                                        style: theme.textTheme.bodyMedium),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ],
          ),
        );
      }),
    );
  }
}
