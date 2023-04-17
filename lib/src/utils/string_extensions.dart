import 'package:flutter_masked_text/flutter_masked_text.dart';

String toReal({required double value}) {
  final controller =
      MoneyMaskedTextController(decimalSeparator: '.', thousandSeparator: ',');
  controller.updateValue(value);
  return "R\$ ${controller.text}";
}

String toDateString({required DateTime? value, String? separator}) {
  if (value == null) return '';
  if (separator == null || separator.isEmpty) separator = '-';
  String day = "${value.day}".padLeft(2, '0');
  String month = "${value.month}".padLeft(2, '0');
  return "$day$separator$month$separator${value.year}";
}

String elipsis(String? text, int length) {
  if (text == null || text.length <= length) return text ?? '';
  return "${text.substring(0, length)}...";
}

List<String> getYearList() {
  List<String> list = [];
  final now = DateTime.now();
  for (int i = -2; i < 1; i++) {
    list.add((now.year + i).toString());
  }
  return list;
}

List<String> getMonthList() {
  return [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];
}

String toMonthYearText(String monthYear) {
  var arr = monthYear.split("/");
  return "${getMonthList()[int.parse(arr[0]) - 1]}/${arr[1]}";
}
