import 'package:intl/intl.dart';
final money=NumberFormat.currency(symbol:'KSh ',decimalDigits:2);
final shortDate=DateFormat('dd MMM yyyy');
String compactMoney(double v)=>NumberFormat.compactCurrency(symbol:'KSh ',decimalDigits:1).format(v);
