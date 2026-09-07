import '../../data/models/stop.dart';

List<int> reorder(List<int> order, int from, int to) {
  if (from < 0 || from >= order.length || order.isEmpty) {
    return List<int>.from(order);
  }

  final result = List<int>.from(order);
  final item = result.removeAt(from);
  final insertionIndex = to.clamp(0, result.length).toInt();
  result.insert(insertionIndex, item);
  return result;
}

List<int> remove(List<int> order, int originalIndex) =>
    order.where((index) => index != originalIndex).toList();

List<int> revertOne(List<int> order, int originalIndex) {
  final currentPosition = order.indexOf(originalIndex);
  if (currentPosition == -1) {
    return List<int>.from(order);
  }

  final result = List<int>.from(order);
  final item = result.removeAt(currentPosition);
  final insertionIndex = originalIndex.clamp(0, result.length).toInt();
  result.insert(insertionIndex, item);
  return result;
}

List<int> restoreRemoved(List<int> order, int totalStops) {
  final result = List<int>.from(order);
  for (var originalIndex = 0; originalIndex < totalStops; originalIndex++) {
    if (result.contains(originalIndex)) {
      continue;
    }
    final insertionIndex = originalIndex.clamp(0, result.length).toInt();
    result.insert(insertionIndex, originalIndex);
  }
  return result;
}

int removedCount(List<int> order, int totalStops) =>
    (totalStops - order.toSet().length).clamp(0, totalStops).toInt();

String removedLabel(int count) =>
    'Restore $count removed stop${count == 1 ? '' : 's'}';

String derivedMeta(int stopCount, int days) => '$days days · $stopCount stops';

String? driveNextForPosition(
  List<int> order,
  int position,
  List<Stop> baselineStops,
) {
  if (position < 0 || position >= order.length) {
    return null;
  }
  if (position == order.length - 1) {
    return null;
  }

  final currentIndex = order[position];
  final nextIndex = order[position + 1];
  if (currentIndex < 0 || currentIndex >= baselineStops.length ||
      nextIndex != currentIndex + 1) {
    return 'Drive time unavailable';
  }
  return baselineStops[currentIndex].driveNext ?? 'Drive time unavailable';
}
