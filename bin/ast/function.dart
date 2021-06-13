import '../logger.dart';
import '../parser.dart';
import '../scanner.dart';
import 'astBase.dart';

class FunctionAst implements AstBase {

  final String name;
  final List<Argument> arguments;
  final List<AstBase> _children = [];

  final String returnType;

  FunctionAst(this.name, this.arguments, this.returnType, List<Token> children) {
    final parser = Parser(children, Logger("$name Parser"));
    this._children.addAll(parser.parse());
  }

  @override
  List<AstBase> get children => _children;

  @override
  String toString() => "$name(${arguments.isNotEmpty ? "..." : ""}):=$returnType";

}

class FunctionCall extends AstBase {
  final String name;
  final List<FunctionCallArgument> arguments;
  final String? library;

  FunctionCall(this.name, this.arguments, {this.library}): super([]);

  @override
  String toString() => "${"$library."}$name(${arguments.isNotEmpty ? "..." : ""})";
}

class FunctionCallArgument extends AstBase {
  final String value;

  FunctionCallArgument(this.value) : super([]);
}

class Argument extends AstBase {
  final String name;
  final String type;

  Argument(this.name, this.type) : super([]);
}