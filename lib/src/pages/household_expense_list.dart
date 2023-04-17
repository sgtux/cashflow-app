import 'package:cashflow_app/src/models/household-expense/household_expense_model.dart';
import 'package:cashflow_app/src/services/household_expense.service.dart';
import 'package:cashflow_app/src/utils/constants.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

typedef RemoveCallback = void Function(int id);

class HouseholdExpenseList extends StatefulWidget {
  const HouseholdExpenseList({Key? key}) : super(key: key);

  @override
  _HouseholdExpenseListState createState() => _HouseholdExpenseListState();
}

class _HouseholdExpenseListState extends State<HouseholdExpenseList> {
  late HouseholdExpenseService householdExpenseService;
  late List<HouseholdExpenseModel> list = [];
  late bool isLoading = true;
  late String? selectedYear;
  late String? selectedMonth;
  double total = 0;

  @override
  void initState() {
    super.initState();
    isLoading = true;

    final now = DateTime.now();
    selectedYear = now.year.toString();
    final months = getMonthList();
    selectedMonth = months[now.month - 1];

    WidgetsBinding.instance?.addPostFrameCallback((_) => refresh());
  }

  void refresh() {
    setState(() {
      isLoading = true;
      list = [];
      total = 0;
    });
    final month = getMonthList().indexOf(selectedMonth.toString()) + 1;
    householdExpenseService
        .getSome(month.toString(), selectedYear.toString())
        .then((value) {
      double sum = 0;
      for (var item in value) {
        sum += item.value;
      }

      setState(() => {list = value, isLoading = false, total = sum});
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });
      handleHttpException(err, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    householdExpenseService = HouseholdExpenseService(context);

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              const SizedBox(
                height: 10,
              ),
              Row(children: [
                const SizedBox(width: 40),
                DropdownButton(
                    value: selectedYear,
                    items: getYearList()
                        .map((String e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedYear = newValue;
                      });
                    }),
                const SizedBox(width: 20),
                DropdownButton(
                    value: selectedMonth,
                    items: getMonthList()
                        .map((String e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMonth = newValue;
                      });
                    }),
                const SizedBox(width: 20),
                ElevatedButton(
                    onPressed: () {
                      refresh();
                    },
                    child: const Text('FILTRAR'))
              ]),
              list.isEmpty
                  ? const Center(child: Text("Sem registros."))
                  : Text(
                      toReal(value: total),
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.red.shade300,
                          fontWeight: FontWeight.bold),
                    ),
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
                                          content: Text(list[idx].description),
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
                                                  householdExpenseService
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
                                title: Text(elipsis(list[idx].description, 30)),
                                subtitle: Row(children: [
                                  Text(
                                    toReal(value: list[idx].value),
                                    style: TextStyle(
                                        color: Colors.red.shade300,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text(" - "),
                                  Text(toDateString(value: list[idx].date)),
                                  const Text(" - "),
                                  Text(list[idx].typeDescription!),
                                  const Text(" - "),
                                  list[idx].vehicleId != null
                                      ? const Icon(
                                          Icons.car_rental,
                                          color: Colors.grey,
                                        )
                                      : const SizedBox()
                                ]),
                                trailing: IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {
                                      Navigator.pushNamed(context,
                                              Routes.householdExpenseDetail,
                                              arguments: list[idx])
                                          .then((value) => refresh());
                                    })));
                      }))
            ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Routes.householdExpenseDetail)
              .then((value) => refresh());
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.addchart),
      ),
    );
  }
}
