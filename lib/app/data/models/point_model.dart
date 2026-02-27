class PointModel {
  final double x; // 0.0 to 1.0 (normalized to canvas width)
  final double y; // 0.0 to 1.0 (normalized to canvas height)
  final double p; // pressure (0.0 to 1.0), default 0.5 for mouse

  const PointModel({
    required this.x,
    required this.y,
    this.p = 0.5,
  });

  factory PointModel.fromList(List<dynamic> data) {
    if (data.length < 2) {
      return const PointModel(x: 0, y: 0);
    }
    return PointModel(
      x: (data[0] as num?)?.toDouble() ?? 0,
      y: (data[1] as num?)?.toDouble() ?? 0,
      p: data.length > 2 ? (data[2] as num?)?.toDouble() ?? 0.5 : 0.5,
    );
  }

  List<double> toList() => [x, y, p];

  @override
  String toString() => 'Point($x, $y, $p)';
}
