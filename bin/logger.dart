import 'package:console/console.dart';

import 'scanner.dart';

class Logger {

  final String name;
  final bool verbose;

  Logger(this.name, {this.verbose = false}) {
    Console.init();
  }

  error(String message, {String errorCode = ErrorCode.Unknown}) {
    Console.setTextColor(Color.RED.id, bright: Color.RED.bright, xterm: Color.RED.xterm);
    Console.write("error[$errorCode]");
    Console.setTextColor(Color.WHITE.id, bright: Color.WHITE.bright, xterm: Color.WHITE.xterm);
    Console.write(": ");
    Console.setBold(true);
    Console.write(message);
    Console.setBold(false);
    Console.resetTextColor();
  }

  warning(String message, {String errorCode = ErrorCode.Unknown}) {
    _setColor(Color.RED);
    Console.write("error[$errorCode]");
    _setColor(Color.BLACK);
    Console.write(": ");
    Console.setBold(true);
    Console.write(message);
    Console.write("\n");
    Console.resetAll();
  }

  tokenError(String message, Token token, {String errorCode = ErrorCode.Unknown}) {
    error(message, errorCode: errorCode);
    Console.write("\n");
    if(token.line.raw != null) {
      _setColor(Color.BLUE);
      Console.write("${token.line.id} | ");
      _setColor(Color.BLACK);
      Console.write(token.line.raw!.replaceAll("\n", ""));
      Console.write("\n");
      _setColor(Color.BLUE);
      for(var i = 0; i < token.line.id.toString().length; i++) {
        Console.write(" ");
      }
      Console.write(" | ");
    }
    Console.write("\n");
    Console.resetAll();
  }

  _setColor(Color color) {
    Console.setTextColor(color.id, bright: color.bright, xterm: color.xterm);
  }

}

class ErrorCode {
  static const String Unknown = "E0000";
  static const String FileDoesNotExist = "E0001";
}