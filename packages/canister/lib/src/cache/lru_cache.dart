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

import 'dart:collection';

import 'package:canister/canister.dart';

/// A Least Recently Used (LRU) Cache Implementation.
///
/// The `LruCache` class implements a simple LRU cache, where the least recently
/// used items are removed when the cache exceeds a specified capacity. It
/// provides efficient methods for storing and retrieving key-value pairs, as
/// well as clearing the cache and invalidating specific keys.
class LruCache<K,V> implements Cache<K,V> {

  int capacity;
  
  LruCache(this.capacity);

  final LinkedHashMap<K,V> _map = LinkedHashMap();

  int get _freeSlots => capacity - _map.length;

  @override
  void clear() => _map.clear();

  @override
  V? get(K key) {
    var entry = _map.remove(key);
    if (entry == null) return null;
    _map[key] = entry;
    return entry;
  }

  @override
  List<V?> getAll(Iterable<K> keys) => keys.map((key) => get(key)).toList();

  @override
  void invalidate(K key) {
    _map.remove(key);
  }

  @override
  void put(K key, V value) {
    if (size >= capacity) _free(1);
    _map[key] = value;
  }

  @override
  void putAll(Map<K, V> map) {
    if (size == capacity) {
      _free(map.length);
    } else if (_freeSlots < map.length) {
      _free(map.length - _freeSlots);
    }
    _map.addAll(map);
  }

  void _free(int amount) {
    _map.entries.take(amount)
        .toList() // Buffer
        .forEach((entry) {
      _map.remove(entry.key);
    });
  }

  @override
  Map<K, V> get map => _map;

  @override
  int get size => _map.length;

}