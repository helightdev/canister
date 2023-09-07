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

/// An asynchronous lazy loader that implements the [SyncLazy] interface.
/// This class defers the computation of a value until it is first accessed,
/// and then caches the computed value for subsequent accesses.
class MemoizedLazy<V> implements Lazy<V> {
  final AsyncLazyFunc<V> loader;
  MemoizedLazy(this.loader);

  Completer<V> _completer = Completer();

  @override
  Future<V> get value =>
      _completer.isCompleted ? _completer.future : _compute();

  Future<V> _compute() {
    _completer.complete(Future.sync(loader));
    return _completer.future;
  }

  @override
  void invalidate() {
    _completer = Completer();
  }
}
