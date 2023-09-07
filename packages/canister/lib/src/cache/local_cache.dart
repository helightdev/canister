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

  final LinkedHashMap<K, _LocalCacheEntry<V>> _map = LinkedHashMap();
  final Queue<K> _deletionQueue = Queue();
  late int _availableWeight = _maxWeight;
  late int _danglingWeight = 0;
  late int _scanCurrent;
  int get _usedWeight => _maxWeight - _availableWeight;

  /// Retrieves the value associated with a given key from the cache, if available.
  ///
  /// This method retrieves the value associated with the provided [key] from the cache. It performs a series of checks and
  /// operations to ensure that the cached entry is valid and up-to-date:
  ///
  /// 1. It checks if the [key] is already scheduled for deletion by examining the deletion queue. If the key is found in the
  ///    deletion queue, the method returns `null` to indicate that the value is no longer available in the cache.
  /// 2. It looks up the cache entry associated with the [key]. If the entry does not exist, the method returns `null`.
  /// 3. It checks if the cache entry has an expiration time set and whether that expiration time has passed, indicating that
  ///    the entry has expired. If the entry is expired, it marks the [key] for deletion in the deletion queue and returns `null`.
  /// 4. If the [expireAfterRead] option is specified, it updates the expiration time of the cache entry to the current time plus
  ///    the read expiration duration. This ensures that the entry remains valid for a specified duration after being accessed.
  /// 5. The cache entry is moved to the top of the cache to prioritize recently accessed entries.
  /// 6. If the [cleanupThreshold] is specified and the used weight in the cache exceeds the threshold, the method calls [cleanup]
  ///    to remove expired and unnecessary entries, maintaining the cache's size within the specified capacity.
  @override
  V? get(K key) {
    // Check if this key is scheduled for deletion
    if (_deletionQueue.contains(key)) return null;
    var entry = _map[key];
    if (entry == null) return null;

    // Check if the key is expired
    if (entry.expiration != null && entry.expiration! <= currentTime) {
      _deletionQueue.add(key);
      return null;
    }
    // Update expiration time
    if (expireAfterRead != null) {
      entry.expiration = currentTime + expireAfterRead!;
    }

    // Move to top
    _map.remove(key);
    _map[key] = entry;

    if (cleanupThreshold != null && _usedWeight > cleanupThreshold!) {
      cleanup();
    }

    return entry.value;
  }

  /// Invalidates the cache entry associated with [key].
  ///
  /// When a [key] is invalidated, it means that the associated cache entry will be scheduled
  /// for removal from the cache. If the key does not exist in the cache, this method has no effect.
  @override
  void invalidate(K key) {
    var entry = _map[key];
    if (entry == null) return;
    _enqueueForDeletion(key, entry.weight);
  }

  /// Inserts or updates a key-value pair in the cache.
  ///
  /// This method inserts or updates a key-value pair in the cache. It creates a cache entry with the provided [key] and [value],
  /// calculates the weight of the entry, and then determines whether it can be accommodated in the cache based on the available
  /// weight and cache capacity.
  ///
  /// The process of inserting or updating a key-value pair includes the following steps:
  ///
  /// 1. It creates a new cache entry using [_createEntry] with the provided [key] and [value].
  /// 2. It checks if the available weight in the cache is sufficient to accommodate the new entry. If the available weight is
  ///    not enough, it follows these sub-steps:
  ///    a. It calculates the additional weight required to insert the entry.
  ///    b. If there is enough dangling weight (weight that can be freed without performing additional deletions) to
  ///       satisfy the required weight, it flushes the deletion queue to free up the necessary weight.
  ///    c. If the required weight is less than or equal to the maximum weight of the cache, it first performs deletions to
  ///       free up any dangling weight, and then calls [freeWeight] to free up the remaining required weight.
  ///    d. If the required weight is greater than the maximum weight of the cache, it throws an exception indicating that the
  ///       cache entry cannot fit into the cache.
  /// 3. If the [cleanupThreshold] is specified and the used weight in the cache exceeds the threshold, it calls [cleanup] to
  ///    remove expired and unnecessary entries to maintain the cache's size within the specified capacity. This is only checked
  ///    if there initially was enough space left to accommodate the entry, since most resolution cases otherwise involve a cleanup.
  /// 4. It subtracts the weight of the new entry from the available weight and inserts the entry into the cache.
  @override
  void put(K key, V value) {
    var entry = _createEntry(key, value);
    if (_availableWeight < entry.weight) {
      var requiredWeight = entry.weight - _availableWeight;
      if (_danglingWeight >= requiredWeight) {
        _performDeletions();
      } else if (requiredWeight <= _maxWeight) {
        _performDeletions();
        requiredWeight = entry.weight - _availableWeight;
        freeWeight(requiredWeight);
      } else {
        throw Exception("Cache entry can't fit into cache");
      }
    } else if (cleanupThreshold != null && _usedWeight > cleanupThreshold!) {
      cleanup();
    }

    _availableWeight -= entry.weight;
    _map[key] = entry;
  }

  _LocalCacheEntry<V> _createEntry(K key, V value) {
    return _LocalCacheEntry(
        _initialExpiration == null ? null : currentTime + _initialExpiration!,
        value,
        weightFunction(key, value));
  }

  void _enqueueForDeletion(K key, int weight) {
    _deletionQueue.add(key);
    _danglingWeight += weight;
  }
  
  void _performDeletions() {
    while (_deletionQueue.isNotEmpty) {
      var element = _deletionQueue.removeFirst();
      var popped = _map.remove(element);
      if (popped == null) continue;
      _availableWeight += popped.weight;
      _danglingWeight -= popped.weight;
      removalListener?.call(element, popped.value);
    }
  }

  /// Frees up a specified amount of weight in the cache by removing entries based on their weights.
  ///
  /// This method attempts to free the given [weight] from the cache by removing cache entries based on their weights.
  /// It iterates through the cache, considering the weights of entries, and marks entries for removal until the requested
  /// weight is reached. Additionally, it performs an expiration scan on the side to remove any expired entries.
  ///
  /// The process of freeing weight includes the following steps:
  ///
  /// 1. It initializes the expiration scan by setting the current time as the scan reference using [_initExpirationScan].
  /// 2. It iterates through the cache entries, considering the weights of entries, and checks for entries that can be
  ///    removed to free up weight. If an entry can be removed without exceeding the requested weight or if it has expired,
  ///    it is marked for deletion.
  /// 3. After scanning all entries, the method calls [_performDeletions] to actually remove the marked entries and free
  ///    up the weight in the cache.
  void freeWeight(int weight) {
    var remainingWeight = weight;
    _initExpirationScan();
    for (var entry in _map.entries) {
      if (_deletionQueue.contains(entry.key)) {
        remainingWeight -= entry.value.weight;
        continue;
      }
      if (_expirationScan(entry.value)) {
        remainingWeight -= entry.value.weight;
        _enqueueForDeletion(entry.key, entry.value.weight);
        continue;
      }
      if (remainingWeight <= 0) continue;
      remainingWeight -= entry.value.weight;
      _enqueueForDeletion(entry.key, entry.value.weight);
    }
    _performDeletions();
  }

  void _initExpirationScan() {
    _scanCurrent = currentTime;
  }

  bool _expirationScan(_LocalCacheEntry entry) {
    var expiration = entry.expiration;
    if (expiration == null) return false;
    return expiration <= _scanCurrent;
  }

  /// Cleans up the cache by removing expired entries.
  ///
  /// This method performs the following actions:
  ///
  /// 1. Flushes all existing deletions by calling [_performDeletions].
  /// 2. Initializes the expiration scan by setting the current time as the scan reference using [_initExpirationScan].
  /// 3. Iterates through the cache entries, checking for expired entries that are not already marked for deletion
  ///    (entries in [_deletionQueue]).
  /// 4. If an entry is found to be expired and not marked for deletion, it is added to [_deletionQueue].
  /// 5. After scanning all entries, the method flushes all newly created deletions by calling [_performDeletions] again.
  ///
  /// This method helps maintain the cache's size within the specified [capacity] and removes entries that have exceeded
  /// their expiration time.
  void cleanup() {
    // Flush all existing deletions
    _performDeletions();
    _initExpirationScan();
    for (var entry in _map.entries) {
      if (_deletionQueue.contains(entry.key)) continue;
      if (_expirationScan(entry.value)) {
        _enqueueForDeletion(entry.key, entry.value.weight);
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

class _LocalCacheEntry<V> {
  int? expiration;
  final int weight;
  final V value;

  _LocalCacheEntry(this.expiration, this.value, this.weight);
}
