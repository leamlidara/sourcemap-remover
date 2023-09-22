import "dart:convert";
import "dart:io";

void main(List<String> arguments) {
  List<String> knowFileTypes = [".js", ".ts", ".css", ".sass"];
  if (arguments.contains("-h") || arguments.contains("--help")) {
    print("SourceMap remover v1.0.3 by LEAM LIDARA");
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
  if (content.contains("sourceMappingURL=") == false) return;

  for (var i in [
    RegExp(r"\/\/\#[ ]+?sourceMappingURL=[a-zA-Z0-9\.\-\~ ]+\.map"),
    RegExp(r"\/\*\#[ ]+?sourceMappingURL=[a-zA-Z0-9\.\-\~ ]+\.map[ ]+?\*\/")
  ]) {
    content = content.replaceAll(i, "");
  }

  f.writeAsStringSync(content.trim());
  print("Fixed: $path");
}

void _fixServiceWorker(String path, List<String> knowFileTypes) {
  var f = File(path);

  RegExp regex = RegExp(r"\{(.)*?\}", dotAll: true, multiLine: true);
  String content = f.readAsStringSync();

  var matches = regex.allMatches(content);
  print("Service Worker Found: $path");

  bool hasRemove = false;
  int cntFileType = knowFileTypes.length;

  for (final match in matches) {
    String str = match.group(0) ?? "{}";

    Map<String, dynamic> js;
    try {
      str = str.replaceAll(RegExp(r"^([\s\t])*", multiLine: true, unicode: true), "");
      str = str.replaceAllMapped(
          RegExp(
            r"([\{\,])([\s\t]+)?([a-zA-Z0-9]+)?([\s\t]+)?:",
            multiLine: true,
          ), (m) {
        return '${m.group(1)}"${m.group(3)}":';
      });
      str = str.replaceAll(RegExp(r"\},(\n|\r\n)?\]"), "}]");
      js = json.decode(str);
      str = "";
    } catch (e) {
      continue;
    }

    for (var k = 0; k < cntFileType; k++) {
      if (js["url"]?.endsWith("${knowFileTypes[k]}.map") == false) continue;

      hasRemove = true;
      content = content.replaceAll(match.group(0) ?? "", "");
    }
  }

  if (hasRemove) {
    f.writeAsStringSync(content.trim());
    print("Service Worker Map DataType Fixed");
  }

  hasRemove = false;
  try {
    regex = RegExp(r"\[(.)*?\]", dotAll: true, multiLine: true);
    matches = regex.allMatches(content);
    for (final match in matches) {
      String str = match.group(0) ?? "";
      if (str == "") continue;

      for (var k = 0; k < cntFileType; k++) {
        if (str.endsWith("${knowFileTypes[k]}.map") == false) continue;

        hasRemove = true;
        content = content.replaceAll(str, "");
      }
    }
  } catch (e) {
    print("Unable to fix Service Worker List DataType due to StackOverflow on Dart SDK!");
    return;
  }

  if (hasRemove) {
    f.writeAsStringSync(content.trim());
    print("Service Worker List DataType Fixed");
  }
}
