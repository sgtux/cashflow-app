import 'package:cashflow_app/firebase_options.dart';
import 'package:cashflow_app/src/pages/household_expense_detail.dart';
import 'package:cashflow_app/src/pages/splash_screen.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_detail.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_list.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_detail.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_list.screen.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'src/pages/home.dart';
import 'src/pages/login.dart';
import 'src/pages/household_expense_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashflow App',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.home: (context) => const Home(),
        Routes.login: (context) => const Login(),
        Routes.householdExpenseList: (context) => const HouseholdExpenseList(),
        Routes.householdExpenseDetail: (context) =>
            const HouseholdExpenseDetail(),
        Routes.vehicleList: (context) => const VehicleListScreen(),
        Routes.vehicleDetail: (context) => const VehicleDetailScreen(),
        Routes.fuelExpenseList: (context) => const FuelExpenseListScreen(),
        Routes.fuelExpenseDetail: (context) => const FuelExpenseDetailScreen(),
      },
    );
  }
}
