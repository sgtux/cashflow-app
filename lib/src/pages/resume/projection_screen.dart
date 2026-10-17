import 'package:cashflow_app/src/components/projection_payment_month_container.dart';
import 'package:cashflow_app/src/models/home/projection_model.dart';
import 'package:cashflow_app/src/services/home.service.dart';
import 'package:cashflow_app/src/utils/exception_handler.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

class ProjectionScreen extends StatefulWidget {
  const ProjectionScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends State<ProjectionScreen> {
  late HomeService homeService;
  bool isLoading = false;
  List<ProjectionModel> list = [];
  String selectedMonthYear = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => refresh());
  }

  void refresh() {
    setState(() {
      isLoading = true;
    });
    homeService.getProjection().then((value) {
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

    return isLoading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : SingleChildScrollView(
            child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            ExpansionPanelList(
              expandedHeaderPadding: const EdgeInsets.all(0),
              expansionCallback: (int index, bool isCollapsed) {
                setState(() {
                  selectedMonthYear = isCollapsed ? list[index].monthYear : '';
                });
              },
              children: list.map<ExpansionPanel>((ProjectionModel item) {
                return ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(
                      title: Row(children: [
                        Text("${toMonthYearText(item.monthYear)} - ",
                            style: TextStyle(color: Colors.grey.shade600)),
                        Text(
                          toReal(value: item.accumulatedValue.toDouble()),
                          style: TextStyle(
                              color: item.accumulatedValue > 0
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                              fontWeight: FontWeight.bold),
                        ),
                      ]),
                    );
                  },
                  body: ProjectionPaymentMonthContainer(model: item),
                  isExpanded: selectedMonthYear == item.monthYear,
                );
              }).toList(),
            )
          ]));
  }
}
