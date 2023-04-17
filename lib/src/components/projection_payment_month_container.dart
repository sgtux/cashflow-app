import 'package:cashflow_app/src/components/projection_payment_invoice_month_container.dart';
import 'package:cashflow_app/src/models/home/invoice_payment_model.dart';
import 'package:cashflow_app/src/models/home/payment_projection_model.dart';
import 'package:cashflow_app/src/models/home/projection_model.dart';
import 'package:cashflow_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';

class ProjectionPaymentMonthContainer extends StatefulWidget {
  final ProjectionModel model;

  const ProjectionPaymentMonthContainer({Key? key, required this.model})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      _ProjectionPaymentMonthContainerState(model);
}

class _ProjectionPaymentMonthContainerState
    extends State<ProjectionPaymentMonthContainer> {
  final ProjectionModel model;

  List<PaymentProjectionModel> payments = [];
  List<InvoicePaymentModel> invoicePayments = [];

  _ProjectionPaymentMonthContainerState(this.model) {
    payments = model.payments.where((e) => e.creditCardName.isEmpty).toList();
    payments.sort((a, b) => a.description.compareTo(b.description));

    for (var item
        in model.payments.where((e) => e.creditCardName.isNotEmpty).toList()) {
      if (!invoicePayments
          .any((e) => e.creditCardName == item.creditCardName)) {
        invoicePayments.add(InvoicePaymentModel(item.creditCardName, []));
      }
      InvoicePaymentModel invoicePayment = invoicePayments
          .firstWhere((e) => e.creditCardName == item.creditCardName);
      invoicePayment.payments.add(item);
    }
    for (var item in invoicePayments) {
      item.calculateTotal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      margin: const EdgeInsets.symmetric(horizontal:  4),
      child: Column(
        children: [
          ProjectionPaymentInvoiceContainer(invoicePayments: invoicePayments),
          Column(
              children: payments.map((p) {
            return Container(
                padding: const EdgeInsets.symmetric(horizontal:  10, vertical: 4),
                color: payments.indexOf(p) % 2 == 0
                    ? Colors.grey.shade200
                    : Colors.grey.shade300,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        elipsis(p.description, 30),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      p.qtdInstallments > 0
                          ? Text(
                              "${p.number}/${p.qtdInstallments}",
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600),
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
                    ]));
          }).toList()),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Entrada: ", style: TextStyle(color: Colors.grey.shade600)),
              Text(
                toReal(value: model.totalIn.toDouble()),
                style: TextStyle(
                    color: Colors.green.shade300, fontWeight: FontWeight.bold),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Saída: ", style: TextStyle(color: Colors.grey.shade600)),
              Text(
                toReal(value: model.totalOut.toDouble()),
                style: TextStyle(
                    color: Colors.red.shade300, fontWeight: FontWeight.bold),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,            
            children: [
              Text("Líquido: ", style: TextStyle(color: Colors.grey.shade600)),
              Text(
                toReal(value: model.total.toDouble()),
                style: TextStyle(
                    color: model.total > 0
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                    fontWeight: FontWeight.bold),
              )
            ],
          )
        ],
      ),
    );
  }
}
