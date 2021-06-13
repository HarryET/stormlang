import '../scanner.dart';
import 'astBase.dart';

enum dotStatementType {
  import, namespace
}

class DotStatement extends AstBase {
   late final String authorName;
   late final String packageName;

   final dotStatementType type;

   DotStatement(this.type, Token author, Token package): super([]) {
    this.authorName = author.rawData;
    this.packageName = package.rawData;
  }

  @override
  String toString() => "${type == dotStatementType.import ? "import" : "namespace"}[$authorName,$packageName]";
}