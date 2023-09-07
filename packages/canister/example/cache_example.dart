import 'package:canister/canister.dart';

void main() async {
  // Create and configure a cache
  final cache = CacheBuilder<String, int>()
      .capacity(100)
      .expireAfterWrite(Duration(minutes: 30))
      .build();

  // Put a value into the cache
  cache.put('key', 42);

  // Get a value from the cache
  final value = cache.get('key');
  print('Cached Value: $value');
}
