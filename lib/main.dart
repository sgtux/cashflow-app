import 'package:cashflow_app/src/models/recurring/recurring_model.dart';
import 'package:cashflow_app/src/pages/account_v2.screen.dart';
import 'package:cashflow_app/src/pages/credit-card/credit_card_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/credit-card/credit_card_list_v2.screen.dart';
import 'package:cashflow_app/src/pages/earning/earning_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/earning/earning_list_v2.screen.dart';
import 'package:cashflow_app/src/pages/glossary_v2.screen.dart';
import 'package:cashflow_app/src/pages/household_expense_detail.dart';
import 'package:cashflow_app/src/pages/household_expense_detail_v2.dart';
import 'package:cashflow_app/src/pages/payment/payment_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/payment/payment_list_v2.screen.dart';
import 'package:cashflow_app/src/pages/recurring/recurring_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/recurring/recurring_list_v2.screen.dart';
import 'package:cashflow_app/src/pages/remaining_balance_v2.screen.dart';
import 'package:cashflow_app/src/pages/splash_screen.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_detail.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_list.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_detail.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_detail_v2.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_list.screen.dart';
import 'package:cashflow_app/src/utils/app_settings.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'src/pages/home.dart';
import 'src/pages/login.dart';
import 'src/pages/login_v2.dart';
import 'src/pages/household_expense_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalStorage();
  AppSettings.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static bool get _isV2 => AppSettings.screensVersion.value == 2;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashflow App',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.home: (context) => const Home(),
        Routes.login: (context) => AppSettings.loginVersion.value == 2
            ? const LoginV2()
            : const Login(),
        Routes.householdExpenseList: (context) => const HouseholdExpenseList(),
        Routes.householdExpenseDetail: (context) => _isV2
            ? const HouseholdExpenseDetailV2()
            : const HouseholdExpenseDetail(),
        Routes.vehicleList: (context) => const VehicleListScreen(),
        Routes.vehicleDetail: (context) =>
            _isV2 ? const VehicleDetailV2Screen() : const VehicleDetailScreen(),
        Routes.fuelExpenseList: (context) => const FuelExpenseListScreen(),
        Routes.fuelExpenseDetail: (context) => _isV2
            ? const FuelExpenseDetailV2Screen()
            : const FuelExpenseDetailScreen(),
        // Funcionalidades que só existem no novo visual (menu lateral da v2).
        Routes.earningList: (context) => const EarningListV2Screen(),
        Routes.earningDetail: (context) => const EarningDetailV2Screen(),
        Routes.recurringEarningList: (context) =>
            const RecurringListV2Screen(kind: RecurringKind.earning),
        Routes.recurringExpenseList: (context) =>
            const RecurringListV2Screen(kind: RecurringKind.expense),
        Routes.recurringDetail: (context) => const RecurringDetailV2Screen(),
        Routes.paymentList: (context) => const PaymentListV2Screen(),
        Routes.paymentDetail: (context) => const PaymentDetailV2Screen(),
        Routes.creditCardList: (context) => const CreditCardListV2Screen(),
        Routes.creditCardDetail: (context) => const CreditCardDetailV2Screen(),
        Routes.remainingBalance: (context) => const RemainingBalanceV2Screen(),
        Routes.account: (context) => const AccountV2Screen(),
        Routes.glossary: (context) => const GlossaryV2Screen(),
      },
    );
  }
}
