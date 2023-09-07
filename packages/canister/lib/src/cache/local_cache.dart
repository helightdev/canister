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
import 'package:canister/src/internal.dart';

/// This class represents a local cache implementation that implements the [Cache] interface.
///
/// It provides a simple in-memory cache with expiration and capacity management.
/// The cache allows for customization using a [weightFunction] to assign weights to cache entries
/// and a [removalListener] to handle removal events.
class LocalCache<K, V> implements Cache<K, V> {
  final int? expireAfterWrite;
  final int? expireAfterRead;
  final int? capacity;
  final int? cleanupThreshold;
  final WeightFunction<K, V> weightFunction;
  final RemovalListener<K, V>? removalListener;

  LocalCache(
      {this.expireAfterWrite,
      this.expireAfterRead,
      this.capacity,
      this.cleanupThreshold,
      this.weightFunction = noWeightFunction,
      this.removalListener});

  late final int _maxWeight = capacity ?? maxIntValue;
  late final int? _initialExpiration = expireAfterWrite ?? expireAfterRead;

  final LinkedHashMap<K, LocalCacheEntry<V>> _map = LinkedHashMap();
  final Queue<K> _deletionQueue = Queue();
  late int _availableWeight = _maxWeight;
  late int _scanCurrent;

  @override
  V? get(K key) {
    if (_deletionQueue.contains(key)) return null;
    var entry = _map[key];
    if (entry == null) return null;
    if (entry.expiration != null && entry.expiration! <= currentTime) {
      _deletionQueue.add(key);
      return null;
    }
    if (expireAfterRead != null) {
      entry.expiration = currentTime + expireAfterRead!;
    }
    _map.remove(key);
    _map[key] = entry; // Move to top
    return entry.value;
  }

  @override
  void invalidate(K key) {
    _deletionQueue.add(key);
  }

  @override
  void put(K key, V value) {
    var entry = _createEntry(key, value);
    if (_availableWeight < entry.weight) {
      var requiredWeight = entry.weight - _availableWeight;
      freeWeight(requiredWeight);
      _performDeletions();
    } else if (cleanupThreshold != null &&
        _maxWeight - _availableWeight < cleanupThreshold!) {
      cleanup();
    }
    _availableWeight -= entry.weight;
    _map[key] = entry;
  }

  LocalCacheEntry<V> _createEntry(K key, V value) {
    return LocalCacheEntry(
        _initialExpiration == null ? null : currentTime + _initialExpiration!,
        value,
        weightFunction(key, value));
  }

  void _performDeletions() {
    while (_deletionQueue.isNotEmpty) {
      var element = _deletionQueue.removeFirst();
      var popped = _map.remove(element);
      if (popped == null) continue;
      _availableWeight += popped.weight;
      removalListener?.call(element, popped.value);
    }
  }

  void freeWeight(int weight) {
    var remainingWeight = weight;
    _initExpirationScan();
    for (var entry in _map.entries) {
      if (_deletionQueue.contains(entry.key)) continue;
      if (_expirationScan(entry.value)) {
        _deletionQueue.add(entry.key);
        continue;
      }
      if (remainingWeight <= 0) continue;
      remainingWeight -= entry.value.weight;
      _deletionQueue.add(entry.key);
    }
  }

  void _initExpirationScan() {
    _scanCurrent = currentTime;
  }

  bool _expirationScan(LocalCacheEntry entry) {
    var expiration = entry.expiration;
    if (expiration == null) return false;
    return expiration <= _scanCurrent;
  }

  void cleanup() {
    // Flush all existing deletions
    _performDeletions();
    _initExpirationScan();
    for (var entry in _map.entries) {
      if (_deletionQueue.contains(entry.key)) continue;
      if (_expirationScan(entry.value)) {
        _deletionQueue.add(entry.key);
      }
    }
    // Flush all newly created deletions
    _performDeletions();
  }

  @override
  int get size => _maxWeight - _availableWeight;

  @override
  Map<K, V> get map => Map.fromEntries(_map.entries
      .where((element) => !_deletionQueue.contains(element.key))
      .map((entry) => MapEntry(entry.key, entry.value.value)));
}

class LocalCacheEntry<V> {
  int? expiration;
  final int weight;
  final V value;

  LocalCacheEntry(this.expiration, this.value, this.weight);
}
