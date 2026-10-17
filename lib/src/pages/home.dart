import 'package:cashflow_app/src/pages/household_expense_list.dart';
import 'package:cashflow_app/src/pages/resume/projection_screen.dart';
import 'package:cashflow_app/src/pages/resume/projection_screen_v2.dart';
import 'package:cashflow_app/src/pages/resume/resume_screen.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_list.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_list.screen.dart';
import 'package:cashflow_app/src/services/storage.service.dart';
import 'package:cashflow_app/src/utils/app_settings.dart';
import 'package:cashflow_app/src/utils/app_theme.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import "package:flutter/material.dart";

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final StorageService storageService = StorageService();
  int _index = 0;

  final List<Widget> _screens = [
    const ResumeScreen(),
    const HouseholdExpenseList(),
    const FuelExpenseListScreen(),
    const VehicleListScreen(),
    ValueListenableBuilder<int>(
      valueListenable: AppSettings.projectionVersion,
      builder: (context, version, _) =>
          version == 2 ? const ProjectionScreenV2() : const ProjectionScreen(),
    ),
  ];

  _incrementTap(index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // A toolbar e o footer seguem o tema claro/escuro das telas v2.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeV2,
      builder: (context, _, __) {
        final theme =
            AppSettings.isDarkV2(context) ? AppTheme.dark : AppTheme.light;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Theme(
              data: theme,
              child: AppBar(
                title: const Text("CASHFLOW"),
                actions: [
                  TextButton(
                      child: const Text('Sair'),
                      onPressed: () {
                        storageService.setToken('');
                        Navigator.pushNamedAndRemoveUntil(
                            context, Routes.login, (_) => false);
                      }),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          body: _screens[_index],
          bottomNavigationBar: Theme(
            data: theme,
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedIconTheme: const IconThemeData(size: 40),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              selectedLabelStyle: const TextStyle(fontSize: 10),
              currentIndex: _index,
              elevation: 5,
              onTap: (idx) {
                _incrementTap(idx);
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart), label: 'Despesas'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.local_gas_station), label: 'Combustível'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.car_rental), label: 'Veículos'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart), label: 'Projeção'),
              ],
            ),
          ),
        );
      },
    );
  }
}
