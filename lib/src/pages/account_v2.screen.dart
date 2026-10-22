import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/models/account/account_model.dart';
import 'package:cashflow_app/src/services/account.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/flutter_masked_text.dart';
import 'package:flutter/material.dart';

class _Plan {
  final int id;
  final String name;
  final String price;
  final int records;

  const _Plan(this.id, this.name, this.price, this.records);
}

const _plans = [
  _Plan(1, 'Free', 'R\$ 0,00', 10000),
  _Plan(2, 'Basic', 'R\$ 5,99', 100000),
  _Plan(3, 'Premium', 'R\$ 19,99', 1000000),
];

/// Limite máximo aceito pela API para cada limite mensal.
const double maxLimit = 99999;

/// Minha conta: limites mensais de gastos e uso do plano.
class AccountV2Screen extends StatelessWidget {
  const AccountV2Screen({Key? key, this.loadAccount}) : super(key: key);

  /// Permite substituir a busca na API (usado nos testes).
  final Future<AccountModel?> Function(BuildContext context)? loadAccount;

  @override
  Widget build(BuildContext context) {
    return V2Theme(child: _AccountV2Body(loadAccount: loadAccount));
  }
}

class _AccountV2Body extends StatefulWidget {
  const _AccountV2Body({Key? key, required this.loadAccount}) : super(key: key);

  final Future<AccountModel?> Function(BuildContext context)? loadAccount;

  @override
  State<_AccountV2Body> createState() => _AccountV2BodyState();
}

class _AccountV2BodyState extends State<_AccountV2Body> {
  final _formKey = GlobalKey<FormState>();
  final _expenseController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  final _fuelController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');

  AccountModel? _account;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _expenseController.dispose();
    _fuelController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final loader = widget.loadAccount ??
          (BuildContext c) => AccountService(c).getAccount();
      final account = await loader(context);
      if (!mounted) return;
      if (account == null) {
        setState(() => _hasError = true);
        return;
      }
      _expenseController.updateValue(account.expenseLimit);
      _fuelController.updateValue(account.fuelExpenseLimit);
      setState(() => _account = account);
    } catch (error, stackTrace) {
      debugPrint('[Conta] Erro: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _hasError = true);
      handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateLimit(double value) =>
      value > maxLimit ? 'O limite vai até ${money(maxLimit)}' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final account = _account!;

    setState(() => _isSaving = true);
    try {
      final result = await AccountService(context).updateLimits(AccountModel(
          email: account.email,
          expenseLimit: _expenseController.numberValue,
          fuelExpenseLimit: _fuelController.numberValue,
          plan: account.plan,
          recordsUsed: account.recordsUsed));
      if (mounted && result.isValid()) showSuccess(context, 'Limites salvos!');
    } catch (error) {
      if (mounted) handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = !_isLoading && !_hasError;

    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta e limites')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: _buildContent(),
        ),
      ),
      bottomNavigationBar: ready
          ? BottomActionBar(
              label: 'Salvar limites', isLoading: _isSaving, onPressed: _save)
          : null,
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
            title: 'Não foi possível carregar sua conta', onRetry: _load),
      ];
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final account = _account!;
    // Mesma regra do site: planos desconhecidos são tratados como Premium.
    final plan = _plans.firstWhere((p) => p.id == account.plan,
        orElse: () => _plans.last);
    final usage = account.recordsUsed / plan.records;

    return [
      if (account.email.isNotEmpty) ScreenIntro(account.email),
      const SectionTitle('Limites de gastos por mês'),
      Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _expenseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Despesas do dia a dia',
                helperText: 'Mercado, lanches, lazer, transporte... Quanto '
                    'você aceita gastar no mês?',
                helperMaxLines: 2,
                prefixIcon: Icon(Icons.shopping_cart_outlined),
              ),
              validator: (_) => _validateLimit(_expenseController.numberValue),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fuelController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Combustível',
                helperText: 'Quanto pretende gastar abastecendo por mês. '
                    'Deixe zerado se não tem veículo.',
                helperMaxLines: 2,
                prefixIcon: Icon(Icons.local_gas_station_outlined),
              ),
              validator: (_) => _validateLimit(_fuelController.numberValue),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const TipCard(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Para que servem os limites?',
        message: 'Eles aparecem como barras no Início e, enquanto você não '
            'lança gastos, a projeção usa o limite como estimativa.',
      ),
      const SectionTitle('Uso do seu plano'),
      V2Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(number(account.recordsUsed),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text('de ${number(plan.records)} registros do plano ${plan.name}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            V2ProgressBar(value: usage, color: usageColor(theme, usage)),
            const SizedBox(height: 8),
            Text(
                'Cada ganho, despesa, parcela ou abastecimento conta como um '
                'registro.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      ..._plans.map((p) {
        final isCurrent = p.id == plan.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: V2Card(
            color: isCurrent ? scheme.primaryContainer : null,
            child: Row(
              children: [
                CircleIcon(Icons.workspace_premium_rounded,
                    color:
                        isCurrent ? scheme.primary : scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${number(p.records)} registros',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(p.price,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (isCurrent)
                      const StatusChip('Seu plano', tone: StatusTone.done),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }
}
