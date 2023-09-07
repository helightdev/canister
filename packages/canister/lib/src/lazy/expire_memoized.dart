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

/// An asynchronous lazy loader that implements the [SyncLazy] interface, providing
/// cached value expiration. This class computes and caches the value but allows
/// the cached entry to expire after a specified [duration]. If no duration is
/// defined, the cached value will expire after the future has returned, effectively
/// debouncing the computation.
class ExpiringLazy<V> implements Lazy<V> {
  final AsyncLazyFunc<V> loader;
  final Duration? expiration;
  ExpiringLazy(this.loader, this.expiration);

  Timer? _timer;
  bool _isComputing = false;
  Completer<V> _completer = Completer();

  @override
  Future<V> get value {
    if (_completer.isCompleted) return _completer.future;
    if (!_isComputing) _compute();
    return _completer.future;
  }

  Future _compute() async {
    _isComputing = true;
    try {
      var data = await loader();
      _completer.complete(data);
      _restartTimer();
    } finally {
      _isComputing = false;
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (expiration == null) {
      invalidate();
      return;
    }
    _timer = Timer(expiration!, invalidate);
  }

  void dispose() {
    _timer?.cancel();
  }

  @override
  void invalidate() {
    _completer = Completer();
    _timer?.cancel();
  }
}
