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
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test("Basic", () {
    LruCache<String, int> cache = LruCache(3);
    cache.put("A", 1);
    cache.put("B", 2);
    cache.put("C", 3);
    expect(cache.size, 3);
    cache.put("D", 4);
    expect(cache.size, 3);
    expect(cache.get("A"), null);
    expect(cache.get("B"), 2);
    expect(cache.get("C"), 3);
    expect(cache.get("D"), 4);
    cache.putAll({"_": 1, "__": 2});
    expect(cache.get("B"), null);
    expect(cache.get("C"), null);
    expect(cache.get("D"), 4);
  });
}
