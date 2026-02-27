import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/game_constants.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/stroke_utils.dart';
import '../../data/models/point_model.dart';
import '../../data/models/stroke_model.dart';
import '../../data/providers/realtime_provider.dart';

class DrawingController extends GetxController {
  final RealtimeProvider _realtimeProvider = Get.find<RealtimeProvider>();
  static const _uuid = Uuid();

  // Canvas state
  final RxList<StrokeModel> strokes = <StrokeModel>[].obs;
  final Rx<StrokeModel?> currentStroke = Rx<StrokeModel?>(null);
  final RxList<StrokeModel> undoStack = <StrokeModel>[].obs;

  // Tool state
  final Rx<Color> selectedColor = const Color(0xFF000000).obs;
  final RxDouble strokeWidth = 4.0.obs;
  final RxBool isEraser = false.obs;
  final RxBool isFillMode = false.obs;
  final RxBool isEnabled = false.obs;

  // Batching
  final List<PointModel> _pointBuffer = [];
  Timer? _batchTimer;
  String? _currentStrokeId;
  int _batchSeq = 0;

  // Canvas size (set by the canvas widget)
  double canvasWidth = 0;
  double canvasHeight = 0;

  // --- Local Drawing (Drawer only) ---

  void onPanStart(DragStartDetails details) {
    if (!isEnabled.value) return;

    _currentStrokeId = _uuid.v4();
    _batchSeq = 0;

    final point = _normalizeOffset(details.localPosition);
    final stroke = StrokeModel(
      id: _currentStrokeId!,
      color: isEraser.value ? AppColors.canvasBg.toARGB32() : selectedColor.value.toARGB32(),
      width: isEraser.value ? strokeWidth.value * 3 : strokeWidth.value,
      isEraser: isEraser.value,
    );
    stroke.addPoint(point);
    currentStroke.value = stroke;

    _pointBuffer.add(point);
    _startBatchTimer();
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (!isEnabled.value || currentStroke.value == null) return;

    final point = _normalizeOffset(details.localPosition);
    currentStroke.value!.addPoint(point);
    currentStroke.refresh();

    _pointBuffer.add(point);
  }

  void onPanEnd(DragEndDetails details) {
    if (!isEnabled.value || currentStroke.value == null) return;

    // Flush remaining points
    _flushBatch(isEnd: true);
    _stopBatchTimer();

    // Finalize stroke
    strokes.add(currentStroke.value!);
    currentStroke.value = null;
    undoStack.clear();
    _currentStrokeId = null;
  }

  void undo() {
    if (!isEnabled.value || strokes.isEmpty) return;
    final removed = strokes.removeLast();
    undoStack.add(removed);

    _realtimeProvider.broadcast(
      event: SupabaseConstants.eventStrokeUndo,
      payload: {'stroke_id': removed.id},
    );
  }

  void redo() {
    if (!isEnabled.value || undoStack.isEmpty) return;
    final restored = undoStack.removeLast();
    strokes.add(restored);

    _realtimeProvider.broadcast(
      event: SupabaseConstants.eventStrokeData,
      payload: {
        'action': 'full',
        'stroke_id': restored.id,
        'points': StrokeUtils.serializePointBatch(restored.points),
        'color': restored.color,
        'width': restored.width,
        'eraser': restored.isEraser,
        'fill': restored.isFill,
      },
    );
  }

  void clearCanvas() {
    if (!isEnabled.value) return;
    strokes.clear();
    currentStroke.value = null;
    undoStack.clear();

    _realtimeProvider.broadcast(
      event: SupabaseConstants.eventStrokeClear,
      payload: {},
    );
  }

  // --- Tool Selection ---

  void setColor(Color color) {
    selectedColor.value = color;
    isEraser.value = false;
  }

  void setStrokeWidth(double width) {
    strokeWidth.value = width;
  }

  void toggleEraser() {
    isEraser.value = !isEraser.value;
    if (isEraser.value) {
      isFillMode.value = false;
    }
  }

  void toggleFillMode() {
    isFillMode.value = !isFillMode.value;
    if (isFillMode.value) {
      isEraser.value = false;
    }
  }

  void fillCanvas(Color color) {
    if (!isEnabled.value) return;

    final fillStroke = StrokeModel(
      id: _uuid.v4(),
      color: color.toARGB32(),
      width: 0,
      isFill: true,
    );
    strokes.add(fillStroke);
    undoStack.clear();

    _realtimeProvider.broadcast(
      event: SupabaseConstants.eventStrokeData,
      payload: {
        'action': 'full',
        'stroke_id': fillStroke.id,
        'points': [],
        'color': fillStroke.color,
        'width': 0.0,
        'eraser': false,
        'fill': true,
      },
    );
  }

  // --- Broadcast (Outgoing) ---

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(
      const Duration(milliseconds: GameConstants.strokeBatchIntervalMs),
      (_) => _flushBatch(),
    );
  }

  void _stopBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }

  void _flushBatch({bool isEnd = false}) {
    if (_pointBuffer.isEmpty || _currentStrokeId == null) return;

    final batch = List<PointModel>.from(_pointBuffer);
    _pointBuffer.clear();
    _batchSeq++;

    _realtimeProvider.broadcast(
      event: SupabaseConstants.eventStrokeData,
      payload: {
        'action': isEnd ? 'end' : 'batch',
        'stroke_id': _currentStrokeId,
        'points': StrokeUtils.serializePointBatch(batch),
        'color': currentStroke.value?.color ?? 0xFF000000,
        'width': currentStroke.value?.width ?? 4.0,
        'eraser': currentStroke.value?.isEraser ?? false,
        'seq': _batchSeq,
      },
    );
  }

  // --- Broadcast (Incoming — for guessers) ---

  void onRemoteStrokeData(Map<String, dynamic> data) {
    final action = data['action'] as String?;
    final strokeId = data['stroke_id'] as String?;
    if (strokeId == null) return;

    final points = StrokeUtils.deserializePointBatch(
      data['points'] as List<dynamic>? ?? [],
    );
    final color = data['color'] as int? ?? 0xFF000000;
    final width = (data['width'] as num?)?.toDouble() ?? 4.0;
    final eraser = data['eraser'] as bool? ?? false;
    final fill = data['fill'] as bool? ?? false;

    if (action == 'full') {
      // Full stroke (redo/snapshot) or fill
      final stroke = StrokeModel(
        id: strokeId,
        points: points,
        color: color,
        width: width,
        isEraser: eraser,
        isFill: fill,
      );
      strokes.add(stroke);
      return;
    }

    // Find or create the in-progress stroke
    if (currentStroke.value?.id == strokeId) {
      // Continue existing stroke
      for (final p in points) {
        currentStroke.value!.addPoint(p);
      }
      currentStroke.refresh();
    } else {
      // New stroke from remote
      final stroke = StrokeModel(
        id: strokeId,
        points: points,
        color: color,
        width: width,
        isEraser: eraser,
      );
      currentStroke.value = stroke;
    }

    if (action == 'end') {
      // Finalize
      if (currentStroke.value != null) {
        strokes.add(currentStroke.value!);
        currentStroke.value = null;
      }
    }
  }

  void onRemoteStrokeUndo(Map<String, dynamic> data) {
    final strokeId = data['stroke_id'] as String?;
    if (strokeId != null) {
      strokes.removeWhere((s) => s.id == strokeId);
    } else if (strokes.isNotEmpty) {
      strokes.removeLast();
    }
  }

  void onRemoteStrokeClear(Map<String, dynamic> data) {
    strokes.clear();
    currentStroke.value = null;
  }

  // --- Canvas Recovery (Late Joiners) ---

  void requestCanvasSnapshot() {
    _realtimeProvider.broadcast(
      event: SupabaseConstants.eventCanvasRequest,
      payload: {'requester_id': 'late_joiner'},
    );
  }

  void onCanvasRequest(Map<String, dynamic> data) {
    if (!isEnabled.value) return; // Only drawer responds
    sendCanvasSnapshot();
  }

  void sendCanvasSnapshot() {
    final allStrokes = StrokeUtils.serializeStrokes(strokes);
    _realtimeProvider.broadcast(
      event: SupabaseConstants.eventCanvasSnapshot,
      payload: {'strokes': allStrokes},
    );
  }

  void onCanvasSnapshot(Map<String, dynamic> data) {
    final strokeData = data['strokes'] as List<dynamic>?;
    if (strokeData == null) return;
    strokes.value = StrokeUtils.deserializeStrokes(strokeData);
  }

  // --- Reset ---

  void resetCanvas() {
    strokes.clear();
    currentStroke.value = null;
    undoStack.clear();
    _pointBuffer.clear();
    _stopBatchTimer();
    _currentStrokeId = null;
    _batchSeq = 0;
    isFillMode.value = false;
    isEraser.value = false;
  }

  // --- Helpers ---

  PointModel _normalizeOffset(Offset offset) {
    return StrokeUtils.normalizePoint(
      rawX: offset.dx,
      rawY: offset.dy,
      canvasWidth: canvasWidth > 0 ? canvasWidth : 1,
      canvasHeight: canvasHeight > 0 ? canvasHeight : 1,
    );
  }

  @override
  void onClose() {
    _stopBatchTimer();
    super.onClose();
  }
}
