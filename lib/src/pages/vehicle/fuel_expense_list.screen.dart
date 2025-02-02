import 'package:cashflow_app/src/models/vehicle/fuel_expense.model.dart';
import 'package:cashflow_app/src/models/vehicle/vehicle.model.dart';
import 'package:cashflow_app/src/services/fuel_expense.service.dart';
import 'package:cashflow_app/src/services/vehicle.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

class FuelExpenseListScreen extends StatefulWidget {
  const FuelExpenseListScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FuelExpenseListScreenState();
}

class _FuelExpenseListScreenState extends State<FuelExpenseListScreen> {
  late VehicleService _vehicleService;
  late FuelExpenseService _fuelExpenseService;
  List<VehicleModel> vehicles = [];
  List<FuelExpenseModel> list = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => refresh());
  }

  void refresh() {
    setState(() {
      isLoading = true;
    });
    _vehicleService.getAll().then((value) {
      setState(() {
        vehicles = value;
        isLoading = false;

        list.clear();
        for (var item in value) {
          list.addAll(item.fuelExpenses);
        }
        list.sort((a, b) => b.date.compareTo(a.date));
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      handleHttpException(error, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    _vehicleService = VehicleService(context);
    _fuelExpenseService = FuelExpenseService(context);

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(
                  child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (BuildContext ctx, int idx) {
                        return Card(
                            child: ListTile(
                                onLongPress: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title:
                                              const Text("Deletar este item?"),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text("Cancelar")),
                                            ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  setState(() {
                                                    isLoading = true;
                                                  });
                                                  _fuelExpenseService
                                                      .remove(list[idx].id)
                                                      .then((res) {
                                                    refresh();
                                                  }).catchError((error) {
                                                    handleHttpException(
                                                        error, context);
                                                    setState(() {
                                                      isLoading = false;
                                                    });
                                                  });
                                                },
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStateProperty.all(
                                                          Colors.red.shade400),
                                                ),
                                                child: const Text("Remover"))
                                          ],
                                        );
                                      });
                                },
                                title: Text(list[idx].vehicleName),
                                subtitle: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          "${list[idx].miliage.toString()} Km"),
                                      Text(
                                        toReal(
                                            value: list[idx]
                                                .valueSupplied
                                                .toDouble()),
                                        style: TextStyle(
                                            color: Colors.red.shade300,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(toDateString(value: list[idx].date)),
                                    ]),
                                trailing: IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {
                                      Map<String, dynamic> args = {};
                                      args['vehicles'] = vehicles;
                                      args['fuelExpenseModel'] = list[idx];
                                      Navigator.pushNamed(
                                              context, Routes.fuelExpenseDetail,
                                              arguments: args)
                                          .then((value) => refresh());
                                    })));
                      }))
            ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (vehicles.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Sem veículos cadastrados.'),
              backgroundColor: Colors.red,
            ));
            return;
          }
          Map<String, dynamic> args = {};
          args['vehicles'] = vehicles;
          args['fuelExpenseModel'] = FuelExpenseModel(
              id: 0,
              vehicleId: 0,
              miliage: 0,
              pricePerLiter: 0,
              valueSupplied: 0,
              date: DateTime.now(),
              vehicleName: "");
          Navigator.pushNamed(context, Routes.fuelExpenseDetail,
                  arguments: args)
              .then((value) => refresh());
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.addchart),
      ),
    );
  }
}
