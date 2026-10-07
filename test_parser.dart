import 'package:expense_tracker/parser/message_parser_pipeline.dart';

void main() {
  const text = '''E-Mandate!
Rs.1000.00 will be deducted on 07/10/26, 00:00:00
For MUTUAL FUNDS NCL AUTOPAY mandate
UMN 01a05c5d4d39742f853f8f718362de0f@yesg
Maintain Balance
-HDFC Bank''';

  final result = MessageParserPipeline.instance.parse(text, sender: "HDFCBK");
  print("Success: \${result.isSuccess}");
  if (result.isSuccess) {
    print("Amount: \${result.payment?.amount}");
    print("Type: \${result.payment?.type}");
    print("Merchant: \${result.payment?.description}");
  } else {
    print("Error: \${result.errorMessage}");
  }
}
