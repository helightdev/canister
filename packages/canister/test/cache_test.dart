import 'package:canister/canister.dart';
import 'package:test/test.dart';

void main() {
  test("Capacity Test", () {
    var cache = CacheBuilder<String, int>().capacity(2).build();
    expect(cache.size, 0);
    cache.put("a", 1);
    cache.put("b", 2);
    expect(cache.size, 2); // Cache should now be filled
    expect(cache.get("a"), 1); // a should exist
    expect(cache.get("b"), 2); // b should exist
    expect(cache.get("c"), null); // c should not exist
    cache.put("c", 3);
    expect(cache.get("a"), null); // a should now be evicted
    expect(cache.get("c"), 3); // c should now be present
    cache.invalidate("c");
    expect(cache.get("c"), null); // c should now be no longer reachable
    expect(cache.size, 2); // the cache should not be cleared
    cache.put("a", 1);
    cache.put("a", 1);
    cache.put("a", 1);
    cache.put("a", 1);
    cache.put("a", 1);
    expect(cache.size, 2); // the cache should stay the same size
  });

  test("Expiration Test", () async {
    var cache = CacheBuilder<String, int>()
        .expireAfterWrite(Duration(milliseconds: 50))
        .expireAfterRead(Duration(milliseconds: 50))
        .build();
    expect(cache.size, 0);
    cache.put("a", 1);
    cache.put("b", 2);
    expect(cache.size, 2); // Cache should now be filled
    expect(cache.get("a"), 1); // a should exist
    expect(cache.get("b"), 2); // b should exist
    expect(cache.get("c"), null); // c should not exist
    await Future.delayed(Duration(milliseconds: 25));
    cache.get("a");
    await Future.delayed(Duration(milliseconds: 33));
    expect(cache.get("a"), 1); // a should exist
    expect(cache.get("b"), null); // b should have expired
    expect(cache.get("c"), null); // c should not exist
    await Future.delayed(Duration(milliseconds: 50));
    expect(cache.get("a"), null); // a should have expired
  });

  test("Update Test", () {
    var cache = CacheBuilder<int, String>()
        .capacity(10)
        .weightFunction((key, value) => value.length)
        .build();
    expect(cache.size, 0);
    cache.put(1, "aaa");
    expect(cache.size, 3);
    cache.put(1, "aaaaaa");
    expect(cache.size, 6);
  });

  test("Weight Test", () {
    var cache = CacheBuilder<String, String>()
        .capacity(10)
        .weightFunction((k, v) => v.length)
        .build();
    expect(cache.size, 0);
    cache.put("a", "aaaa");
    cache.put("b", "bbb");
    cache.put("c", "ccc");
    expect(cache.size, 10); // space should now be claimed
    cache.get("a");
    cache.put("d", "dddddd");
    expect(cache.size, 10); // space hould stay the same
    expect(cache.get("a"), "aaaa"); // a should not have been freed
    expect(cache.get("b"), null); // b should have been freed
    expect(cache.get("c"), null); // c should have been freed
    cache.put("e", "eeeeeee");
    expect(cache.get("a"), null); // a should have been freed
    expect(cache.get("d"), null); // d should have been freed
  });
}
