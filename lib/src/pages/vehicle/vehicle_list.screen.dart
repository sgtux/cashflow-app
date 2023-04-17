import 'package:cashflow_app/src/models/vehicle/vehicle.model.dart';
import 'package:cashflow_app/src/services/vehicle.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VehicleListScreenStage();
}

class _VehicleListScreenStage extends State<VehicleListScreen> {
  late VehicleService _vehicleService;
  List<VehicleModel> vehicles = [];
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

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : vehicles.isEmpty
              ? const Center(child: Text("Sem registros."))
              : Column(children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                      child: ListView.builder(
                          itemCount: vehicles.length,
                          itemBuilder: (BuildContext ctx, int idx) {
                            return Card(
                                child: ListTile(
                              onLongPress: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Deletar este item?"),
                                        content:
                                            Text(vehicles[idx].description),
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
                                                _vehicleService
                                                    .remove(vehicles[idx].id)
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
                                              child: const Text("Remover"),
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    MaterialStateProperty.all(
                                                        Colors.red.shade400),
                                              ))
                                        ],
                                      );
                                    });
                              },
                              title: Text(vehicles[idx].description),
                              subtitle: Row(children: [
                                Text("${vehicles[idx].miliageTraveled} km")
                              ]),
                              trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Colors.blue.shade300,
                                  onPressed: () {
                                    Navigator.pushNamed(
                                            context, Routes.vehicleDetail,
                                            arguments: vehicles[idx])
                                        .then((value) => refresh());
                                  }),
                            ));
                          }))
                ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Routes.vehicleDetail)
              .then((value) => refresh());
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.addchart),
      ),
    );
  }
}
