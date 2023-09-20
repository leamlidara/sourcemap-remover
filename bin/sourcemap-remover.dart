import "dart:convert";
import "dart:io";

void main(List<String> arguments) {
  List<String> knowFileTypes = [".js", ".ts", ".css", ".sass"];
  if (arguments.contains("-h") || arguments.contains("--help")) {
    print("SourceMap remover v1.0.2 by LEAM LIDARA");
    print("https://github.com/leamlidara");
    print("---------------------------------------------");
    print("");
    print("Usage: ");
    print("sourcemap-remover [option [directory_path]]");
    print("options: -h,  --help : display this help");
    print("");
    print("Noted: If a directory path is not specified, the application will use the current directory.");
    print("");
    print("Support file types: ${knowFileTypes.join(', ')}");
    return;
  }

  List<FileSystemEntity> lst;
  if (arguments.isNotEmpty) {
    var dir = Directory(arguments[0]);
    if (dir.existsSync()) {
      lst = dir.listSync(recursive: true);
    } else {
      print("** Error: unable to location the directory path.");
      return;
    }
  } else {
    lst = Directory.current.listSync(recursive: true);
  }

  String path = "";
  String fType = "";
  int cnt = lst.length;
  int cntFileTypes = knowFileTypes.length;
  for (var i = 0; i < cnt; i++) {
    if (lst[i] is Directory) continue;
    path = lst[i].path;

    //Delete sourceMap + fix sourceMap not found
    for (var j = 0; j < cntFileTypes; j++) {
      fType = knowFileTypes[j];
      try {
        if (path.endsWith("$fType.map")) {
          try {
            File(path).deleteSync();
            print("Deleted: $path");
          } catch (e) {}
          continue;
        }
        if (path.endsWith(fType)) _fixSourceMapNotFound(path);
      } catch (e) {
        print(e);
        return;
      }
    }

    if (path.endsWith("service-worker.js")) _fixServiceWorker(path, knowFileTypes);
  }
}

void _fixSourceMapNotFound(String path) {
  var f = File(path);
  String content = f.readAsStringSync();
  if (content.contains("# sourceMappingURL=") == false) return;

  for (var i in [
    RegExp(r"\/\/\# sourceMappingURL=[a-zA-Z0-9\.\-\~ ]+\.map"),
    RegExp(r"\/\*\# sourceMappingURL=[a-zA-Z0-9\.\-\~ ]+\.map[ ]+?\*\/")
  ]) {
    content = content.replaceAll(i, "");
  }

  f.writeAsStringSync(content.trim());
  print("Fixed: $path");
}

void _fixServiceWorker(String path, List<String> knowFileTypes) {
  var f = File(path);
  RegExp regex = RegExp(r"\[(.)+?\]", dotAll: true, multiLine: true, unicode: true);
  String content = f.readAsStringSync();
  List<RegExpMatch> matches = regex.allMatches(content).toList();
  var cnt = matches.length;
  if (cnt < 1) return;
  print("Service Worker Found: $path");
  print("Fixing...");

  bool hasRemove = false;
  int cntFileType = knowFileTypes.length;
  for (var i = 0; i < cnt; i++) {
    List<dynamic> js;
    String str = matches[i].group(0) ?? "[]";
    bool isJsonNeedFix = false;
    try {
      str = str.replaceAll(RegExp(r"^([\s\t])*", multiLine: true, unicode: true), "");
      str = str.replaceAllMapped(
          RegExp(
            r"([\{\,])([\s\t]+)?([a-zA-Z0-9]+)?([\s\t]+)?:",
            multiLine: true,
          ), (m) {
        isJsonNeedFix = true;
        return '${m.group(1)}"${m.group(3)}":';
      });
      str = str.replaceAll(RegExp(r"\},(\n|\r\n)?\]"), "}]");
      js = json.decode(str);
      str = "";
    } catch (e) {
      continue;
    }

    List<dynamic> toDeleteList = List.empty(growable: true);
    for (var jse in js) {
      if (jse is String) {
        jse = jse.trim();
        for (var k = 0; k < cntFileType; k++) {
          if (jse != "" && jse.endsWith("${knowFileTypes[k]}.map") == false) continue;

          toDeleteList.add(jse);
        }
      } else if (jse is Map) {
        if (jse.containsKey('url') == false) continue;

        for (var k = 0; k < cntFileType; k++) {
          if (jse["url"]?.endsWith("${knowFileTypes[k]}.map") == false) continue;

          toDeleteList.add(jse);
        }
      }
    }

    if (toDeleteList.isEmpty) continue;
    for (var jse in toDeleteList) {
      js.remove(jse);
    }
    toDeleteList.clear();

    hasRemove = true;
    str = json.encode(js);
    if (isJsonNeedFix) {
      str = str.replaceAllMapped(
          RegExp(
            r'([\{\,])"([a-zA-Z0-9]+)?":',
            multiLine: true,
          ), (m) {
        return '${m.group(1)}${m.group(2)}:';
      });
    }
    content = content.replaceAll(matches[i].group(0) ?? "[{}]", str);
  }

  if (hasRemove) {
    f.writeAsStringSync(content.trim());
    print("Service Worker Fixed: $path");
  }
}
