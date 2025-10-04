import 'package:flutter/material.dart';

class DrawPoint {
  final Offset point;
  final Paint paint;

  DrawPoint({required this.point, required this.paint});

  Map<String, dynamic> toJson() {
    return {
      'x': point.dx,
      'y': point.dy,
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
    };
  }

  factory DrawPoint.fromJson(Map<String, dynamic> json) {
    final paint = Paint()
      ..color = Color(json['color'])
      ..strokeWidth = json['strokeWidth']
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    return DrawPoint(
      point: Offset(json['x'].toDouble(), json['y'].toDouble()),
      paint: paint,
    );
  }
}

class DrawingData {
  final List<List<DrawPoint>> strokes;

  DrawingData({required this.strokes});

  Map<String, dynamic> toJson() {
    return {
      'strokes': strokes
          .map((stroke) => stroke.map((point) => point.toJson()).toList())
          .toList(),
    };
  }

  factory DrawingData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> strokesJson = json['strokes'];
    final List<List<DrawPoint>> strokes =
        strokesJson.map<List<DrawPoint>>((strokeJson) {
      final List<dynamic> pointsJson = strokeJson;
      return pointsJson
          .map<DrawPoint>((pointJson) => DrawPoint.fromJson(pointJson))
          .toList();
    }).toList();

    return DrawingData(strokes: strokes);
  }
}

class DrawingPad extends StatefulWidget {
  final List<dynamic>? drawings;
  final Function(List<dynamic>) onDrawingComplete;
  final Color backgroundColor;
  final bool isReadOnly;

  const DrawingPad({
    Key? key,
    this.drawings,
    required this.onDrawingComplete,
    this.backgroundColor = Colors.white,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  State<DrawingPad> createState() => _DrawingPadState();
}

class _DrawingPadState extends State<DrawingPad> {
  List<List<DrawPoint>> _strokes = [];
  List<DrawPoint> _currentStroke = [];
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 3.0;
  bool _isErasing = false;

  @override
  void initState() {
    super.initState();
    _loadDrawings();
  }

  void _loadDrawings() {
    if (widget.drawings != null && widget.drawings!.isNotEmpty) {
      try {
        final List<dynamic> drawingsJson = widget.drawings!;
        _strokes = drawingsJson.map<List<DrawPoint>>((stroke) {
          final List<dynamic> pointsJson = stroke;
          return pointsJson
              .map<DrawPoint>((pointJson) => DrawPoint.fromJson(pointJson))
              .toList();
        }).toList();
      } catch (e) {
        debugPrint('Error loading drawings: $e');
        _strokes = [];
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.isReadOnly) return;

    final paint = Paint()
      ..color = _isErasing ? widget.backgroundColor : _currentColor
      ..strokeWidth = _isErasing ? _currentStrokeWidth * 3 : _currentStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    setState(() {
      _currentStroke = [DrawPoint(point: details.localPosition, paint: paint)];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isReadOnly || _currentStroke.isEmpty) return;

    final paint = _currentStroke.first.paint;
    setState(() {
      _currentStroke.add(DrawPoint(point: details.localPosition, paint: paint));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isReadOnly || _currentStroke.isEmpty) return;

    setState(() {
      _strokes.add(List.from(_currentStroke));
      _currentStroke = [];

      // Convert strokes to JSON and call onDrawingComplete
      final List<List<Map<String, dynamic>>> drawingsJson =
          _strokes.map((stroke) {
        return stroke.map((point) => point.toJson()).toList();
      }).toList();

      widget.onDrawingComplete(drawingsJson);
    });
  }

  void _clearDrawing() {
    if (widget.isReadOnly) return;
    setState(() {
      _strokes = [];
      widget.onDrawingComplete([]);
    });
  }

  void _toggleEraser() {
    if (widget.isReadOnly) return;
    setState(() {
      _isErasing = !_isErasing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: widget.backgroundColor,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: DrawingPainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                ),
                child: Container(),
              ),
            ),
          ),
        ),
        if (!widget.isReadOnly)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Color selector
                PopupMenuButton<Color>(
                  icon: Icon(Icons.color_lens, color: _currentColor),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: Colors.black,
                      child:
                          Container(width: 24, height: 24, color: Colors.black),
                    ),
                    PopupMenuItem(
                      value: Colors.blue,
                      child:
                          Container(width: 24, height: 24, color: Colors.blue),
                    ),
                    PopupMenuItem(
                      value: Colors.red,
                      child:
                          Container(width: 24, height: 24, color: Colors.red),
                    ),
                    PopupMenuItem(
                      value: Colors.green,
                      child:
                          Container(width: 24, height: 24, color: Colors.green),
                    ),
                    PopupMenuItem(
                      value: Colors.yellow,
                      child: Container(
                          width: 24, height: 24, color: Colors.yellow),
                    ),
                  ],
                  onSelected: (color) {
                    setState(() {
                      _currentColor = color;
                      _isErasing = false;
                    });
                  },
                ),
                // Stroke width selector
                PopupMenuButton<double>(
                  icon: const Icon(Icons.line_weight),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1.0,
                      child: Container(height: 1, color: Colors.black),
                    ),
                    PopupMenuItem(
                      value: 3.0,
                      child: Container(height: 3, color: Colors.black),
                    ),
                    PopupMenuItem(
                      value: 5.0,
                      child: Container(height: 5, color: Colors.black),
                    ),
                    PopupMenuItem(
                      value: 8.0,
                      child: Container(height: 8, color: Colors.black),
                    ),
                  ],
                  onSelected: (width) {
                    setState(() {
                      _currentStrokeWidth = width;
                    });
                  },
                ),
                // Eraser button
                IconButton(
                  icon: Icon(
                    Icons.auto_fix_high,
                    color: _isErasing
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  onPressed: _toggleEraser,
                ),
                // Clear button
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _clearDrawing,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<DrawPoint>> strokes;
  final List<DrawPoint> currentStroke;

  DrawingPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(
          stroke[i].point,
          stroke[i + 1].point,
          stroke[i].paint,
        );
      }
    }

    // Draw current stroke
    for (int i = 0; i < currentStroke.length - 1; i++) {
      canvas.drawLine(
        currentStroke[i].point,
        currentStroke[i + 1].point,
        currentStroke[i].paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true;
  }
}
