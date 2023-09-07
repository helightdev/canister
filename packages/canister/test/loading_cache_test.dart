import 'package:canister/canister.dart';
import 'package:test/test.dart';

void main() {
  test("Loading Test", () async {
    var cache =
        CacheBuilder<int, String>().buildLoading((key) => key.toString() * key);
    expect(await cache.size(), 0);
    expect(await cache.get(1), "1");
    expect(await cache.get(3), "333");
    expect(await cache.get(5), "55555");
  });

  test("Debouncing", () async {
    int loadCounter = 0;
    var cache = CacheBuilder<int, String>().buildLoading((key) async {
      loadCounter++;
      await Future.delayed(Duration(milliseconds: 50));
      return key.toString() * key;
    });
    expect(await cache.size(), 0);
    expect(loadCounter, 0);
    var data = await Future.wait([cache.get(3), cache.get(3), cache.get(3)]);
    expect(data, everyElement("333"));
    expect(loadCounter, 1);
  });
}
