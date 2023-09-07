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

/// A synchronous lazy loader that implements the [SyncLazy] interface.
/// This class defers the computation of a value until it is first accessed,
/// and then caches the computed value for subsequent accesses.
class SyncMemoizedLazy<V> implements SyncLazy<V> {
  final SyncLazyFunc<V> loader;
  SyncMemoizedLazy(this.loader);

  late V _value;
  bool _isCached = false;

  @override
  V get value {
    if (_isCached) return _value;
    _value = loader();
    _isCached = true;
    return _value;
  }

  @override
  void invalidate() {
    _isCached = false;
  }
}
