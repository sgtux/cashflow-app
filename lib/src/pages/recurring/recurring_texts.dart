import 'package:cashflow_app/src/models/recurring/recurring_model.dart';
import 'package:flutter/material.dart';

/// Vocabulário das telas de ganhos fixos e contas fixas.
class RecurringTexts {
  final IconData icon;
  final String title;
  final String subtitle;
  final String add;
  final String newTitle;
  final String editTitle;
  final String descriptionLabel;
  final String descriptionHint;
  final String valueLabel;
  final String valueHelper;
  final String done;
  final String pending;
  final String inactive;
  final String quickAction;
  final String historyTitle;
  final String historyValueLabel;
  final String historyEmpty;
  final String totalLabel;
  final String Function(int count) pendingCount;
  final String showInactive;
  final String inactiveAtLabel;
  final String inactiveAtHelper;
  final String emptyTitle;
  final String emptyMessage;
  final String removeTitle;

  const RecurringTexts(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.add,
      required this.newTitle,
      required this.editTitle,
      required this.descriptionLabel,
      required this.descriptionHint,
      required this.valueLabel,
      required this.valueHelper,
      required this.done,
      required this.pending,
      required this.inactive,
      required this.quickAction,
      required this.historyTitle,
      required this.historyValueLabel,
      required this.historyEmpty,
      required this.totalLabel,
      required this.pendingCount,
      required this.showInactive,
      required this.inactiveAtLabel,
      required this.inactiveAtHelper,
      required this.emptyTitle,
      required this.emptyMessage,
      required this.removeTitle});

  static RecurringTexts of(RecurringKind kind) =>
      kind == RecurringKind.earning ? _earning : _expense;

  static final _earning = RecurringTexts(
    icon: Icons.event_repeat_rounded,
    title: 'Ganhos fixos',
    subtitle:
        'Dinheiro que chega todo mês, como salário, aposentadoria ou pensão.',
    add: 'Cadastrar ganho fixo',
    newTitle: 'Novo ganho fixo',
    editTitle: 'Editar ganho fixo',
    descriptionLabel: 'Nome do ganho',
    descriptionHint: 'Ex.: Salário, Aposentadoria',
    valueLabel: 'Quanto costuma receber por mês?',
    valueHelper:
        'Uma estimativa. Se vier diferente em algum mês, ajuste no histórico.',
    done: 'Recebido este mês',
    pending: 'Ainda não recebido',
    inactive: 'Encerrado',
    quickAction: 'Recebi',
    historyTitle: 'Histórico de recebimentos',
    historyValueLabel: 'Valor recebido',
    historyEmpty: 'Nenhum recebimento registrado ainda.',
    totalLabel: 'Você recebe por mês (estimado)',
    pendingCount: (n) => n == 1
        ? '1 ganho ainda não recebido este mês'
        : '$n ganhos ainda não recebidos este mês',
    showInactive: 'Mostrar ganhos encerrados',
    inactiveAtLabel: 'Encerrar a partir de',
    inactiveAtHelper: 'Parou de receber? Informe a data e ele deixa de '
        'entrar nas projeções.',
    emptyTitle: 'Nenhum ganho fixo cadastrado',
    emptyMessage: 'Comece pelo seu salário: cadastre uma vez e, a cada mês, '
        'só confirme que recebeu.',
    removeTitle: 'Remover ganho fixo?',
  );

  static final _expense = RecurringTexts(
    icon: Icons.receipt_long_rounded,
    title: 'Contas fixas',
    subtitle: 'Contas que chegam todo mês: aluguel, internet, luz, celular, '
        'assinaturas.',
    add: 'Cadastrar conta fixa',
    newTitle: 'Nova conta fixa',
    editTitle: 'Editar conta fixa',
    descriptionLabel: 'Nome da conta',
    descriptionHint: 'Ex.: Aluguel, Internet, Conta de luz',
    valueLabel: 'Quanto costuma custar por mês?',
    valueHelper: 'Se o valor muda (como a conta de luz), use uma média.',
    done: 'Paga este mês',
    pending: 'A pagar',
    inactive: 'Encerrada',
    quickAction: 'Paguei',
    historyTitle: 'Histórico de pagamentos',
    historyValueLabel: 'Valor pago',
    historyEmpty: 'Nenhum pagamento registrado ainda.',
    totalLabel: 'Suas contas fixas somam por mês',
    pendingCount: (n) => n == 1
        ? '1 conta ainda a pagar este mês'
        : '$n contas ainda a pagar este mês',
    showInactive: 'Mostrar contas encerradas',
    inactiveAtLabel: 'Encerrar a partir de',
    inactiveAtHelper: 'Cancelou o serviço? Informe a data e ela deixa de '
        'entrar nas projeções.',
    emptyTitle: 'Nenhuma conta fixa cadastrada',
    emptyMessage: 'Liste as contas que chegam todo mês. Assim você sabe '
        'quanto do seu dinheiro já tem destino certo.',
    removeTitle: 'Remover conta fixa?',
  );
}
