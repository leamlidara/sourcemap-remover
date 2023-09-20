import "dart:io";

void main(List<String> arguments) {
  if (arguments.contains("-h") || arguments.contains("--help")) {
    print("sourcemap-remover [option [directory path]]");
    print("options: -h,  --help : display this help");
    print("If directory path did not specific, application will get current directory.");
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

  List<String> fileTypes = [".js", ".css"];
  String path = "";
  String fType = "";
  int cnt = lst.length;
  int cntFileTypes = fileTypes.length;
  for (var i = 0; i < cnt; i++) {
    if (lst[i] is Directory) continue;
    path = lst[i].path;

    //Delete sourceMap + fix sourceMap not found
    for (var j = 0; j < cntFileTypes; j++) {
      fType = fileTypes[j];

      if (!path.endsWith("$fType.map")) File(path).delete();
      if (path.endsWith(fType)) _fixSourceMapNotFound(path);
    }
  }
}

void _fixSourceMapNotFound(String path) {
  var f = File(path);
  var content = f.readAsStringSync();
  if (content.contains("# sourceMappingURL=") == false) return;

  for (var i in [
    RegExp(r"\/\/\# sourceMappingURL=[a-zA-Z0-9\.\-\~ ]+\.map"),
    RegExp(r"\/\*\# sourceMappingURL=[a-zA-Z0-9\.\-\~ ]+\.map[ ]+?\*\/")
  ]) {
    content = content.replaceAll(i, "");
  }

  f.writeAsString(content.trim());
}
