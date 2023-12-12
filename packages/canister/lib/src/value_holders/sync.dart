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

class ValueHolderImpl<T> implements ValueHolder<T> {
  late T _value;
  @override
  bool hasValue = false;

  @override
  T get value {
    if (!hasValue) throw StateError("Value not set");
    return _value;
  }

  @override
  T hold(T value) {
    hasValue = true;
    return _value = value;
  }

  @override
  T get(SyncLazyFunc<T> loader) {
    if (!hasValue) {
      _value = loader();
      hasValue = true;
    }
    return _value!;
  }

  @override
  void reset() {
    hasValue = false;
  }
}
