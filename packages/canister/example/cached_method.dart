import 'package:canister/canister.dart';
import 'package:canister/src/dsl.dart';

void main() async {
  // Create a class with a lazy field wrapped using LazyField.
  final myObject = MyObject();

  // Access the lazy field. It will be computed and cached on first access.
  print('Accessing the method with multiple arguments...');
  myObject.calculateSum((1, 2));

  // Accessing the lazy field again retrieves the cached result.
  print('Accessing a single argument...');
  myObject.getStringLength("Hello");

  print("Accessing an async method...");
  await myObject.asyncProduct((2, 3));
}

class MyObject {
  // You can create a single arg cached methods using the syncLoadingCache method.
  final getStringLength = syncLoadingCache((String s) => s.length);

  // You can practically create multi argument methods using records.
  final calculateSum = ((int a, int b) args) {
    var (a, b) = args; // Unpack the arguments
    return a + b;
  }.syncLoadingCache();

  // You can create an async method using the loadingCache method.
  final asyncProduct = ((int a, int b) args) async {
    var (a, b) = args; // Unpack the arguments
    await Future.delayed(Duration(seconds: 1));
    return a * b;
  }.loadingCache();
}
