import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:terra_nt/core/util/tile_cache_key.dart';
import 'package:terra_nt/shared/map/terra_map.dart';
import 'package:terra_nt/shared/map/tile_cache.dart';

const _tileUrl =
    'https://basemaps.cartocdn.com/rastertiles/dark_all/5/27/17.png';

// A valid one-pixel PNG, decoded by the real network tile image provider below.
final _tileBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQFwcdLl4wmwAAAAtJREFUCNdjYAACAAAFAAHiJgWbAAAAAElFTkSuQmCC',
);

Future<CachedMapTile> _waitForTile(
  BuiltInMapCachingProvider provider,
  String url,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    final tile = await provider.getTile(url);
    if (tile != null) return tile;
    // The built-in provider persists tiles through a background isolate.
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('Tile was not written to disk: $url');
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory temporaryDirectory;
  late Directory supportDirectory;
  late Directory osCacheDirectory;
  BuiltInMapCachingProvider? provider;
  var failSupportDirectory = false;
  late List<String> directoryRequests;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'terra-tile-test-',
    );
    supportDirectory = Directory('${temporaryDirectory.path}/support');
    osCacheDirectory = Directory('${temporaryDirectory.path}/os-cache');
    directoryRequests = [];
    failSupportDirectory = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      directoryRequests.add(call.method);
      if (call.method == 'getApplicationSupportDirectory') {
        if (failSupportDirectory) {
          throw PlatformException(code: 'unavailable');
        }
        return supportDirectory.path;
      }
      if (call.method == 'getApplicationCacheDirectory') {
        return osCacheDirectory.path;
      }
      throw StateError('Unexpected directory request: ${call.method}');
    });
  });

  tearDown(() async {
    await provider?.destroy();
    provider = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    binding.imageCache.clear();
    binding.imageCache.clearLiveImages();
    await temporaryDirectory.delete(recursive: true);
  });

  test(
    'writes under app support and overrides one-day freshness to 30 days',
    () async {
      provider = await initializeTileCache();
      final beforeWrite = DateTime.timestamp();
      await provider!.putTile(
        url: '$_tileUrl?key=old',
        metadata: CachedMapTileMetadata.fromHttpHeaders({
          'cache-control': 'public, max-age=86400',
          'age': '0',
        }),
        bytes: _tileBytes,
      );
      final tile = await _waitForTile(provider!, '$_tileUrl?key=new');

      expect(tile.bytes, _tileBytes);
      final freshAge = tile.metadata.staleAt.difference(beforeWrite);
      expect(
        freshAge.inSeconds,
        closeTo(const Duration(days: 30).inSeconds, 2),
      );
      expect(
        tile.metadata.staleAt.isAfter(beforeWrite.add(const Duration(days: 2))),
        isTrue,
      );
      expect(
        tile.metadata.staleAt.isBefore(
          beforeWrite.add(const Duration(days: 31)),
        ),
        isTrue,
      );
      final filename = BuiltInMapCachingProvider.uuidTileKeyGenerator(
        tileCacheKey(_tileUrl),
      );
      expect(
        await File('${supportDirectory.path}/fm_cache/$filename').exists(),
        isTrue,
      );
      expect(await osCacheDirectory.exists(), isFalse);
      expect(directoryRequests, ['getApplicationSupportDirectory']);
      expect(BuiltInMapCachingProvider.getOrCreateInstance(), same(provider));
    },
  );

  test(
    'a directory lookup failure keeps startup working with the default cache',
    () async {
      failSupportDirectory = true;
      provider = await initializeTileCache();
      await provider!.putTile(
        url: _tileUrl,
        metadata: CachedMapTileMetadata.fromHttpHeaders({
          'cache-control': 'max-age=86400',
          'age': '0',
        }),
        bytes: _tileBytes,
      );
      final tile = await _waitForTile(provider!, _tileUrl);

      expect(tile.bytes, _tileBytes);
      expect(tile.metadata.staleAt.difference(DateTime.timestamp()).inDays, 29);
      expect(
        await Directory('${osCacheDirectory.path}/fm_cache').exists(),
        isTrue,
      );
      expect(await supportDirectory.exists(), isFalse);
      expect(directoryRequests, [
        'getApplicationSupportDirectory',
        'getApplicationCacheDirectory',
      ]);
    },
  );

  test('a restarted default network provider renders the cached tile without signal or a key', () async {
    provider = await initializeTileCache();
    await provider!.putTile(
      url: '$_tileUrl?key=old',
      metadata: CachedMapTileMetadata.fromHttpHeaders({
        'cache-control': 'max-age=86400',
        'age': '0',
      }),
      bytes: _tileBytes,
    );
    await _waitForTile(provider!, _tileUrl);
    await provider!.destroy();
    provider = await initializeTileCache();

    var networkRequests = 0;
    final client = MockClient((request) async {
      networkRequests++;
      throw const SocketException('No signal');
    });
    final networkProvider = NetworkTileProvider(httpClient: client);
    final layer = TileLayer(
      urlTemplate: cartoDarkTileUrl,
      additionalOptions: const {'key': ''},
      tileProvider: networkProvider,
    );
    final imageProvider = networkProvider.getImageWithCancelLoadingSupport(
      const TileCoordinates(27, 17, 5),
      layer,
      Completer<void>().future,
    );
    final imageReady = Completer<ImageInfo>();
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (image, _) => imageReady.complete(image),
      onError: imageReady.completeError,
    );
    stream.addListener(listener);
    try {
      final image = await imageReady.future.timeout(const Duration(seconds: 5));
      expect(image.image.width, 1);
      expect(image.image.height, 1);
      expect(networkRequests, 0);
      image.dispose();
    } finally {
      stream.removeListener(listener);
      await imageProvider.evict();
      await networkProvider.dispose();
      client.close();
    }
  });
}
