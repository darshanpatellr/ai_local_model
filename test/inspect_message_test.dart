import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

void main() {
  test('Inspect Message value equality', () {
    final m1 = Message.thinking(text: 'Hello');
    final m2 = Message.thinking(text: 'Hello');
    
    print('m1 identical to m2: ${identical(m1, m2)}');
    print('m1 == m2: ${m1 == m2}');
    
    final list = <Message>[m1];
    print('list.contains(m2): ${list.contains(m2)}');
    print('list.remove(m2): ${list.remove(m2)}');
  });
}
