import 'package:cashflow_app/src/utils/app_settings.dart';
import 'package:cashflow_app/src/utils/app_theme.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Aplica o tema claro/escuro das telas v2 e reconstrói quando o modo muda.
class V2Theme extends StatelessWidget {
  const V2Theme({Key? key, required this.child}) : super(key: key);

  final Widget child;

  static ThemeData data(BuildContext context) =>
      AppSettings.isDarkV2(context) ? AppTheme.dark : AppTheme.light;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeV2,
      builder: (context, _, __) => Theme(data: data(context), child: child),
    );
  }
}

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Valor em reais no padrão brasileiro, com sinal quando negativo
/// (ex.: R$ 1.234,56 / -R$ 80,00).
String money(num value) => _currency.format(value);

/// Valor com sinal explícito (ex.: + R$ 500,00 / - R$ 80,00).
String signedMoney(num value) =>
    '${value < 0 ? '-' : '+'} ${_currency.format(value.abs())}';

/// Número no padrão brasileiro (ex.: 45.320 / 11,5).
String number(num value, {int decimals = 0}) =>
    NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: decimals)
        .format(value);

/// "Outubro de 2026".
String monthYearLabel(int month, int year) =>
    '${getMonthList()[month - 1]} de $year';

/// "17 de outubro".
String dayMonthLabel(DateTime date) =>
    '${date.day} de ${getMonthList()[date.month - 1].toLowerCase()}';

Color inColor(ColorScheme scheme) => scheme.primary;

Color outColor(ColorScheme scheme) => scheme.error;

Color signedColor(ColorScheme scheme, num value) =>
    value >= 0 ? inColor(scheme) : outColor(scheme);

Color warningColor(ThemeData theme) => theme.brightness == Brightness.dark
    ? Colors.amber.shade300
    : Colors.amber.shade800;

/// Cor de uma barra de uso (limite, gasto/renda): verde até 80%, âmbar até
/// 100% e vermelho acima.
Color usageColor(ThemeData theme, num ratio) {
  if (ratio >= 1) return theme.colorScheme.error;
  if (ratio >= 0.8) return warningColor(theme);
  return theme.colorScheme.primary;
}

/// Pede confirmação antes de excluir. Retorna true se o usuário confirmou.
Future<bool> confirmDelete(BuildContext context,
    {required String title, String? message}) async {
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(88, 40),
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Título de tela com subtítulo explicativo.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({Key? key, required this.title, this.subtitle})
      : super(key: key);

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

/// Título de seção, com um complemento opcional à direita.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {Key? key, this.trailing}) : super(key: key);

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Bloco com fundo arredondado usado como cartão nas telas v2.
class V2Card extends StatelessWidget {
  const V2Card(
      {Key? key,
      required this.child,
      this.color,
      this.padding = const EdgeInsets.all(16),
      this.onTap})
      : super(key: key);

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Cartão de dica em linguagem simples.
class TipCard extends StatelessWidget {
  const TipCard(
      {Key? key,
      required this.icon,
      required this.title,
      required this.message,
      this.isWarning = false})
      : super(key: key);

  final IconData icon;
  final String title;
  final String message;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        isWarning ? scheme.errorContainer : scheme.secondaryContainer;
    final foreground =
        isWarning ? scheme.onErrorContainer : scheme.onSecondaryContainer;

    return V2Card(
      color: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: foreground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensagem centralizada para estados vazios e de erro.
class MessageCard extends StatelessWidget {
  const MessageCard(
      {Key? key,
      required this.icon,
      required this.title,
      required this.message,
      this.actionLabel,
      this.onAction})
      : super(key: key);

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Estado de erro padrão, com botão para tentar de novo.
  factory MessageCard.error({required String title, VoidCallback? onRetry}) {
    return MessageCard(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: 'Verifique sua conexão e tente de novo.',
      actionLabel: 'Tentar novamente',
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return V2Card(
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: scheme.primary),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Seletor de mês com setas para o mês anterior e o próximo.
class MonthSelector extends StatelessWidget {
  const MonthSelector(
      {Key? key,
      required this.month,
      required this.year,
      required this.onChanged,
      this.enabled = true})
      : super(key: key);

  final int month;
  final int year;
  final void Function(int month, int year) onChanged;
  final bool enabled;

  void _move(int delta) {
    final date = DateTime(year, month + delta);
    onChanged(date.month, date.year);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return V2Card(
      color: theme.colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            onPressed: enabled ? () => _move(-1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              monthYearLabel(month, year),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            onPressed: enabled ? () => _move(1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// Ícone redondo usado à esquerda dos itens de lista.
class CircleIcon extends StatelessWidget {
  const CircleIcon(this.icon, {Key? key, required this.color, this.size = 40})
      : super(key: key);

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Item que pode ser excluído deslizando para a esquerda.
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete(
      {required Key key,
      required this.child,
      required this.confirmTitle,
      required this.onDelete,
      required this.onDeleted,
      this.confirmMessage})
      : super(key: key);

  final Widget child;
  final String confirmTitle;
  final String? confirmMessage;

  /// Exclui de fato; retorna true se deu certo.
  final Future<bool> Function() onDelete;

  /// Chamado depois que o item sai da tela; deve removê-lo da lista.
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        final confirmed = await confirmDelete(context,
            title: confirmTitle, message: confirmMessage);
        if (!confirmed) return false;
        return onDelete();
      },
      onDismissed: (_) => onDeleted(),
      child: child,
    );
  }
}

/// Botão principal fixo no rodapé dos formulários.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar(
      {Key? key,
      required this.label,
      required this.onPressed,
      this.isLoading = false})
      : super(key: key);

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: scheme.onPrimary))
              : Text(label),
        ),
      ),
    );
  }
}
