import 'astBase.dart';

class Variable extends AstBase {

  final String name;
  final String type;
  final String value;

  final bool constant;

  Variable(this.name, this.type, this.value, {this.constant = true}) : super([]);

  @override
  String toString() => "$name($type)=${value.length >= 15 ? "..." : value}";

}