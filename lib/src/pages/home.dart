import 'package:cashflow_app/src/pages/household_expense_list.dart';
import 'package:cashflow_app/src/pages/resume/projection_screen.dart';
import 'package:cashflow_app/src/pages/resume/resume_screen.dart';
import 'package:cashflow_app/src/pages/vehicle/fuel_expense_list.screen.dart';
import 'package:cashflow_app/src/pages/vehicle/vehicle_list.screen.dart';
import 'package:cashflow_app/src/services/storage.service.dart';
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

  final List<Widget> _screens = const [
    ResumeScreen(),
    HouseholdExpenseList(),
    FuelExpenseListScreen(),
    VehicleListScreen(),
    ProjectionScreen()
  ];

  _incrementTap(index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CASHFLOW"),
        actions: [
          ButtonBar(
            alignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton(
                  child: const Text('Sair'),
                  onPressed: () {
                    storageService.setToken('');
                    Navigator.pushNamedAndRemoveUntil(
                        context, Routes.login, (_) => false);
                  }),
            ],
          )
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: const IconThemeData(size: 40),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        selectedLabelStyle: const TextStyle(fontSize: 10),
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
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
    );
  }
}
