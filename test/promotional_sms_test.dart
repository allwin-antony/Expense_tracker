import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/parser/message_parser_pipeline.dart';

void main() {
  test('Test specific promotional SMS', () {
    const body = "Dear Customer, you were almost there to make the right choice. We have securely saved your Suryoday Small Finance Bank FD for INR 100000.00, complete to create your fixed deposit successfully  -Super Money";
    
    final result = MessageParserPipeline.instance.parse(body, sender: 'VM-SUPMON');
    
    print('--- PARSING RESULT ---');
    print('Is Success: ${result.isSuccess}');
    if (result.isSuccess) {
      print('Amount: ${result.payment?.amount}');
      print('Type: ${result.payment?.type}');
      print('Description: ${result.payment?.description}');
    } else {
      print('Error: ${result.errorMessage}');
    }
  });
}
