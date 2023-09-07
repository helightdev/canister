import 'package:canister/canister.dart';
import 'package:test/test.dart';

void main() {
  test("MemoizedLazySync", () {
    var i = 0;
    var lazy = SyncLazy.by(() => 42 + (i++));
    expect(lazy(), 42);
    expect(lazy(), 42);
  });

  test("MemoizedLazy", () async {
    var i = 0;
    var lazy = Lazy.by(() async {
      await Future.delayed(Duration(milliseconds: 100));
      return 42 + (i++);
    });
    expect(await lazy(), 42);
    expect(await lazy(), 42);
  });

  test("ExpireLazyEphemeral", () async {
    var i = 0;
    var lazy = Lazy.expire(() async {
      await Future.delayed(Duration(milliseconds: 100));
      return 42 + (i++);
    });
    var p0 = await Future.wait([lazy(), lazy(), lazy()]);
    expect(p0, everyElement(42));
    var p1 = await Future.wait([lazy(), lazy(), lazy()]);
    expect(p1, everyElement(43));
  });

  test("ExpireLazyDuration", () async {
    var i = 0;
    var lazy = Lazy.expire(() async {
      await Future.delayed(Duration(milliseconds: 5));
      return 42 + (i++);
    }, Duration(milliseconds: 200));
    var p0 = await Future.wait([lazy(), lazy(), lazy()]);
    expect(p0, everyElement(42));
    await Future.delayed(Duration(milliseconds: 100));
    var p1 = await Future.wait([lazy(), lazy(), lazy()]);
    expect(p1, everyElement(42));
    await Future.delayed(Duration(milliseconds: 110));
    var p2 = await Future.wait([lazy(), lazy(), lazy()]);
    expect(p2, everyElement(43));
  });
}
