import 'package:cashflow_app/src/models/home/invoice_payment_model.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

class ProjectionPaymentInvoiceContainer extends StatefulWidget {
  final List<InvoicePaymentModel> invoicePayments;

  const ProjectionPaymentInvoiceContainer(
      {Key? key, required this.invoicePayments})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      _ProjectionPaymentInvoiceContainerState(invoicePayments);
}

class _ProjectionPaymentInvoiceContainerState
    extends State<ProjectionPaymentInvoiceContainer> {
  final List<InvoicePaymentModel> invoicePayments;

  String expandedCard = '';

  _ProjectionPaymentInvoiceContainerState(this.invoicePayments);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
            margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
            child: Column(children: [
              ExpansionPanelList(
                expandedHeaderPadding: EdgeInsets.all(0),
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    expandedCard = isExpanded ? '' : invoicePayments[index].creditCardName;
                  });
                },
                children: invoicePayments
                    .map<ExpansionPanel>((InvoicePaymentModel item) {
                  return ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Row(children: [
                          Text(
                            "${item.creditCardName} - ",
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                          Text(
                            toReal(value: item.total),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade300,
                            ),
                          ),
                        ]),
                      );
                    },
                    body: Column(
                        children: item.payments
                            .map((p) => Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                color: item.payments.indexOf(p) % 2 == 0
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade300,
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        elipsis(p.description, 30),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                      p.qtdInstallments > 0
                                          ? Text(
                                              "${p.number}/${p.qtdInstallments}",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade600),
                                            )
                                          : const SizedBox(),
                                      Text(
                                        toReal(value: p.value.toDouble()),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: p.isIn
                                                ? Colors.green.shade300
                                                : Colors.red.shade300),
                                      )
                                    ])))
                            .toList()),
                    isExpanded:  expandedCard == item.creditCardName,
                  );
                }).toList(),
              )
            ])));
  }
}
