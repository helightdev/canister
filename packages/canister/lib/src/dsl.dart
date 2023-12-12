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

// ############################ Global Methods ############################

/// DSL for creating [SyncLazy] instances. See [SyncLazy.by] for details.
SyncLazy<T> syncLazy<T>(SyncLazyFunc<T> loader) => SyncLazy.by(loader);

/// DSL for creating [Lazy] instances. See [Lazy.by] for details.
Lazy<T> lazy<T>(AsyncLazyFunc<T> loader, [Duration? duration]) {
  if (duration == null) {
    return Lazy.by(loader);
  } else {
    return Lazy.expire(loader, duration);
  }
}

/// DSL for creating loading [AsyncCache] instances. See [CacheBuilder] for details.
AsyncCache<K, V> loadingCache<K, V>(CacheLoader<K, V> loader,
    {Function(CacheBuilder<K, V> builder)? configure}) {
  var builder = Cache.builder<K, V>();
  configure?.call(builder);
  return builder.buildLoading(loader);
}

/// DSL for creating loading [SyncCache] instances. See [CacheBuilder] for details.
Cache<K, V> syncLoadingCache<K, V>(SyncCacheLoader<K, V> loader,
    {Function(CacheBuilder<K, V> builder)? configure}) {
  var builder = Cache.builder<K, V>();
  configure?.call(builder);
  return builder.buildSyncLoading(loader);
}

// ############################ Extension ############################

extension CacheExtension<K, V> on Cache<K, V> {
  /// A convenience method that allows calling the [get] method using a
  /// map like syntax.
  V? operator [](K key) => get(key);

  /// A convenience method that allows calling the [put] method using a
  /// map like syntax.
  void operator []=(K key, V value) => put(key, value);

  /// Shorthand syntax for [get].
  V? call(K key) => get(key);
}

/// Convenience extensions
extension AsyncCacheExtension<K, V> on AsyncCache<K, V> {
  /// Shorthand syntax for [get].
  Future<V?> call(K key) => get(key);
}

/// Convenience extensions
extension SyncFunctionCacheExtension<K, V> on SyncCacheLoader<K, V> {
  /// Creates a [SyncLoadingCache] instance wrapping the given function,
  /// allowing for memoization of the result. The cache is configured using
  /// the provided [configure] function.
  Cache<K, V> syncLoadingCache(
      {Function(CacheBuilder<K, V> builder)? configure}) {
    var builder = Cache.builder<K, V>();
    configure?.call(builder);
    return builder.buildSyncLoading(this);
  }
}

/// Convenience extensions
extension AsyncFunctionCacheExtension<K, V> on CacheLoader<K, V> {
  /// Creates a [LoadingCache] instance wrapping the given function,
  /// allowing for memoization of the result. The cache is configured using
  /// the provided [configure] function.
  AsyncCache<K, V> loadingCache(
      {Function(CacheBuilder<K, V> builder)? configure}) {
    var builder = Cache.builder<K, V>();
    configure?.call(builder);
    return builder.buildLoading(this);
  }
}

/// Convenience extensions
extension LazyExtension<V> on SyncLazy<V> {
  /// A convenience method that allows calling the [value] getter as if it were
  /// a function. This is useful when you want to obtain the value using a
  /// function call syntax.
  V call() => value;
}

/// Convenience extensions
extension AsyncLazyExtension<V> on Lazy<V> {
  /// A convenience method for eagerly evaluating the lazy value with a nicer syntax.
  Lazy<V> eager() => this..call();
}

extension LazyCreationExtension<T> on T Function() {
  /// Creates a [SyncMemoizedLazy] instance wrapping the given function,
  /// allowing for memoization of the result.
  SyncMemoizedLazy<T> lazy() => SyncMemoizedLazy(this);
}

/// Convenience extensions
extension LazyFunctionExtension<T> on Future<T> Function() {
  /// Creates a [MemoizedLazy] instance wrapping the given function,
  /// allowing for memoization of the result.
  MemoizedLazy<T> lazy() => MemoizedLazy(this);

  /// Creates an [ExpiringLazy] instance wrapping the given function,
  /// allowing for expiring memoization of the result.
  ExpiringLazy<T> lazyExpiring([Duration? duration]) =>
      ExpiringLazy(this, duration);
}

/// Convenience extensions
extension ValueHolderExtension<T> on ValueHolder<T> {
  /// Shorthand syntax for [get].
  T call(SyncLazyFunc<T> loader) => get(loader);

  /// Convenience method for replacing the value using [hold] and [reset].
  T replace(SyncLazyFunc<T> loader) {
    var value = loader();
    reset();
    return hold(value);
  }
}

/// Convenience extensions
extension AsyncValueHolderExtension<T> on AsyncValueHolder<T> {
  /// Shorthand syntax for [get].
  Future<T> call(AsyncLazyFunc<T> loader) => get(loader);

  /// Convenience method for replacing the value using [hold] and [reset].
  Future<T> replace(AsyncLazyFunc<T> loader) {
    var value = loader();
    reset();
    return hold(value);
  }
}
