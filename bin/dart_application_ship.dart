import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import '../lib/alignment.dart';
import '../lib/field.dart';
import '../lib/point.dart';
import '../lib/result.dart';

const String BOT_NAME = "BOT";
Future<void> main(List<String> arguments) async {
  Isolate? mainIsolate = null;
  ReceivePort receiveResultsPort = ReceivePort();
  SendPort? sendResultsPort = null;
  receiveResultsPort.listen((message) async {
    if (message is SendPort)
      sendResultsPort = message;
    else if (message is Map<String, Result>) {
      mainIsolate?.kill(priority: Isolate.immediate);
      clearConsole();

      for (var element in message.entries) {
        await element.value.readResultsData("C:\\Users\\Kombucha\\Desktop\\testDrive");
        await element.value.saveResult("C:\\Users\\Kombucha\\Desktop\\testDrive");
        print("\n\t" + element.toString());
      }
      exit(0);
    }
  });
  Isolate.spawn(startResultsIsolate, receiveResultsPort.sendPort);

  ReceivePort mainReceiver = ReceivePort();
  mainIsolate = await Isolate.spawn(processGame, mainReceiver.sendPort);
  mainReceiver.listen((message) {
    if (message is Map<String, Field>) sendResultsPort?.send(message);
  });
}

void processGame(SendPort port) async {
  bool playWithBot = true;
  bool randomizePlayerField = false;
  int fieldSize = 10;
  Map<String, Field> playerFields = {};
  Future<Field>? field1Generation;
  Future<Field>? field2Generation;

  //select field size
  print(
    "\nBefore you start i`d like to ask if you have any preferences in field size (not the standard one)? \n\tEnter the size (min - 10, max - 20): ",
  );
  var selecetdSize = stdin.readLineSync();
  while (selecetdSize == null || int.tryParse(selecetdSize) == null) {
    print(
      "\nLet me remind you that the format is just the number For example, \"10\". This will be equal to: \"I prefer the size of field equal to 10x10\"",
    );
    selecetdSize = stdin.readLineSync();
  }
  fieldSize = int.parse(selecetdSize);
  fieldSize = fieldSize < 10 || fieldSize > 20 ? 10 : fieldSize;

  //check if bot needed
  print(
    "\nBy the way, just before you start i`d like to ask if you have the real opponent to play with. If not you`ll be pushed to play with stupid bot, who place signs randomly. (YES - turn bot of)",
  );
  var answer = stdin.readLineSync();
  if (answer == null || answer.toLowerCase() != "yes") {
    print(
      "\nWell, enjoy playing with the bot, not knowing basic combinations to win.",
    );
  } else {
    print("\nWell, enjoy this console sheet, i guess.");
    playWithBot = false;
  }

  //asking if needs random generation
  print(
    "\nNow, you`re about to fill your field with ships. Would you rather place the ships by yourself than allow us randomly generate them. (yes|no)? #Asking both players and applied to both players",
  );
  var randomize = stdin.readLineSync();
  if (randomize == null || randomize.toLowerCase() == "yes") {
    print("\nWell, enjoy the random field we`ve generated right fir you.");
  } else {
    print("\nWell, enjoy this console sheet, i guess.");
    randomizePlayerField = true;
  }

  //generating fields
  field1Generation = randomizePlayerField
      ? Isolate.run(() async {
          return randomizeField(fieldSize);
        })
      : null;
  field2Generation = randomizePlayerField || playWithBot
      ? Isolate.run(() async {
          return randomizeField(fieldSize);
        })
      : null;

  //inputing names for players
  print("\nFor now i need the name for \"Player 1\": ");
  var name1 = stdin.readLineSync() ?? "Player 1";
  var name2 = BOT_NAME;
  if (!playWithBot) {
    print("\nFor now i need the name for \"Player 2\": ");
    name2 = stdin.readLineSync() ?? "Player 2";
    while (name2 == name1) {
      print(
        "That name has already been taken!!! \nFor now i need the name for \"Player 2\": ",
      );
      name2 = stdin.readLineSync() ?? "Player 2";
    }
  }

  //generating field for player 1
  if (field1Generation == null)
    playerFields.addAll({name1: initializeField(fieldSize)});
  else
    playerFields.addAll({name1: (await field1Generation)});

  //generating field for player 2
  if (field2Generation == null)
    playerFields.addAll({name2: initializeField(fieldSize)});
  else
    playerFields.addAll({name2: (await field2Generation)});

  //the fight
  while (true) {
    //showing player 1 fields in compare
    clearConsole();
    print(playerFields.entries.first.key);
    printField(playerFields.entries.first.value, false);
    printField(playerFields.entries.last.value, false);

    //reading hit point
    var hitPoint = requirePointInput();
    var hadHit = playerFields.entries.last.value.tryHitShip(
      hitPoint.xAxis,
      hitPoint.yAxis,
    );
    while (hadHit == null || hadHit) {
      clearConsole();
      printField(playerFields.entries.first.value, false);
      printField(playerFields.entries.last.value, false);
      hitPoint = requirePointInput();
      hadHit = playerFields.entries.last.value.tryHitShip(
        hitPoint.xAxis,
        hitPoint.yAxis,
      );
    }

    //showing player 2 fields in compare
    clearConsole();
    if (!playWithBot) {
      print(playerFields.entries.last.key);
      printField(playerFields.entries.last.value, false);
      printField(playerFields.entries.first.value, true);

      //reading hit point
      hitPoint = requirePointInput();
      var hadHit = playerFields.entries.first.value.tryHitShip(
        hitPoint.xAxis,
        hitPoint.yAxis,
      );
      while (hadHit == null || hadHit) {
        clearConsole();
        printField(playerFields.entries.last.value, false);
        printField(playerFields.entries.first.value, true);
        hitPoint = requirePointInput();
        hadHit = playerFields.entries.first.value.tryHitShip(
          hitPoint.xAxis,
          hitPoint.yAxis,
        );
      }
    } else {
      //randoizing hit point
      Random random = Random();
      hitPoint = Point(
        random.nextInt(fieldSize) + 1,
        random.nextInt(fieldSize) + 1,
      );
      var hadHit = playerFields.entries.first.value.tryHitShip(
        hitPoint.xAxis,
        hitPoint.yAxis,
      );
      while (hadHit == null || hadHit) {
        hitPoint = Point(
          random.nextInt(fieldSize) + 1,
          random.nextInt(fieldSize) + 1,
        );
        hadHit = playerFields.entries.first.value.tryHitShip(
          hitPoint.xAxis,
          hitPoint.yAxis,
        );
      }
    }
    port.send(playerFields);
  }
}

Point requirePointInput() {
  print("""
      Please input point in format "<xAxis>:<yAxis>": 
      """);
  var turnInput = stdin.readLineSync() ?? "";
  RegExp format = RegExp(r'[0-9]{1,}\:[0-9]{1,}');
  while (!format.hasMatch(turnInput)) {
    print(
      "Let me remind you that the format is to place x axis, then - vertical double dot and then - y axis. For example, 1:2. This will be equal to: \"Place my ship at row 2, column 1\"",
    );
    turnInput = stdin.readLineSync() ?? "";
  }
  var axises = turnInput.split(':');
  var xAxis = int.parse(axises[0]);
  var yAxis = int.parse(axises[1]);

  return Point(xAxis, yAxis);
}

Field initializeField(int size) {
  Field playerField = Field(size);

  int singlesCount = (size / 10.0 * 4).round();
  int doublesCount = (size / 10.0 * 3).round();
  int tripplesCout = (size / 10.0 * 2).round();
  int quadriplesCount = (size / 10.0).round();

  while (singlesCount + doublesCount + tripplesCout + quadriplesCount > 0) {
    printField(playerField, false);

    //selecting ship type
    print("""You have:
      * $singlesCount of one-cell ships;
      * $doublesCount of two-cell ships;
      * $tripplesCout of three-cell ships;
      * $quadriplesCount of four-cell ships.

      Please select the type of ship(1-4, default - first that have more than 1 remaining);
""");

    var type = int.tryParse(stdin.readLineSync() ?? "1") ?? 1;
    var firstFilledOne = singlesCount > 0
        ? 1
        : doublesCount > 0
        ? 2
        : tripplesCout > 0
        ? 3
        : 4;

    if (type == 1 && singlesCount <= 0) {
      type = firstFilledOne;
    } else if (type == 2 && doublesCount <= 0) {
      type = firstFilledOne;
    } else if (type == 3 && tripplesCout <= 0) {
      type = firstFilledOne;
    } else if (type == 4 && quadriplesCount <= 0) {
      type = firstFilledOne;
    }

    //Selecting start point
    print("""Placing ship of type $type
      Please input start point in format "<xAxis>:<yAxis>": 
      """);
    var turnInput = stdin.readLineSync() ?? "";
    RegExp format = RegExp(r'[0-9]{1,}\:[0-9]{1,}');
    while (!format.hasMatch(turnInput)) {
      print(
        "Let me remind you that the format is to place x axis, then - vertical double dot and then - y axis. For example, 1:2. This will be equal to: \"Place my ship at row 2, column 1\"",
      );
      turnInput = stdin.readLineSync() ?? "";
    }

    //selecting axis
    print("""Placing ship of type $type
      Please input ship`s axis:
      v - vertical;
      h - horizontal.
      Select (default is h): 
      """);
    var axisInput = stdin.readLineSync() ?? "";

    //placing the ship
    var shipAlignment = axisInput.toLowerCase() == "v"
        ? Alignment.vertical
        : Alignment.horizontal;
    var axises = turnInput.split(':');
    var xAxis = int.parse(axises[0]);
    var yAxis = int.parse(axises[1]);

    if (playerField.tryAddShip(
      "Type $type",
      type,
      xAxis,
      yAxis,
      shipAlignment,
    )) {
      switch (type) {
        case 1:
          singlesCount -= 1;
          break;
        case 2:
          doublesCount -= 1;
          break;
        case 3:
          tripplesCout -= 1;
          break;
        case 4:
          quadriplesCount -= 1;
          break;
      }
    }
  }

  //returning filled field
  return playerField;
}

Field randomizeField(int size) {
  Field playerField = Field(size);
  Random random = Random();

  int singlesCount = (size / 10.0 * 4).round();
  int doublesCount = (size / 10.0 * 3).round();
  int tripplesCout = (size / 10.0 * 2).round();
  int quadriplesCount = (size / 10.0).round();

  while (singlesCount + doublesCount + tripplesCout + quadriplesCount > 0) {
    var firstFilledOne = singlesCount > 0
        ? 1
        : doublesCount > 0
        ? 2
        : tripplesCout > 0
        ? 3
        : 4;
    var x = random.nextInt(size) + 1;
    var y = random.nextInt(size) + 1;
    var alignment = random.nextBool()
        ? Alignment.horizontal
        : Alignment.vertical;

    while (!playerField.tryAddShip(
      "Type$firstFilledOne",
      firstFilledOne,
      x,
      y,
      alignment,
    )) {
      x = random.nextInt(size) + 1;
      y = random.nextInt(size) + 1;
      alignment = random.nextBool() ? Alignment.horizontal : Alignment.vertical;
    }

    switch (firstFilledOne) {
      case 1:
        singlesCount -= 1;
        break;
      case 2:
        doublesCount -= 1;
        break;
      case 3:
        tripplesCout -= 1;
        break;
      case 4:
        quadriplesCount -= 1;
        break;
    }
  }

  return playerField;
}

void clearConsole() {
  print("\x1B[2J\x1B[H");
}

void printField(Field playerField, bool hideShips) {
  stdout.writeln();

  //showing upper numbers for the table
  stdout.write("  ");
  for (var j = 1; j <= playerField.size; j++) {
    var symbolToWrite = j < 10 ? " $j" : "$j";
    stdout.write("\t$symbolToWrite");
  }

  //showing each line for the table
  for (var i = 1; i <= playerField.size; i++) {
    stdout.writeln();
    var symbolToWrite = i < 10 ? " $i" : "$i";

    //showing line i for first table
    stdout.write(symbolToWrite);
    for (var j = 1; j <= playerField.size; j++) {
      var fieldSymb = playerField.getSymbolFoPoint(j, i, hideShips);
      stdout.write("\t $fieldSymb");
    }
  }
  stdout.writeln();
}

void startResultsIsolate(SendPort port) {
  final receivePort = ReceivePort();
  port.send(receivePort.sendPort);

  receivePort.listen((message) {
    try {
      if (message is Map<String, Field> &&
          message.entries.any((f) {
            return !f.value.hasAliveShips();
          })) {
        var playersRes = message.map((key, value) {
          var res = Result(key);
          if (value.hasAliveShips()) {
            res.increaseSuccessCount(1);
          } else {
            res.increaseFailureCountCount(1);
          }

          return MapEntry(key, res);
        });
        port.send(playersRes);
      } else {
        port.send(null);
      }
    } catch (e) {
      port.send(e.toString());
    }
  });
}
