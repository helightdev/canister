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
    int invocationCount = 0;
    SyncLoadingCache<String, int> wrapper = SyncLoadingCache(cache, (key) {
      invocationCount++;
      return key.length;
    });
    expect(wrapper.get("A"), 1);
    expect(wrapper.get("BB"), 2);
    expect(wrapper.get("CCC"), 3);
    expect(invocationCount, 3);
    expect(wrapper.get("A"), 1);
    expect(wrapper.get("BB"), 2);
    expect(wrapper.get("CCC"), 3);
    expect(invocationCount, 3);
    expect(wrapper.size, 3);
  });
}
