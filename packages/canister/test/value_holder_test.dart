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
import 'package:test/test.dart';

void main() {
  test("Test Sync Value Holder", () {
    var holder = ValueHolder<String>();
    expect(holder.hasValue, false);
    expect(holder.get(() => "Hello"), "Hello");
    expect(holder.get(() => "Test"), "Hello");
    holder.hold("Other");
    expect(holder.get(() => "Test"), "Other");
    expect(holder.replace(() => "Hello"), "Hello");
    expect(holder.value, "Hello");
  });

  test("Test Async Value Holder", () async {
    var holder = AsyncValueHolder<String>();
    expect(holder.hasValue, false);
    var firstValue = await holder.get(() async => "Hello");
    expect(firstValue, "Hello");
    await holder.get(() => "Other");
    expect(holder.value, firstValue);
  });

  test("Test Async Debounce", () async {
    var holder = AsyncValueHolder<int>();
    int invocationCount = 0;
    generate() async {
      invocationCount++;
      await Future.delayed(Duration(milliseconds: 10));
      return invocationCount;
    }

    var values = await Future.wait([
      holder(generate),
      holder(generate),
      holder(generate),
    ]);
    expect(values, everyElement(1));
    expect(invocationCount, 1);
    expect(holder(() async => 99), completion(1));
    expect(holder.replace(() => 42), completion(42));
    expect(holder(() async => 99), completion(42));
  });

  test("Test Async Pending", () async {
    var holder = AsyncValueHolder<int>();
    holder.hold(1);
    expect(holder.isPending, true); // Value is there but not available
    expect(holder.hasValue, false);
    var awaited = await holder.awaitPending();
    expect(holder.isPending, false);
    expect(holder.hasValue, true);
    expect(awaited, 1);
    expect(holder.value, 1);
  });

  test("Test Async Replace", () async {
    var holder = AsyncValueHolder<int>();
    await holder.hold(1);
    expect(holder(() async => 99), completion(1));
    expect(holder.replace(() => 42), completion(42));
    expect(holder(() async => 99), completion(42));
  });
}
