import 'point_model.dart';

class StrokeModel {
  final String id;
  final List<PointModel> points;
  final int color; // Color.value int
  final double width;
  final bool isEraser;
  final bool isFill;

  StrokeModel({
    required this.id,
    List<PointModel>? points,
    this.color = 0xFF000000,
    this.width = 4.0,
    this.isEraser = false,
    this.isFill = false,
  }) : points = points ?? [];

  factory StrokeModel.fromJson(Map<String, dynamic> json) {
    return StrokeModel(
      id: json['id'] as String? ?? '',
      points: (json['pts'] as List?)
          ?.map((p) => PointModel.fromList(p as List))
          .toList() ?? [],
      color: json['c'] as int? ?? 0xFF000000,
      width: (json['w'] as num?)?.toDouble() ?? 4.0,
      isEraser: json['e'] as bool? ?? false,
      isFill: json['f'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pts': points.map((p) => p.toList()).toList(),
      'c': color,
      'w': width,
      'e': isEraser,
      'f': isFill,
    };
  }

  StrokeModel copyWith({List<PointModel>? points}) {
    return StrokeModel(
      id: id,
      points: points ?? this.points,
      color: color,
      width: width,
      isEraser: isEraser,
      isFill: isFill,
    );
  }

  void addPoint(PointModel point) {
    points.add(point);
  }
}
