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
  List<HomeDataModel> list = [];
  final List<Color?> listColors = [
    Colors.red,
    Colors.orange.shade600,
    Colors.orange.shade800,
    Colors.blue.shade300,
    Colors.blue.shade800,
    Colors.green.shade700,
    Colors.green.shade900,
    Colors.green.shade500,
  ];

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
        list = value;
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(
                  child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (BuildContext ctx, int idx) {
                        return Card(
                            child: ListTile(
                          title: Text(toReal(value: list[idx].value.toDouble()),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: listColors[list[idx].index])),
                          subtitle: Text(
                            list[idx].description,
                            style: TextStyle(
                                fontSize: 12,
                                color: listColors[list[idx].index]),
                          ),
                        ));
                      }))
            ]),
    );
  }
}
