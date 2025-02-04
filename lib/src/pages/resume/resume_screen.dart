import 'package:cashflow_app/src/models/home/home_data_model.dart';
import 'package:cashflow_app/src/services/home.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  late HomeService homeService;
  bool isLoading = false;
  HomeDataModel homeDataModel = HomeDataModel.initialValue();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => refresh());
  }

  void refresh() {
    setState(() {
      isLoading = true;
    });
    homeService.getHomeData().then((value) {
      setState(() {
        isLoading = false;
        homeDataModel = value;
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
    homeService = HomeService(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Card(
              child: Column(children: [
                const SizedBox(height: 10),
                const Text("LIMITES"),
                ListView.builder(
                    itemCount: homeDataModel.limitValues.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext ctx, int idx) {
                      return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          child: Column(children: [
                            Text(
                              homeDataModel.limitValues[idx].description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            LinearProgressIndicator(
                              value: homeDataModel.limitValues[idx].percent
                                  .toDouble(),
                              backgroundColor: Colors.grey.shade300,
                              color: homeDataModel.limitValues[idx].color,
                              minHeight: 14,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(6)),
                            ),
                            Text(
                                "${toReal(value: homeDataModel.limitValues[idx].spent.toDouble())} / ${toReal(value: homeDataModel.limitValues[idx].limit.toDouble())}",
                                style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        homeDataModel.limitValues[idx].color)),
                          ]));
                    }),
                const Divider(),
                const SizedBox(height: 4),
                const Text("PENDÊNCIAS"),
                ListView.builder(
                    itemCount: homeDataModel.pendingPayments.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext ctx, int idx) {
                      return Card(
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      homeDataModel
                                          .pendingPayments[idx].description,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                        toReal(
                                            value: homeDataModel
                                                .pendingPayments[idx].value
                                                .toDouble()),
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.red)),
                                  ])));
                    }),
                const Divider(),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("ENTRADAS - "),
                  Text(
                    toReal(value: homeDataModel.totalInflows.toDouble()),
                    style: const TextStyle(color: Colors.green),
                  )
                ]),
                ListView.builder(
                    itemCount: homeDataModel.inflows.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext ctx, int idx) {
                      return Card(
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      homeDataModel.inflows[idx].description,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                        toReal(
                                            value: homeDataModel
                                                .inflows[idx].value
                                                .toDouble()),
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.green)),
                                  ])));
                    }),
                const Divider(),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("SAÍDAS - "),
                  Text(
                    toReal(value: homeDataModel.totalOutflows.toDouble()),
                    style: const TextStyle(color: Colors.red),
                  )
                ]),
                ListView.builder(
                    itemCount: homeDataModel.outflows.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext ctx, int idx) {
                      return Card(
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      homeDataModel.outflows[idx].description,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                        toReal(
                                            value: homeDataModel
                                                .outflows[idx].value
                                                .toDouble()),
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.red)),
                                  ])));
                    })
              ]),
            )),
    );
  }
}
