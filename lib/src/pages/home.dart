import 'package:cashflow_app/src/components/v2/v2_menu.dart';
import 'package:cashflow_app/src/components/v2/v2_widgets.dart';
import 'package:cashflow_app/src/pages/household_expense_list.dart';
import 'package:cashflow_app/src/pages/household_expense_list_v2.dart';
import 'package:cashflow_app/src/pages/resume/projection_screen.dart';
import 'package:cashflow_app/src/pages/resume/projection_screen_v2.dart';
import 'package:cashflow_app/src/pages/resume/resume_screen.dart';
import 'package:cashflow_app/src/pages/resume/resume_screen_v2.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_list.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_list_v2.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_list.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_list_v2.screen.dart';
import 'package:cashflow_app/src/services/storage.service.dart';
import 'package:cashflow_app/src/utils/app_settings.dart';
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

  static const List<Widget> _screensV1 = [
    ResumeScreen(),
    HouseholdExpenseList(),
    FuelExpenseListScreen(),
    VehicleListScreen(),
    ProjectionScreen(),
  ];

  static const List<Widget> _screensV2 = [
    ResumeScreenV2(),
    HouseholdExpenseListV2(),
    FuelExpenseListV2Screen(),
    VehicleListV2Screen(),
    ProjectionScreenV2(),
  ];

  _incrementTap(index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // A toolbar e o footer seguem o tema claro/escuro das telas v2.
    return ListenableBuilder(
      listenable: Listenable.merge(
          [AppSettings.themeModeV2, AppSettings.screensVersion]),
      builder: (context, _) {
        final theme = V2Theme.data(context);
        final isDark = theme.brightness == Brightness.dark;
        final isV2 = AppSettings.screensVersion.value == 2;

        return Scaffold(
          drawer: isV2
              ? Theme(
                  data: theme,
                  child: V2Menu(currentTab: _index, onSelectTab: _incrementTap),
                )
              : null,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Theme(
              data: theme,
              child: AppBar(
                title: const Text("Bê-a-bá"),
                actions: [
                  IconButton(
                    tooltip: isDark ? 'Usar tema claro' : 'Usar tema escuro',
                    onPressed: () => AppSettings.toggleThemeV2(context),
                    icon: Icon(isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined),
                  ),
                  IconButton(
                    tooltip: isV2
                        ? 'Voltar ao visual clássico'
                        : 'Experimentar o novo visual',
                    onPressed: () =>
                        AppSettings.setScreensVersion(isV2 ? 1 : 2),
                    icon: Icon(isV2
                        ? Icons.history_rounded
                        : Icons.auto_awesome_outlined),
                  ),
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
          body: (isV2 ? _screensV2 : _screensV1)[_index],
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
