import 'package:cashflow_app/src/models/home/payment_projection_model.dart';

class InvoicePaymentModel {
  final String creditCardName;
  
  final List<PaymentProjectionModel> payments;

  late double total = 0;

  InvoicePaymentModel(this.creditCardName, this.payments);

  calculateTotal(){
    double sum = 0;
    for (var e in payments) { sum += e.value; }
    total = sum;
  }
}