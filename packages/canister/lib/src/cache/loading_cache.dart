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

import 'package:canister/src/cache.dart';

/// This class represents a loading cache that implements the [AsyncCache] interface.
///
/// It provides a mechanism to asynchronously load and cache values for a given key.
/// The cache is backed by a [Cache] instance, and loading is handled by a [CacheLoader].
class LoadingCache<K, V> implements AsyncCache<K, V> {
  final Cache<K, V> cache;
  final CacheLoader<K, V> loader;
  LoadingCache(this.cache, this.loader);

  final Map<K, Completer<V>> _loading = {};

  @override
  Future<V?> get(K key) {
    var cached = cache.get(key);
    if (cached != null) return Future.value(cached);
    var loading = _loading[key];
    if (loading != null) return loading.future;
    return _startLoad(key);
  }

  Future<V> _startLoad(K key) {
    Completer<V> completer = Completer();
    completer.future.then((value) => _finishLoad(key, value));
    completer.complete(loader(key));
    _loading[key] = completer;
    return completer.future;
  }

  void _finishLoad(K key, V value) {
    cache.put(key, value);
    _loading.remove(key);
  }

  @override
  Future invalidate(K key) async {
    cache.invalidate(key);
  }

  @override
  Future put(K key, V value) async {
    cache.put(key, value);
  }

  @override
  Future<int> size() => Future.value(cache.size);

  @override
  Future<Map<K, V>> map() => Future.value(cache.map);

  @override
  Future clear() async => cache.clear();
}
