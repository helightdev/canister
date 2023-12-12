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

class AsyncValueHolderImpl<T> implements AsyncValueHolder<T> {
  late T _value;
  @override
  bool hasValue = false;
  bool hasPending = false;

  Future<T>? _future;

  @override
  T get value {
    if (!hasValue) throw StateError("Value not set");
    return _value;
  }

  @override
  bool get isPending => hasPending;

  @override
  Future<T> hold(FutureOr<T> value) async {
    _future = Future.value(value);
    hasPending = true;
    _value = await _future!;
    hasValue = true;
    hasPending = false;
    return _value!;
  }

  @override
  Future<T> get(AsyncLazyFunc<T> loader) async {
    if (hasValue) return _value;
    if (_future != null) return _future!;
    _future = Future.value(loader());
    hasPending = true;
    _value = await _future!;
    hasValue = true;
    hasPending = false;
    return _value!;
  }

  @override
  void reset() {
    hasValue = false;
    hasPending = false;
    _future = null;
  }

  @override
  Future<T> awaitPending() async {
    if (hasValue) return _value;
    if (!hasPending) throw StateError("No pending value");
    return await _future!;
  }
}
