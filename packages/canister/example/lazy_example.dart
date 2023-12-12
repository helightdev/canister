import 'dart:async';
import 'package:canister/canister.dart';

void main() async {
  // Create an asynchronous lazy instance with an expiring cache.
  final lazyValue = Lazy.expire(
    () async {
      // Simulate an asynchronous computation, e.g., fetching data from a remote source.
      await Future.delayed(Duration(seconds: 1));
      return 42;
    },
    Duration(seconds: 3), // Cache will expire after 5 seconds.
  );

  print('Accessing the lazy value...');
  final result1 = await lazyValue.value;
  print('Result 1: $result1');

  // Wait for a few seconds to demonstrate cache expiration.
  await Future.delayed(Duration(seconds: 5));

  print('Accessing the lazy value again...');
  final result2 = await lazyValue.value;
  print('Result 2: $result2');
}
