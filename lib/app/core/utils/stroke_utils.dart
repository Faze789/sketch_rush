import '../../data/models/point_model.dart';
import '../../data/models/stroke_model.dart';

class StrokeUtils {
  StrokeUtils._();

  /// Serialize a list of strokes for canvas snapshot broadcast
  static List<Map<String, dynamic>> serializeStrokes(List<StrokeModel> strokes) {
    return strokes.map((s) => s.toJson()).toList();
  }

  /// Deserialize strokes from canvas snapshot
  static List<StrokeModel> deserializeStrokes(List<dynamic> data) {
    return data
        .map((s) => StrokeModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Normalize a raw canvas position to 0.0-1.0 range
  static PointModel normalizePoint({
    required double rawX,
    required double rawY,
    required double canvasWidth,
    required double canvasHeight,
    double pressure = 0.5,
  }) {
    return PointModel(
      x: (rawX / canvasWidth).clamp(0.0, 1.0),
      y: (rawY / canvasHeight).clamp(0.0, 1.0),
      p: pressure,
    );
  }

  /// Denormalize a point to canvas coordinates
  static ({double x, double y}) denormalizePoint({
    required PointModel point,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    return (x: point.x * canvasWidth, y: point.y * canvasHeight);
  }

  /// Serialize a batch of points for broadcast (compact format)
  static List<List<double>> serializePointBatch(List<PointModel> points) {
    return points.map((p) => p.toList()).toList();
  }

  /// Deserialize a batch of points from broadcast
  static List<PointModel> deserializePointBatch(List<dynamic> data) {
    return data
        .map((p) => PointModel.fromList(p as List<dynamic>))
        .toList();
  }
}
