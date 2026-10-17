import 'dart:math';

import 'package:cashflow_app/src/services/account.service.dart';
import 'package:cashflow_app/src/services/storage.service.dart';
import 'package:cashflow_app/src/utils/app_settings.dart';
import 'package:cashflow_app/src/utils/app_theme.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Nova tela de login, com tema claro/escuro e foco em quem está começando
/// a organizar o dinheiro.
class LoginV2 extends StatelessWidget {
  const LoginV2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.loginThemeMode,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        return Theme(
          data: isDark ? AppTheme.dark : AppTheme.light,
          child: _LoginV2Body(isDark: isDark),
        );
      },
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;

  const _Feature(this.icon, this.title, this.description);
}

const _features = [
  _Feature(Icons.receipt_long_rounded, 'Saiba para onde vai seu dinheiro',
      'Registre gastos da casa e do carro em poucos toques.'),
  _Feature(Icons.speed_rounded, 'Defina limites de gastos',
      'Acompanhe na tela inicial quanto ainda pode gastar no mês.'),
  _Feature(Icons.trending_up_rounded, 'Comece a investir',
      'Veja projeções e entenda como o dinheiro guardado rende.'),
];

const _tips = [
  'Pague-se primeiro: separe uma parte da renda assim que ela cair na conta.',
  'Antes de investir, monte uma reserva de emergência de 3 a 6 meses de gastos.',
  'Anote todos os gastos por um mês. Os pequenos somam mais do que parece.',
  'Juros compostos premiam quem começa cedo, mesmo com pouco.',
  'Dívidas com juros altos, como cartão e cheque especial, vêm antes de investir.',
];

class _LoginV2Body extends StatefulWidget {
  const _LoginV2Body({Key? key, required this.isDark}) : super(key: key);

  final bool isDark;

  @override
  State<_LoginV2Body> createState() => _LoginV2BodyState();
}

class _LoginV2BodyState extends State<_LoginV2Body> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pageController = PageController();
  final _storageService = StorageService();
  final String _tip = _tips[Random().nextInt(_tips.length)];

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  int _currentFeature = 0;

  bool get _isBusy => _isLoading || _isGoogleLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goHome(String token) {
    _storageService.setToken(token);
    Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    try {
      final res = await AccountService(context)
          .login(_emailController.text.trim(), _passwordController.text);
      if (mounted && res != null) _goHome(res.token);
    } catch (error, stackTrace) {
      debugPrint('[Login] Erro: $error\n$stackTrace');
      if (mounted) handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final res = await AccountService(context).googleLogin();
      if (mounted && res != null) _goHome(res.token);
    } on GoogleSignInException catch (error, stackTrace) {
      if (mounted) handleGoogleSignInException(error, stackTrace, context);
    } catch (error, stackTrace) {
      debugPrint('[GoogleLogin] Erro: $error\n$stackTrace');
      if (mounted) handleHttpException(error, context);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _toggleTheme() {
    AppSettings.setLoginThemeMode(
        widget.isDark ? ThemeMode.light : ThemeMode.dark);
  }

  void _switchToClassicLogin() {
    AppSettings.setLoginVersion(1);
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFeatureCarousel(),
                  const SizedBox(height: 28),
                  _buildGoogleButton(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildEmailForm(),
                  const SizedBox(height: 28),
                  _buildTipCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Spacer(),
        IconButton(
          tooltip: widget.isDark ? 'Usar tema claro' : 'Usar tema escuro',
          onPressed: _toggleTheme,
          icon: Icon(widget.isDark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined),
        ),
        Flexible(
          child: TextButton.icon(
            onPressed: _isBusy ? null : _switchToClassicLogin,
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            label: const Text('Login clássico',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(Icons.savings_rounded, size: 40, color: scheme.onPrimary),
        ),
        const SizedBox(height: 20),
        Text(
          'Bem-vindo ao Cashflow',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Organize seu dinheiro e dê os primeiros passos para investir.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildFeatureCarousel() {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          // Acompanha o tamanho de fonte escolhido nas configurações do celular.
          height: MediaQuery.textScalerOf(context).scale(112),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _features.length,
            onPageChanged: (index) => setState(() => _currentFeature = index),
            itemBuilder: (context, index) => _FeatureCard(_features[index]),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_features.length, (index) {
            final selected = index == _currentFeature;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _isBusy ? null : _loginWithGoogle,
      icon: _isGoogleLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const FaIcon(FontAwesomeIcons.google, size: 18),
      label: const Text('Continuar com Google'),
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              'ou entre com seu email',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              enabled: !_isBusy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) return 'Informe seu email';
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              enabled: !_isBusy,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _loginWithEmail(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Informe sua senha' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isBusy ? null : _loginWithEmail,
              child: _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Theme.of(context).colorScheme.onPrimary))
                  : const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              color: scheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dica para começar',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _tip,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSecondaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(this.feature, {Key? key}) : super(key: key);

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(feature.icon, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    feature.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
