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

export 'lazy/sync_memoized.dart';
export 'lazy/async_memoized.dart';
export 'lazy/expire_memoized.dart';

typedef SyncLazyFunc<V> = V Function();
typedef AsyncLazyFunc<V> = FutureOr<V> Function();

/// An interface for lazy-loading a value of type [V].
abstract interface class SyncLazy<V> {
  /// Gets the lazily computed value. If the value has not been computed yet,
  /// it will be computed and cached before being returned.
  V get value;

  /// Invalidates (removes) the cached value, forcing it to be recomputed on
  /// the next access to [value].
  void invalidate();

  /// Creates a synchronous lazy instance with the provided [loader].
  /// The [SyncMemoizedLazy] implementation computes the value synchronously and caches the result.
  static SyncLazy<V> by<V>(SyncLazyFunc<V> loader) {
    return SyncMemoizedLazy(loader);
  }
}

abstract interface class Lazy<V> extends SyncLazy<Future<V>> {
  /// Gets the lazily computed value. If the value has not been computed yet,
  /// it will be computed and cached before being returned.
  @override
  Future<V> get value;

  /// Creates an asynchronous lazy instance with the provided [loader].
  /// The [MemoizedLazy] implementation computes the value asynchronously and caches the result.
  static MemoizedLazy<V> by<V>(AsyncLazyFunc<V> loader) {
    return MemoizedLazy(loader);
  }

  /// Creates an asynchronous lazy instance with the provided [loader] and optional
  /// [duration]. An expiring lazy instance computes and caches the value, but
  /// the cached entry expires after the specified [duration]. If no duration is defined,
  /// the cached value will expire after the future has returned, which only debounces
  /// the computation.
  static ExpiringLazy<V> expire<V>(AsyncLazyFunc<V> loader,
      [Duration? duration]) {
    return ExpiringLazy(loader, duration);
  }
}

extension LazyExtension<V> on SyncLazy<V> {
  /// A convenience method that allows calling the [value] getter as if it were
  /// a function. This is useful when you want to obtain the value using a
  /// function call syntax.
  V call() => value;
}

extension LazyFunctionExtension<T> on Future<T> Function() {
  /// Creates a [MemoizedLazy] instance wrapping the given function,
  /// allowing for memoization of the result.
  MemoizedLazy<T> lazy() => MemoizedLazy(this);

  /// Creates an [ExpiringLazy] instance wrapping the given function,
  /// allowing for expiring memoization of the result.
  ExpiringLazy<T> lazyExpiring([Duration? duration]) =>
      ExpiringLazy(this, duration);
}
