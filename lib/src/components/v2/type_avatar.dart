import 'package:flutter/material.dart';

/// Ids dos tipos de despesa doméstica (mesmos da API).
class ExpenseTypes {
  static const food = 1;
  static const market = 2;
  static const snack = 3;
  static const aesthetics = 4;
  static const education = 5;
  static const vehicle = 6;
  static const pets = 7;
  static const leisure = 8;
  static const hardDrink = 9;
  static const party = 10;
  static const transport = 11;
  static const lateFees = 12;
  static const clothes = 13;
  static const utilities = 14;
  static const cleaning = 15;
  static const exchange = 16;
  static const investiment = 17;
  static const phone = 18;
  static const games = 19;
  static const others = 20;
  static const donation = 21;
  static const streams = 22;
  static const loan = 23;
  static const financing = 24;
  static const tech = 25;
  static const bills = 26;
  static const housing = 27;
}

/// Ids dos tipos de ganho (mesmos da API).
class EarningTypes {
  static const salary = 1;
  static const freelance = 2;
  static const bonus = 3;
  static const retirement = 4;
  static const rent = 5;
  static const dividends = 6;
  static const interest = 7;
  static const business = 8;
  static const royalties = 9;
  static const sale = 10;
  static const gift = 11;
  static const refund = 12;
  static const others = 20;
}

class _TypeStyle {
  const _TypeStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}

const Map<int, _TypeStyle> _expenseStyles = {
  ExpenseTypes.food: _TypeStyle(Icons.restaurant, Color(0xFFE07A5F)),
  ExpenseTypes.market: _TypeStyle(Icons.local_grocery_store, Color(0xFF3D9970)),
  ExpenseTypes.snack: _TypeStyle(Icons.fastfood, Color(0xFFF4A259)),
  ExpenseTypes.aesthetics: _TypeStyle(Icons.auto_fix_high, Color(0xFFB565A7)),
  ExpenseTypes.education: _TypeStyle(Icons.school, Color(0xFF2F6FB2)),
  ExpenseTypes.vehicle: _TypeStyle(Icons.time_to_leave, Color(0xFF5B7C99)),
  ExpenseTypes.pets: _TypeStyle(Icons.pets, Color(0xFF8D6E63)),
  ExpenseTypes.leisure: _TypeStyle(Icons.kitesurfing, Color(0xFF00A6A6)),
  ExpenseTypes.hardDrink: _TypeStyle(Icons.liquor, Color(0xFF9C4F96)),
  ExpenseTypes.party: _TypeStyle(Icons.celebration, Color(0xFFE85D75)),
  ExpenseTypes.transport: _TypeStyle(Icons.airport_shuttle, Color(0xFF4A6FA5)),
  ExpenseTypes.lateFees: _TypeStyle(Icons.percent, Color(0xFFD1495B)),
  ExpenseTypes.clothes: _TypeStyle(Icons.dry_cleaning, Color(0xFF7E6BC4)),
  ExpenseTypes.utilities: _TypeStyle(Icons.handyman, Color(0xFF6C757D)),
  ExpenseTypes.cleaning: _TypeStyle(Icons.sanitizer, Color(0xFF4FB0C6)),
  ExpenseTypes.exchange: _TypeStyle(Icons.currency_exchange, Color(0xFF1F7A5A)),
  ExpenseTypes.investiment: _TypeStyle(Icons.savings, Color(0xFF1F7A5A)),
  ExpenseTypes.phone: _TypeStyle(Icons.smartphone, Color(0xFF2A9D8F)),
  ExpenseTypes.games: _TypeStyle(Icons.sports_esports, Color(0xFF6A4C93)),
  ExpenseTypes.donation:
      _TypeStyle(Icons.volunteer_activism, Color(0xFFE76F51)),
  ExpenseTypes.streams: _TypeStyle(Icons.live_tv, Color(0xFFC1121F)),
  ExpenseTypes.loan: _TypeStyle(Icons.account_balance, Color(0xFFB5651D)),
  ExpenseTypes.financing: _TypeStyle(Icons.request_quote, Color(0xFF9A6324)),
  ExpenseTypes.tech: _TypeStyle(Icons.computer, Color(0xFF264653)),
  ExpenseTypes.bills: _TypeStyle(Icons.lightbulb, Color(0xFFE9B824)),
  ExpenseTypes.housing: _TypeStyle(Icons.home, Color(0xFF7B4B2A)),
  ExpenseTypes.others: _TypeStyle(Icons.more, Color(0xFF8A8F98)),
};

const Map<int, _TypeStyle> _earningStyles = {
  EarningTypes.salary: _TypeStyle(Icons.work, Color(0xFF2F6FB2)),
  EarningTypes.freelance: _TypeStyle(Icons.laptop_mac, Color(0xFF4A6FA5)),
  EarningTypes.bonus: _TypeStyle(Icons.emoji_events, Color(0xFFF4A259)),
  EarningTypes.retirement: _TypeStyle(Icons.elderly, Color(0xFF8D6E63)),
  EarningTypes.rent: _TypeStyle(Icons.house, Color(0xFF3D9970)),
  EarningTypes.dividends: _TypeStyle(Icons.show_chart, Color(0xFF1F7A5A)),
  EarningTypes.interest: _TypeStyle(Icons.savings, Color(0xFF00A6A6)),
  EarningTypes.business: _TypeStyle(Icons.storefront, Color(0xFF7E6BC4)),
  EarningTypes.royalties: _TypeStyle(Icons.copyright, Color(0xFFB565A7)),
  EarningTypes.sale: _TypeStyle(Icons.sell, Color(0xFFE07A5F)),
  EarningTypes.gift: _TypeStyle(Icons.card_giftcard, Color(0xFFE85D75)),
  EarningTypes.refund: _TypeStyle(Icons.replay, Color(0xFF5B7C99)),
  EarningTypes.others: _TypeStyle(Icons.more, Color(0xFF8A8F98)),
};

_TypeStyle _expenseStyle(int? type) =>
    _expenseStyles[type] ?? _expenseStyles[ExpenseTypes.others]!;

_TypeStyle _earningStyle(int? type) =>
    _earningStyles[type] ?? _earningStyles[EarningTypes.others]!;

/// Cor do tipo de despesa, usada também nas barras do resumo do mês.
Color expenseTypeColor(int? type) => _expenseStyle(type).color;

class _TypeAvatar extends StatelessWidget {
  const _TypeAvatar(this.style, {required this.size});

  final _TypeStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
      child: Icon(style.icon, size: size * 0.55, color: Colors.white),
    );
  }
}

/// Ícone colorido do tipo de despesa, igual ao do site.
class ExpenseTypeAvatar extends StatelessWidget {
  const ExpenseTypeAvatar({Key? key, required this.type, this.size = 40})
      : super(key: key);

  final int? type;
  final double size;

  @override
  Widget build(BuildContext context) =>
      _TypeAvatar(_expenseStyle(type), size: size);
}

/// Ícone colorido do tipo de ganho, igual ao do site.
class EarningTypeAvatar extends StatelessWidget {
  const EarningTypeAvatar({Key? key, required this.type, this.size = 40})
      : super(key: key);

  final int? type;
  final double size;

  @override
  Widget build(BuildContext context) =>
      _TypeAvatar(_earningStyle(type), size: size);
}
