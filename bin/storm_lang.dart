import 'dart:io';

import 'package:args/args.dart';
import 'logger.dart';

import 'ast/function.dart';
import 'parser.dart';
import 'scanner.dart';

void main(List<String> args) async {
  final arguments = getParser().parse(args); // Parse args
  final logger = Logger("Storm"); // Initialise logger

  final file = File(arguments["file"] as String); // The file containing the programs code

  if(!file.existsSync()) {
    logger.error("`${arguments["file"]}` dose not exist", errorCode: ErrorCode.FileDoesNotExist);
    return;
  }

  final fileContents = await file.readAsString();
  //logger.fine("File contents extracted");

  final scanner = Scanner(fileContents, logger);
  final tokens = scanner.tokens();

  final parser = Parser(tokens, logger);
  final ast = parser.parse();

  for(final i in ast) {
    print(i.toString());
    if(i.children.isNotEmpty) {
      for (final child in i.children) {
        print(" $child");
      }}
  }

}

ArgParser getParser() {
  final parser = ArgParser();
  // Flags
  parser.addFlag("verbose", abbr: "v", defaultsTo: false);

  //Options
  parser.addOption("file", abbr: "f", defaultsTo: "./main.storm");

  return parser;
}