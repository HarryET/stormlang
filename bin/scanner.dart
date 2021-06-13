import 'logger.dart';

class ScannerError extends Error {
  @override
  String toString() => "Unknown exception with scanner";
}

class Scanner {
  final String _source;
  final Logger _logger;

  final Map<String, tokenType> _keywords = {};
  final List<Token> _tokens = [];
  final Map<int, LineData> lineMeta = {};

  int _start = 0;
  int _current = 0;
  int _line = 1;

  Scanner(this._source, this._logger) {
    this._keywords.addAll({
      "class": tokenType.CLASS,
      "else": tokenType.ELSE,
      "false": tokenType.FALSE,
      "for": tokenType.FOR,
      "if": tokenType.IF,
      "null": tokenType.NULL,
      "return": tokenType.RETURN,
      "super": tokenType.SUPER,
      "this": tokenType.THIS,
      "true": tokenType.TRUE,
      "while": tokenType.WHILE,
      "namespace": tokenType.NAMESPACE,
      "import": tokenType.IMPORT,
      "returning": tokenType.RETURNING,
      "const": tokenType.CONST,
      "mut": tokenType.MUT,
    });
  }

  List<Token> tokens() {
    this.lineMeta[this._line] = LineData(this._line, this._current);
    while (!this._isAtEnd) {
      this._start = this._current;
      _scanToken();
    }

    this._tokens.add(Token(
        tokenType.EOF,
        "",
        null,
        this._currentLine ?? LineData(this._line, this._current),
        this._start,
        this._current));
    return this._tokens;
  }

  void _scanToken() {
    final char = _advance;
    switch (char) {
      case "(":
        _addToken(tokenType.LEFT_PAREN);
        break;
      case ")":
        _addToken(tokenType.RIGHT_PAREN);
        break;
      case "{":
        _addToken(tokenType.LEFT_BRACE);
        break;
      case "}":
        _addToken(tokenType.RIGHT_BRACE);
        break;
      case ",":
        _addToken(tokenType.COMMA);
        break;
      case ".":
        _addToken(tokenType.DOT);
        break;
      case "-":
        _addToken(tokenType.MINUS);
        break;
      case "+":
        _addToken(tokenType.PLUS);
        break;
      case ";":
        _addToken(tokenType.SEMICOLON);
        break;
      case "*":
        _addToken(tokenType.STAR);
        break;
      case "!":
        _addToken(_match("=") ? tokenType.BANG_EQUAL : tokenType.BANG);
        break;
      case "=":
        _addToken(_match("=") ? tokenType.EQUAL_EQUAL : tokenType.EQUAL);
        break;
      case "<":
        _addToken(_match("=") ? tokenType.LESS_EQUAL : tokenType.LESS);
        break;
      case ">":
        _addToken(_match("=") ? tokenType.GREATER_EQUAL : tokenType.GREATER);
        break;
      case "/":
        if (_match("/")) {
          // A comment goes until the end of the line.
          while (_peek != "\n" && !this._isAtEnd) {
            this._advance;
          }
        } else {
          _addToken(tokenType.SLASH);
        }
        break;
      case ":":
        if (_match("=")) {
          _addToken(tokenType.TYPE);
        }
        break;
      case " ":
      case "\r":
      case "\t":
        break;
      case "\n":
        _currentLine?.setEndPos(this._current);
        _currentLine
            ?.setRawData(this._source.substring(this._start, this._current));
        this._line++;
        this.lineMeta[this._line] = LineData(this._line, this._current);
        break;
      case "\"":
        _string();
        break;
      default:
        if (_isDigit(char)) {
          _number();
        } else if (_isAlpha(char)) {
          _identifier();
        } else {
          this._logger.error(
              "Unexpected character `${char}` at line: ${this._line}, pos: ${this._current - (this._currentLine?.startPos ?? this._current)}");
          throw ScannerError();
        }
        break;
    }
  }

  void _addToken(tokenType type, {dynamic value}) => this._tokens.add(Token(
      type,
      this._source.substring(this._start, this._current),
      value,
      this._currentLine ?? LineData(this._line, this._start),
      this._start,
      this._current));

  void _identifier() {
    while (_isAlphaNumeric(this._peek)) {
      this._advance;
    }
    final text = this._source.substring(this._start, this._current);
    _addToken(this._keywords[text] ?? tokenType.IDENTIFIER);
  }

  void _string() {
    while (this._peek != "\"" && !this._isAtEnd) {
      if (this._peek == "\n") this._line++;
      this._advance;
    }

    if (this._isAtEnd) {
      final eString = this._source.substring(this._start + 1, this._current);
      final e = Token(
          tokenType.STRING,
          eString,
          eString,
          this._currentLine ?? LineData(this._line, this._start)
            ..setEndPos(this._current)
            ..setRawData(eString),
          this._start,
          this._current);
      this._logger.tokenError(
          "Unterminated string at line: ${this._line}, pos: ${this._current - (this._currentLine?.startPos ?? this._current)}",
          e);
      throw ScannerError();
    }

    // The closing ".
    this._advance;

    // Trim the surrounding quotes.
    String value = this._source.substring(this._start + 1, this._current - 1);
    _addToken(tokenType.STRING, value: value);
  }

  void _number() {
    while (_isDigit(this._peek)) this._advance;

    if (this._peek == "." && _isDigit(this._peekNext)) {
      this._advance;

      while (_isDigit(this._peek)) this._advance;
    }

    _addToken(tokenType.NUMBER,
        value:
            int.tryParse(this._source.substring(this._start, this._current)));
  }

  String get _peek {
    if (this._isAtEnd) return "\0";
    return this._source[this._current];
  }

  String get _peekNext {
    if (this._current + 1 >= this._source.length) return "\0";
    return this._source[this._current + 1];
  }

  bool _match(String expected) {
    if (_isAtEnd) return false;
    if (this._source[this._current] != expected) return false;

    this._current++;
    return true;
  }

  bool _isDigit(String char) => int.tryParse(char) != null;

  bool _isAlpha(String char) => RegExp("[a-zA-Z_]").hasMatch(char);

  bool _isAlphaNumeric(String char) => _isDigit(char) || _isAlpha(char);

  String get _advance => this._source[this._current++];

  bool get _isAtEnd => this._current >= this._source.length;

  LineData? get _currentLine => this.lineMeta[this._line];
}

enum tokenType {
  // Single-character tokens.
  LEFT_PAREN,
  RIGHT_PAREN,
  LEFT_BRACE,
  RIGHT_BRACE,
  COMMA,
  DOT,
  MINUS,
  PLUS,
  SEMICOLON,
  SLASH,
  STAR,

  // One or two character tokens.
  BANG,
  BANG_EQUAL,
  EQUAL,
  EQUAL_EQUAL,
  GREATER,
  GREATER_EQUAL,
  LESS,
  LESS_EQUAL,
  TYPE,

  // Literals.
  IDENTIFIER,
  STRING,
  NUMBER,

  // Keywords.
  CLASS,
  ELSE,
  FALSE,
  FOR,
  IF,
  NULL,
  OR,
  RETURN,
  SUPER,
  THIS,
  TRUE,
  WHILE,
  NAMESPACE,
  IMPORT,
  RETURNING,
  CONST,
  MUT,
  EOF
}

class Token {
  final tokenType type;
  final String _raw;
  final dynamic literal;
  final LineData line;
  final int start;
  final int end;

  Token(this.type, this._raw, this.literal, this.line, this.start, this.end);

  @override
  String toString() => "$type:$_raw:${line.id}[$start-$end]";

  String get rawData => this._raw;
}

class LineData {
  final int id;
  final int startPos;

  late final int? endPos;
  late final String? raw;

  LineData(this.id, this.startPos);

  void setEndPos(int pos) => this.endPos = pos;

  void setRawData(String data) => this.raw = data;
}
