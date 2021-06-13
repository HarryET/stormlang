import "ast/astBase.dart";
import "ast/dotStatement.dart";
import "ast/function.dart";
import "ast/variable.dart";
import 'logger.dart';
import "scanner.dart";

class SyntaxError extends Error {
  @override
  String toString() => "Invalid Syntax.";
}

class Parser {

  final List<AstBase> _statements = [];

  final List<Token> _tokens;
  final Logger _logger;

  int _current = 0;
  
  Parser(this._tokens, this._logger);

  List<AstBase> parse() {
    while(!_isAtEnd) {
      _parseToken();
    }

    return this._statements;
  }

  void _parseToken() {
    final token = _advance;
    if(token.type == tokenType.NAMESPACE) {
      _dotStatement(dotStatementType.namespace);
      return;
    }
    if(token.type == tokenType.IMPORT) {
      _dotStatement(dotStatementType.import);
      return;
    }
    if(token.type == tokenType.CONST || token.type == tokenType.MUT) {
      if(_peak.type != tokenType.IDENTIFIER) {
        // TODO fix logging
        //this._logger.warning("Missing variable name on line ${token.line}");
        throw SyntaxError();
      }
      final name = _advance;
      if(_peak.type != tokenType.EQUAL) {
        // TODO fix logging
        //this._logger.warning("Missing variable declaration on line ${token.line}");
        throw SyntaxError();
      }
      _current++;
      if(!_isValue()) {
        // TODO fix logging
        //this._logger.warning("Invalid variable declaration on line ${token.line}");
        throw SyntaxError();
      }
      final value = _advance;

      if(_peak.type != tokenType.SEMICOLON) {
        // TODO fix logging
        //this._logger.warning("Missing semicolon on line ${token.line}");
        throw SyntaxError();
      }

      _current++;

      this._statements.add(Variable(
          name.rawData,
          value.type == tokenType.STRING
              ? "string"
              : value.type == tokenType.NUMBER
                ? "number"
                : "dynamic",
          value.rawData, constant: token.type == tokenType.CONST));

      return;
    }
    if(token.type == tokenType.IDENTIFIER) {
      if(_peak.type == tokenType.DOT) {
        // method from lib
        _current++; // skip dot

        final name = _advance;
        if(name.type != tokenType.IDENTIFIER) {
          // TODO fix logging
          //this._logger.warning("Method call error");
          throw SyntaxError();
        }

        if(_peak.type != tokenType.LEFT_PAREN) {
          // TODO fix logging
          //this._logger.warning("Method call error");
          throw SyntaxError();
        }
        _current++;

        if(_isValidFunctionParamValue()) {
          final args = <FunctionCallArgument>[];
          while(_isValidFunctionParamValue()) {
            final arg = _advance;
            args.add(FunctionCallArgument(arg.rawData));
            if(_peak.type == tokenType.RIGHT_PAREN) {
              _current++;
              break;
            }
          }
          if(_peak.type != tokenType.SEMICOLON) {// TODO fix logging
            //this._logger.warning("Method call error, missing semicolon");
            throw SyntaxError();
          }
          this._statements.add(FunctionCall(name.rawData, args, library: token.rawData));
          return;
        }
      }
      if(_peak.type == tokenType.LEFT_PAREN) {
        _current++; // Skip LPAREN
        // if(_isValidFunctionParamValue()) {
        //   final args = <FunctionCallArgument>[];
        //   while(_isValidFunctionParamValue()) {
        //     final arg = _advance;
        //     args.add(FunctionCallArgument(arg.rawData));
        //   }
        //   this._statements.add(FunctionCall(token.rawData, args));
        // }

        if(_peak.type == tokenType.IDENTIFIER || _peak.type == tokenType.RIGHT_PAREN) {
          final arguments = <Argument>[];
          var hasArgs = true;

          if(_peakNext.type == tokenType.RIGHT_PAREN) {
            hasArgs = false;
            _current++;
          }

          while(hasArgs && _peak.type != tokenType.RIGHT_PAREN) {
            final name = _advance;

            if(_peak.type != tokenType.TYPE) {
              // TODO fix logging
              //this._logger.warning("Arguments must have a type");
              throw SyntaxError();
            }
            _current++;

            if(_peak.type != tokenType.IDENTIFIER) {
              // TODO fix logging
              //this._logger.warning("Arguments must have a type");
              throw SyntaxError();
            }

            final type = _advance;
            var typeString = type.rawData;
            if(typeString == "list") {
              if(_peak.type != tokenType.LESS) {
                // TODO fix logging
                //this._logger.warning("Lists must have a valid data type");
                throw SyntaxError();
              }
              _current++;
              if(_peak.type != tokenType.IDENTIFIER) {
                // TODO fix logging
                //this._logger.warning("Lists must have a valid data type");
                throw SyntaxError();
              }
              final listType = _advance;
              if(_peak.type != tokenType.GREATER) {
                // TODO fix logging
                //this._logger.warning("Lists must have a valid data type");
                throw SyntaxError();
              }
              _current++;
              typeString += "<${listType.rawData}>";
            }

            arguments.add(Argument(name.rawData, typeString));

            if(_peak.type == tokenType.COMMA) {
              _advance;
            }
          }

          if(_peak.type != tokenType.RIGHT_PAREN) {
            // TODO fix logging
            //this._logger.warning("Function definition missing a closing paren");
            throw SyntaxError();
          }
          _current++;

          String returnType;
          if(_peak.type != tokenType.RETURNING) {
            returnType = "void";
          } else {
            _current++;
            final type = _advance;
            returnType = type.rawData;
          }

          if(_peak.type != tokenType.LEFT_BRACE) {
            // TODO fix logging
            //this._logger.warning("Function (${token.rawData}) dose not have a valid body.");
            throw SyntaxError();
          }

          _current++;

          var shouldReadChildren = true;

          var openBraces = 0;
          var closedBraces = 0;

          final children = <Token>[];

          while(shouldReadChildren) {
            if(_peak.type == tokenType.LEFT_BRACE) {
              openBraces++;
            }
            if(_peak.type == tokenType.RIGHT_BRACE) {
              closedBraces++;
            }

            children.add(_advance);

            if(openBraces == closedBraces && _peak.type == tokenType.RIGHT_BRACE) {
              shouldReadChildren = false;
            }
          }

          this._statements.add(FunctionAst(token.rawData, arguments, returnType, children));
          return;
        }
      }
    }

  }

  bool _isValue() => _peak.type == tokenType.STRING || _peak.type == tokenType.NUMBER;

  bool _isValidFunctionParamValue() {
    if(_isValue()) {
      return true;
    }
    final p1 = _peak;
    final p2 = _peakNext;
    if(_peak.type == tokenType.IDENTIFIER && _peakNext != tokenType.TYPE) {
      return true;
    }
    return false;
  }

  bool get _isAtEnd => this._current >= this._tokens.length;

  Token get _advance => this._tokens[this._current++];

  Token get _peak => this._tokens[this._current];

  Token get _peakNext => this._tokens[this._current + 1];

  Token get _currentToken => this._tokens[this._current];

  void _dotStatement(dotStatementType type) {
    final str = type == dotStatementType.import ? "Imports" : "Namespace";
    if(_peak.type != tokenType.IDENTIFIER) {
      // TODO fix logging
      //this._logger.warning("$str is invalid must include a valid author");
      throw SyntaxError();
    }
    final author = _advance;

    if(_peak.type != tokenType.DOT) {
      // TODO fix logging
      //this._logger.warning("$str is invalid must include a valid author and package name separated by a dot.");
      throw SyntaxError();
    }
    _current++;

    if(_peak.type != tokenType.IDENTIFIER) {
      // TODO fix logging
      //this._logger.warning("$str is invalid must include a valid package name");
      throw SyntaxError();
    }
    final package = _advance;

    if(_peak.type != tokenType.SEMICOLON) {
      // TODO fix logging
      //this._logger.warning("All statements require a semicolon at the end.");
      throw SyntaxError();
    }
    _advance;

    this._statements.add(DotStatement(type, author, package));
    return;
  }

}