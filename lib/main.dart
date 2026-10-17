import 'package:cashflow_app/src/pages/household_expense_detail.dart';
import 'package:cashflow_app/src/pages/household_expense_detail_v2.dart';
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
      },
    );
  }
}
