import 'alignment.dart';
import 'point.dart';
import 'ship.dart';

class Field {
  final List<Point> __hitPoints = List.empty(growable: true);
  final List<Ship> __placedShips = List.empty(growable: true);
  final int size;

  Field(this.size);

  bool? tryHitShip(int xAxis, int yAxis) {
    //check if point has already been hit or out of bounds
    if (xAxis < 0 ||
        yAxis < 0 ||
        xAxis > size ||
        yAxis > size ||
        __hitPoints.any(
          (point) => point.xAxis == xAxis && point.yAxis == yAxis,
        )) {
      return null;
    }

    //check if there is a dead ship near of hit shit at current point
    var hitOrNear = __placedShips.any(
      (ship) =>
          ship.isPointHit(xAxis, yAxis) ||
          !ship.isAlive() && ship.isPointNear(xAxis, yAxis),
    );
    if (hitOrNear) {
      return null;
    }

    //check if there is a ship at this position
    var shipToHit = __placedShips
        .where((ship) => ship.containsPoint(xAxis, yAxis))
        .firstOrNull;
    if (shipToHit != null) {
      if (shipToHit.tryHit(xAxis, yAxis)) {
        __hitPoints.add(Point(xAxis, yAxis));
        return true;
      }
      return null;
    }

    //otherwise - just add to hit points
    __hitPoints.add(Point(xAxis, yAxis));
    return false;
  }

  String getSymbolFoPoint(int xAxis, int yAxis, bool hideShips) {
    //check if it is hit ship`s point
    if (__placedShips.any((ship) => ship.isPointHit(xAxis, yAxis))) {
      return "X";
    }

    //check if point has already been hit
    if (__hitPoints.any(
      (point) => point.xAxis == xAxis && point.yAxis == yAxis,
    )) {
      return "*";
    }
    //check if point is near to dead ship
    if (__placedShips.any(
      (ship) => !ship.isAlive() && ship.isPointNear(xAxis, yAxis),
    )) {
      return "*";
    }

    //check if there is ship at the point
    if (!hideShips &&
        __placedShips.any(
          (ship) =>
              ship.containsPoint(xAxis, yAxis) &&
              !ship.isPointHit(xAxis, yAxis),
        )) {
      return "■";
    }
    //empty field
    return "~";
  }

  bool tryAddShip(
    String name,
    int shipSize,
    xAxis,
    yAxis,
    Alignment alignment,
  ) {
    if (xAxis < 0 ||
        xAxis > size ||
        yAxis < 0 ||
        yAxis > size ||
        (alignment == Alignment.horizontal && xAxis + shipSize - 1 > size) ||
        (alignment == Alignment.vertical && yAxis + shipSize - 1 > size)) {
      return false;
    }

    Ship newShip = Ship(name, alignment, shipSize, xAxis, yAxis);
    if (__placedShips.any((ship) => ship.isCrosses(newShip))) {
      return false;
    }

    __placedShips.add(newShip);
    return true;
  }

  bool hasAliveShips() {
    return __placedShips.any((ship) => ship.isAlive());
  }
}
