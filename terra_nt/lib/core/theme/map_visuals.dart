import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Named visual values measured from the three native map references.
class AppMapVisuals {
  AppMapVisuals._();

  /// The box the camera may not be panned or zoomed outside of.
  ///
  /// Australia, widened north and south by the margin
  /// `CameraConstraint.contain` needs: that constraint keeps the camera's whole
  /// visible region inside the box, so at `AppMetrics.mapMinZoom` the box has
  /// to be comfortably taller than a phone viewport or every gesture — and the
  /// debug assert in `FlutterMap`'s options setter — would reject the camera.
  static final australiaCameraBounds = LatLngBounds(
    const LatLng(-50, 105),
    const LatLng(5, 160),
  );

  static const backdropRouteOpacity = 0.75;
  static const resultRouteOpacity = 0.85;

  static const backdropDashPattern = <double>[1, 7];
  static const resultDashPattern = <double>[1, 6];
}
