import 'package:canister/canister.dart';

void main() {
  // Create a class with a lazy field wrapped using LazyField.
  final myObject = MyObject();

  // Access the lazy field. It will be computed and cached on first access.
  print('Accessing the lazy field...');
  myObject.access();

  // Accessing the lazy field again retrieves the cached result.
  print('Accessing the lazy field again...');
  myObject.access();
}

class MyObject {
  // Wrap a lazy field using lazy.
  late final Lazy<int> lazyField = _fetch.lazy();

  void access() async {
    // Accessing the lazy field using the call syntax.
    var result = await lazyField();
    print("Result: $result");
  }

  Future<int> _fetch() async {
    // Simulate an asynchronous computation, e.g., fetching data from a remote source.
    await Future.delayed(Duration(seconds: 2));
    return 42;
  }
}
