/// Tile identity without CARTO's volatile API key. Keep all other URL bytes,
/// including the retina suffix and any unrelated query parameters.
String tileCacheKey(String url) {
  final queryStart = url.indexOf('?');
  if (queryStart < 0) return url;

  final fragmentStart = url.indexOf('#', queryStart);
  final queryEnd = fragmentStart < 0 ? url.length : fragmentStart;
  final parameters = url.substring(queryStart + 1, queryEnd).split('&');
  final retained = parameters.where((part) => part.split('=').first != 'key');
  if (retained.length == parameters.length) return url;

  final query = retained.isEmpty ? '' : '?${retained.join('&')}';
  return '${url.substring(0, queryStart)}$query${url.substring(queryEnd)}';
}
