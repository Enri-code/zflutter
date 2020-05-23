import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zflutter/src/core/renderer.dart';

import 'core.dart';

@immutable
class ZPath {
  final List<ZPathCommand> _commands;
  final bool closed;

  List<ZPathCommand> get commands => _commands;

  const ZPath([List<ZPathCommand> commands])
      : this.closed = false,
        this._commands = commands ?? const [];

  const ZPath.closed([List<ZPathCommand> commands])
      : this.closed = false,
        this._commands = commands ?? const [];

  ZPath close() => ZPath(_commands);

  ZPath addCommand(ZPathCommand command) {
    return ZPath([..._commands, command]);
  }

  ZPath move({double x = 0, double y = 0, double z = 0}) {
   // assert(!(vector != null && (x != 0 || y!= null || y!= null)));
    return addCommand(ZMove(x, y, z));
  }

  ZPath moveVector(ZVector vector) {
    return addCommand(ZMove.vector(vector ?? ZVector.zero));
  }

  ZPath line({double x = 0, double y = 0, double z = 0}) {
    return addCommand(ZLine(x, y, z));
  }

  ZPath lineVector(ZVector vector) {
    return addCommand(ZLine.vector(vector));
  }

  ZPath arc({@required ZVector corner, @required ZVector end}) {
    return addCommand(ZArc(corner: corner, end: end));
  }

  ZPath bezier(List<ZVector> points) {
    return addCommand(ZBezier(points));
  }
}

// TODO: This Paths needs to be immutable;
abstract class ZPathCommand {
  final ZVector endRenderPoint = ZVector.zero;

  void reset();

  ZPathCommand transform(ZVector translation, ZVector rotate, ZVector scale);

  void render(ZRenderer renderer);

  ZVector point({index = 0});

  ZVector renderPoint({int index = 0});

  set previous(ZVector previousPoint) {}

  ZPathCommand clone();
}

class ZMove extends ZPathCommand {
  ZVector _point;

  ZVector _renderPoint;

  ZVector get endRenderPoint => _renderPoint;

  ZMove.vector(this._point) {
    _renderPoint = _point.copy();
  }

  ZMove(double x, double y, double z) {
    _renderPoint = ZVector(x, y, z);
  }

  ZMove.only({double x = 0, double y = 0, double z = 0}) {
    _renderPoint = ZVector(x, y, z);
  }

  void reset() {
    _renderPoint = _point;
  }

  ZPathCommand transform(ZVector translation, ZVector rotate, ZVector scale) {
    return ZMove.vector(_renderPoint.transform(translation, rotate, scale));
  }

  void render(ZRenderer renderer) {
    renderer.move(_renderPoint);
  }

  ZVector point({index = 0}) {
    return _point;
  }

  ZVector renderPoint({index = 0}) {
    return _renderPoint;
  }

  ZPathCommand clone() {
    return ZMove.vector(this.point());
  }
}

class ZLine extends ZPathCommand {
  ZVector _point;

  ZVector _renderPoint;

  ZVector get endRenderPoint => _renderPoint;

  ZLine.vector(this._point) {
    _renderPoint = _point.copy();
  }

  ZLine(double x, double y, double z) {
    _renderPoint = ZVector(x, y, z);
  }

  ZLine.only({double x = 0, double y = 0, double z = 0}) {
    _renderPoint = ZVector(x, y, z);
  }

  void reset() {
    _renderPoint = _point;
  }

  ZPathCommand transform(ZVector translation, ZVector rotate, ZVector scale) {
    return ZLine.vector(_renderPoint.transform(translation, rotate, scale));
  }

  void render(ZRenderer renderer) {
    renderer.line(_renderPoint);
  }

  ZVector point({index = 0}) {
    return _point;
  }

  ZVector renderPoint({index = 0}) {
    return _renderPoint;
  }

  ZPathCommand clone() {
    return ZLine.vector(_point);
  }
}

class ZBezier extends ZPathCommand {
  List<ZVector> points;

  List<ZVector> renderPoints;

  ZVector get endRenderPoint => renderPoints.last;

  ZBezier(this.points) {
    renderPoints = points.map((e) => e.copy()).toList();
  }

  void reset() {
    /* renderPoints.asMap().forEach((index, vector) {
      vector.set(points[index]);
    });*/
  }

  ZPathCommand transform(ZVector translation, ZVector rotate, ZVector scale) {
    return ZBezier(renderPoints.map((point) {
      return point.transform(translation, rotate, scale);
    }).toList());
  }

  void render(ZRenderer renderer) {
    renderer.bezier(renderPoints[0], renderPoints[1], renderPoints[2]);
  }

  ZVector point({index = 0}) {
    return points[index];
  }

  ZVector renderPoint({index = 0}) {
    return renderPoints[index];
  }

  ZPathCommand clone() {
    return ZBezier(this.points);
  }
}

const double _arcHandleLength = 9 / 16;

class ZArc extends ZPathCommand {
  List<ZVector> points;
  ZVector _previous = ZVector.zero;

  List<ZVector> renderPoints;

  ZVector get endRenderPoint => renderPoints.last;

  ZArc.list(this.points, [this._previous]) {
    renderPoints = points.map((e) => e.copy()).toList();
  }

  ZArc({@required ZVector corner, @required ZVector end, ZVector previous})
      : assert(corner != null && end != null,
            'Corner and end points can\'t be null') {
    _previous = previous;

    points = [corner, end];

    renderPoints = points.map((e) => e.copy()).toList();
  }

  List<ZVector> controlPoints = [ZVector.zero, ZVector.zero];

  void reset() {
    renderPoints = List.generate(renderPoints.length, (i) => points[i]);
  }

  ZPathCommand transform(ZVector translation, ZVector rotate, ZVector scale) {
    return ZArc.list(renderPoints.map((point) {
      return point.transform(translation, rotate, scale);
    }).toList());
  }

  void render(ZRenderer renderer) {
    assert(_previous != null);
    var prev = _previous;
    var corner = renderPoints[0];
    var end = renderPoints[1];
    var a = ZVector.lerp(prev, corner, _arcHandleLength);
    var b = ZVector.lerp(end, corner, _arcHandleLength);
    renderer.bezier(a, b, end);
  }

  ZVector point({index = 0}) {
    return points[index];
  }

  ZVector renderPoint({index = 0}) {
    return renderPoints[index];
  }

  @override
  set previous(ZVector previousPoint) {
    assert(previousPoint != null);
    _previous = previousPoint;
  }

  ZPathCommand clone() {
    return ZArc.list(points, _previous);
  }
}
