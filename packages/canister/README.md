# Canister - A Versatile Dart Caching Library
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/helightdev/canister/dart.yaml)
![Pub Version (including pre-releases)](https://img.shields.io/pub/v/canister?color=brightgreen)
![Pub Points](https://img.shields.io/pub/points/canister)
![Pub Likes](https://img.shields.io/pub/likes/canister?color=brightgreen)

Canister is a powerful and extensible caching library for Dart, offering a wide range of caching
strategies and features to enhance the performance of your Dart applications.
Whether you need to reduce latency, optimize data retrieval, or implement memoization,
Canister has you covered.

## Features

- **Extensible**: Customize and extend Canister to tailor caching strategies to your specific needs.
- **Guava-Like Caches**: Familiar caching patterns inspired by Guava's caching library.
- **Lazy Computations**: Easily make your existing functions compute lazily.
- **Asynchronous Caching**: Seamlessly handle asynchronous operations for modern Dart applications.
- **Memoization**: Efficiently cache function results to eliminate redundant computations.
- **Expiration Policies**: Configure expiration rules based on write or read operations.
- **Weight Functions**: Assign weights to cache entries for advanced cache management.
- **Removal Listeners**: Trigger actions when cache entries are removed, adding flexibility and functionality.

## Installation
Add the following dependency to your `pubspec.yaml`:
```yaml
dependencies:
  canister: ^1.0.0
```

## Usage
```dart
import 'package:canister/canister.dart';

void main() {
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
```
Fore more examples, have a look at the example folder.

## Contributing
Contributions are welcome! If you find any issues or have suggestions for improvement,
please open an issue or submit a pull request on our GitHub repository.
