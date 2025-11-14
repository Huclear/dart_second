import 'dart:convert';
import 'dart:io';

class Result {
  String __playerName;
  int __amountGames = 0;
  int __amountSucceeded = 0;
  int __amountFailures = 0;

  Result(this.__playerName);

  void increaseSuccessCount(int count) {
    __amountGames += count;
    __amountSucceeded += count;
  }

  void increaseFailureCountCount(int count) {
    __amountGames += count;
    __amountFailures += count;
  }

  Map<String, dynamic> toJson() {
    return {
      "playerName": __playerName,
      "amountSucceeded": __amountSucceeded,
      "amountFailures": __amountFailures,
    };
  }

  factory Result.fromJson(Map<String, dynamic> jsonData) {
    if (!jsonData.containsKey("playerName")) throw Exception("Not formatted");
    var res = Result(
      jsonData.entries.firstWhere((pair) {
            return pair.key == "playerName";
          }).value
          as String,
    );

    var succeededCount = jsonData.containsKey("amountSucceeded")
        ? jsonData.entries.firstWhere((pair) {
                return pair.key == "amountSucceeded";
              }).value
              as int
        : 0;
    var failedCount = jsonData.containsKey("amountFailures")
        ? jsonData.entries.firstWhere((pair) {
                return pair.key == "amountFailures";
              }).value
              as int
        : 0;

    res.increaseFailureCountCount(failedCount);
    res.increaseSuccessCount(succeededCount);
    return res;
  }

  Future<void> saveResult(String directoryPath) async {
    var directory = Directory(directoryPath);
    if (directory.existsSync()) {
      var saveFile = File(directoryPath + "\\" + __playerName + ".json");
      if (!(saveFile.existsSync())) {
        await saveFile.create();
      }

      var jsonData = jsonEncode(this);
      await saveFile.writeAsString(jsonData);
    } else
      throw Exception(
        "Directory with the path " + directoryPath + " was not found",
      );
  }

  Future<void> readResultsData(String directoryPath) async {
    var directory = Directory(directoryPath);
    if (directory.existsSync()) {
      var saveFile = File(directoryPath + "\\" + __playerName + ".json");
      if (!(saveFile.existsSync())) {
        return;
      }

      var jsonData = jsonDecode(await saveFile.readAsString());
      if (jsonData != null) {
        var res = Result.fromJson(jsonData);
        increaseFailureCountCount(res.__amountFailures);
        increaseSuccessCount(res.__amountSucceeded);
      }
    } else
      throw Exception(
        "Directory with the path " + directoryPath + " was not found",
      );
  }

  @override
  String toString() {
    return __playerName +
        " has already played " +
        __amountGames.toString() +
        "games with the relation of wins to failures of " +
        __amountSucceeded.toString() +
        ":" +
        __amountFailures.toString();
  }
}
