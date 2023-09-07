/*
 * Copyright 2023, the canister authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:canister/canister.dart';
import 'package:canister/src/cache/loading_cache.dart';
import 'package:canister/src/internal.dart';

/// A builder class for configuring and creating cache instances.
class CacheBuilder<K, V> {
  int? _expireAfterWrite;
  int? _expireAfterRead;
  int? _capacity;
  int? _cleanupThreshold;
  WeightFunction<K, V> _weightFunction = noWeightFunction;
  RemovalListener<K, V>? _removalListener;

  /// Sets the cache expiration duration after a write operation.
  CacheBuilder<K, V> expireAfterWrite(Duration duration) {
    _expireAfterWrite = duration.inMicroseconds;
    return this;
  }

  /// Sets the cache expiration duration after a read operation.
  /// If no [expireAfterWrite] duration is specified, this value is
  /// used as a fallback.
  CacheBuilder<K, V> expireAfterRead(Duration duration) {
    _expireAfterRead = duration.inMicroseconds;
    return this;
  }

  /// Sets the maximum capacity of the cache. When using a [weightFunction],
  /// this defines the maximum weight of the cache.
  CacheBuilder<K, V> capacity(int capacity) {
    _capacity = capacity;
    return this;
  }

  /// Sets the cleanup threshold for the cache. Exceeding the [cleanupThreshold]
  /// will trigger cleanup operations for all succeeding write operations, which
  /// flush pending deletions and check expiration dates.
  CacheBuilder<K, V> cleanupThreshold(int cleanupThreshold) {
    _cleanupThreshold = cleanupThreshold;
    return this;
  }

  /// Sets a custom weight function to calculate the weight of cache entries.
  CacheBuilder<K, V> weightFunction(WeightFunction<K, V> function) {
    _weightFunction = function;
    return this;
  }

  /// Sets a custom removal listener for the cache.
  CacheBuilder<K, V> removalListener(RemovalListener<K, V> listener) {
    _removalListener = listener;
    return this;
  }

  /// Builds and returns a configured instance of a cache based on the builder's parameters.
  Cache<K, V> build() => LocalCache(
      expireAfterRead: _expireAfterRead,
      expireAfterWrite: _expireAfterWrite,
      capacity: _capacity,
      cleanupThreshold: _cleanupThreshold,
      weightFunction: _weightFunction,
      removalListener: _removalListener);

  /// Builds and returns an asynchronous loading cache based on the builder's parameters.
  AsyncCache<K, V> buildLoading(CacheLoader<K, V> loader) {
    var cache = build();
    return LoadingCache(cache, loader);
  }
}
