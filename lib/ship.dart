import 'package:dart_application_ship/alignment.dart';

class Ship {
  final String name;
  final int size;
  final Alignment alignment;
  int xStart;
  int yStart;

  Ship(this.name, this.alignment, this.size, this.xStart, this.yStart);

  List<int> hitPoints = List.empty(growable: true);

  bool tryHit(int xAxis, int yAxis) {
    if (xStart > xAxis || yStart > yAxis) {
      return false;
    }

    //check if it is horizontal axist
    if (alignment == Alignment.horizontal && yAxis == yStart) {
      int hitPoint = xAxis - xStart;
      if (hitPoint > size - 1 || hitPoints.contains(hitPoint)) {
        return false;
      }

      hitPoints.add(hitPoint);
      return true;
    }

    //check if it is vertical axis
    if (alignment == Alignment.vertical && xAxis == xStart) {
      int hitPoint = yAxis - yStart;
      if (hitPoint > size - 1 || hitPoints.contains(hitPoint)) {
        return false;
      }

      hitPoints.add(hitPoint);
      return true;
    }

    return false;
  }

  bool isAlive() {
    return hitPoints.length < size;
  }

  bool containsPoint(int xAxis, int yAxis) {
    if (xStart > xAxis || yStart > yAxis) {
      return false;
    } else if (alignment == Alignment.horizontal &&
        yAxis == yStart &&
        xAxis - xStart < size) {
      return true;
    } else if (alignment == Alignment.vertical &&
        xAxis == xStart &&
        yAxis - yStart < size) {
      return true;
    }

    return false;
  }

  bool isPointNear(int xAxis, int yAxis) {
    //calculating closed array for first ship

    //calculating closed array start coordinates
    var closedArray1StartX = xStart - 1;
    var closedArray1StartY = yStart - 1;

    //calculating closed array end coordinates
    var closedArray1EndX = alignment == Alignment.horizontal
        ? xStart + size
        : xStart + 1;
    var closedArray1EndY = alignment == Alignment.horizontal
        ? yStart + 1
        : yStart + size;

    return xAxis >= closedArray1StartX && xAxis <= closedArray1EndX
    && yAxis >= closedArray1StartY && yAxis <= closedArray1EndY;
  }

  bool isPointHit(int xAxis, int yAxis) {
    if (alignment == Alignment.horizontal && yAxis == yStart) {
      return hitPoints.contains(xAxis - xStart);
    } else if (alignment == Alignment.vertical && xAxis == xStart) {
      return hitPoints.contains(yAxis - yStart);
    }
    return false;
  }

  bool isCrosses(Ship other) {
    //calculating closed array for first ship

    //calculating closed array start coordinates
    var closedArray1StartX = xStart - 1;
    var closedArray1StartY = yStart - 1;

    //calculating closed array end coordinates
    var closedArray1EndX = alignment == Alignment.horizontal
        ? xStart + size
        : xStart + 1;
    var closedArray1EndY = alignment == Alignment.horizontal
        ? yStart + 1
        : yStart + size;

    //calculating closed array for seconf ship

    //calculating closed array start coordinates
    var closedArray2StartX = other.xStart;
    var closedArray2StartY = other.yStart;

    //calculating closed array end coordinates
    var closedArray2EndX = other.alignment == Alignment.horizontal
        ? other.xStart + other.size-1
        : other.xStart;
    var closedArray2EndY = other.alignment == Alignment.horizontal
        ? other.yStart
        : other.yStart + other.size-1;

    //comparing arrays
    bool xFree =
        (closedArray1StartX < closedArray2StartX &&
            closedArray1EndX < closedArray2StartX) ||
        closedArray1StartX > closedArray2EndX;
    bool yFree =
        (closedArray1StartY < closedArray2StartY &&
            closedArray1EndY < closedArray2StartY) ||
        closedArray1StartY > closedArray2EndY;

    return !xFree && !yFree;
  }
}
