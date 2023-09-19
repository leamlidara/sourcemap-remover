import "dart:io";

void main(List<String> arguments) {
  if (arguments.contains("-h") || arguments.contains("--help")) {
    print("sourcemap-remover [option [directory path]]");
    print("options: -h,  --help : display this help");
    print("If directory path did not specific, application will get current directory");
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
  int cnt = lst.length;
  for (var i = 0; i < cnt; i++) {
    if (lst[i] is Directory) continue;
    _checkAndRemoveMap(lst[i].path);
    _fixMapNotFound(lst[i].path);
  }
}

void _checkAndRemoveMap(String path) {
  if (!path.endsWith(".map")) return;
  List<String> names = path.split('\\');
  var nFile = File(path.substring(0, path.length - 4));
  if (nFile.existsSync()) {
    var content = nFile.readAsStringSync();
    content = content.replaceAll("//# sourceMappingURL=${names[names.length - 1]}", "");
    nFile.writeAsString(content.trim());
  }
  File(path).delete();
}

void _fixMapNotFound(String path) {
  if (!path.endsWith(".js") && !path.endsWith(".css")) return;

  var f = File(path);
  var content = f.readAsStringSync();
  if (content.contains("//# sourceMappingURL=")) {
    content = content.replaceAll(RegExp(r"\/\/\# sourceMappingURL=[a-zA-Z0-9\.\-\~ ]+\.map"), "");
    f.writeAsString(content.trim());
  }
}
