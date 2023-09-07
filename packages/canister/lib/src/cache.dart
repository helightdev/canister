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

import 'dart:async';

import 'package:canister/canister.dart';

export 'cache/builder.dart';
export 'cache/loading_cache.dart';
export 'cache/local_cache.dart';
export 'cache/lru_cache.dart';

typedef WeightFunction<K, V> = int Function(K key, V value);
typedef RemovalListener<K, V> = Function(K key, V value);
typedef CacheLoader<K, V> = FutureOr<V> Function(K key);

/// An interface for a generic cache that stores key-value pairs.
abstract interface class Cache<K, V> {
  /// Gets the current size of the cache, indicating the number of key-value pairs
  /// stored in the cache. When using weighted entries, this will return the total
  /// weight of the cache rather than the entry count.
  int get size;

  /// Returns a map representation of this cache.
  Map<K, V> get map;

  /// Retrieves the value associated with the given [key] from the cache.
  /// If the [key] is not found in the cache, `null` is returned.
  V? get(K key);

  /// Retrieves the values for multiple [keys].
  /// The order of the values is equal to the key order.
  List<V?> getAll(Iterable<K> keys);

  /// Puts a new key-value pair into the cache. If the [key] already exists in
  /// the cache, the previous value associated with it is replaced by the
  /// [value].
  void put(K key, V value);

  /// Puts multiple new key-value pairs into the cache. If a [K] already exists in
  /// the cache, the previous value associated with it is replaced by the
  /// [V].
  void putAll(Map<K,V> map);

  /// Invalidates (removes) a key-value pair from the cache based on the
  /// provided [key]. If the [key] is not found in the cache, no action is taken.
  void invalidate(K key);

  /// Fully empties the queue.
  void clear();

  /// Creates a builder class for configuring and creating cache instances.
  static CacheBuilder<K,V> builder<K,V>() => CacheBuilder<K,V>();

  /// Creates a [LruCache] with the specified [capacity].
  static LruCache<K,V> lru<K,V>(int capacity) => LruCache<K,V>(capacity);
}

/// An interface for an asynchronous cache that stores key-value pairs.
abstract interface class AsyncCache<K, V> {
  /// Gets the current size of the cache, indicating the number of key-value pairs
  /// stored in the cache. When using weighted entries, this will return the total
  /// weight of the cache rather than the entry count.
  Future<int> size();

  /// Returns a map representation of this cache.
  Future<Map<K, V>> map();

  /// Retrieves the value associated with the given [key] from the cache.
  /// If the [key] is not found in the cache, `null` is returned.
  Future<V?> get(K key);

  /// Retrieves the values for multiple [keys].
  /// The order of the values is equal to the key order.
  Future<List<V?>> getAll(Iterable<K> keys);

  /// Puts a new key-value pair into the cache. If the [key] already exists in
  /// the cache, the previous value associated with it is replaced by the
  /// [value].
  Future put(K key, V value);

  /// Puts multiple new key-value pairs into the cache. If a [K] already exists in
  /// the cache, the previous value associated with it is replaced by the
  /// [V].
  Future putAll(Map<K,V> map);

  /// Invalidates (removes) a key-value pair from the cache based on the
  /// provided [key]. If the [key] is not found in the cache, no action is taken.
  Future invalidate(K key);

  /// Fully empties the queue.
  Future clear();
}

extension CacheExtension<K, V> on Cache<K, V> {
  V? operator [](K key) => get(key);
  void operator []=(K key, V value) => put(key, value);
}
