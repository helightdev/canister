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
import 'package:canister/src/value_holders/async.dart';
import 'package:canister/src/value_holders/sync.dart';

/// {@template value_holder}
/// A simple value holder that allows to hold a value and load it lazily.
/// This api can be used for manually caching values and creating more
/// complex lazy loading mechanisms. For a simple lazy loading mechanism use
/// [SyncLazy].
/// {@endtemplate}
abstract class ValueHolder<T> {
  /// Returns the value if it is set, otherwise throws a [StateError].
  T get value;

  /// Returns true if the value is set.
  bool get hasValue;

  /// Sets the value.
  T hold(T value);

  /// Returns the value if it is set, otherwise loads it using the supplied
  /// [loader] function.
  T get(SyncLazyFunc<T> loader);

  /// Resets the value.
  void reset();

  /// {@macro value_holder}
  factory ValueHolder() => ValueHolderImpl<T>();
}

/// {@template async_value_holder}
/// A simple asynchrnous value holder that allows to hold a lazily computed value.
/// This api can be used for manually debouncing async calls and creating more
/// complex lazy loading mechanisms. For a simple lazy loading mechanism use
/// [Lazy].
/// {@endtemplate}
abstract class AsyncValueHolder<T> {
  /// Returns the value if it is set, otherwise throws a [StateError].
  T get value;

  /// Returns true if the value is set.
  bool get hasValue;

  /// Returns true if the value is currently being loaded.
  bool get isPending;

  /// Returns the value if it is set, otherwise waits for the value if [isPending]
  /// is true, otherwise throws a [StateError].
  Future<T> awaitPending();

  /// Sets the value.
  Future<T> hold(FutureOr<T> value);

  /// Returns the value if it is set, otherwise loads it using the supplied
  /// [loader] function.
  Future<T> get(AsyncLazyFunc<T> loader);

  /// Resets the value.
  void reset();

  /// {@macro async_value_holder}
  factory AsyncValueHolder() => AsyncValueHolderImpl<T>();
}
