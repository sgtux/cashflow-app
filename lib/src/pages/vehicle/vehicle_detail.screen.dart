import 'package:cashflow_app/src/models/vehicle/vehicle.model.dart';
import 'package:cashflow_app/src/services/vehicle.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:flutter/material.dart';

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({Key? key}) : super(key: key);

  @override
  _VehicleDetailScreenState createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late VehicleService vehicleService;
  late bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    vehicleService = VehicleService(context);

    final descriptionController = TextEditingController();

    final vehicle =
        (ModalRoute.of(context)?.settings.arguments as VehicleModel?) ??
            VehicleModel(
                id: 0,
                description: '',
                fuelExpenses: [],
                miliagePerLiter: 0,
                miliageTraveled: 0);

    descriptionController.text = vehicle.description;

    return Scaffold(
        appBar: AppBar(title: const Text("Veículo")),
        body: SingleChildScrollView(
          child: Card(
              child: Form(
                  key: _formKey,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 20.0),
                      // child: Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: descriptionController,
                            decoration:
                                const InputDecoration(labelText: 'Descrição'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Campo obrigatório.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          isLoading
                              ? const CircularProgressIndicator()
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('VOLTAR'),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() {
                                            isLoading = true;
                                          });
                                          final model = VehicleModel(
                                              id: vehicle.id,
                                              description:
                                                  descriptionController.text,
                                              fuelExpenses: [],
                                              miliageTraveled: 0,
                                              miliagePerLiter: 0);
                                          vehicleService
                                              .save(model)
                                              .then((value) {
                                            setState(() => {isLoading = false});
                                            Navigator.of(context).pop();
                                          }).catchError((error) {
                                            setState(() {
                                              isLoading = false;
                                            });
                                            handleHttpException(error, context);
                                          });
                                        }
                                      },
                                      child: const Text('SALVAR'),
                                    )
                                  ],
                                ),
                        ],
                      ))
                  // ),
                  )),
        ));
  }
}
