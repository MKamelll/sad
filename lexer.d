import std.variant;
import std.typecons;
import std.format;
import std.stdio;
import std.ascii;
import std.conv;

enum TokenType {
    Left_paren, Right_paren, Plus, Minus, Star, Slash, Int, Float, Mod, Carrot,
    Identifier, Comma, Let, Const, Eq, Eq_Eq, Bang, Bang_Eq, Greater_Eq, Less_Eq, Less, Greater,
    Fn, End, Return, For, While, If, Elif, Else, Range, String, SemiColon, Eof
}

alias Lexeme = Algebraic!(int, float, string);

alias Number = Algebraic!(int, float);

class Token {
    TokenType type;
    Lexeme lexeme;

    this(TokenType type, Lexeme lexeme) {
        this.type = type;
        this.lexeme = lexeme;
    }

    override string toString() {
        if (lexeme.type == typeid(int) || lexeme.type == typeid(float))
            return format("Token(type: %s, lexeme: %s)", to!string(type), to!string(lexeme));
        
        return format("Token(type: %s, lexeme: '%s')", to!string(type), to!string(lexeme));
    }
};

class Tokenizer {
    string source;
    int current;

    this(string source) {
        this.source = source;
        this.current = 0;
    }

    Nullable!char peek() {
        if (current + 1 < source.length) {
            return Nullable!char(source[current+1]);
        }

        return Nullable!char.init;
    }

    void advance(int num) {
        current += num;
    }

    auto next() {
        if (current < source.length) {
            char curr = source[current];           
            switch (curr) {
            case '=': {
                if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.Eq_Eq, Lexeme("=="));
                } else {
                    advance(1);
                    return new Token(TokenType.Eq, Lexeme("="));
                }
                break;
            }

            case '>': {
                if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.Greater_Eq, Lexeme(">="));
                } else {
                    advance(1);
                    return new Token(TokenType.Greater, Lexeme(">"));
                }
                break;
            }

            case '<': {
                if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.Less_Eq, Lexeme("<="));
                } else {
                    advance(1);
                    return new Token(TokenType.Less, Lexeme("<"));
                }
                break;
            }

            case '!': {
                if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.Bang_Eq, Lexeme("!="));
                } else {
                    advance(1);
                    return new Token(TokenType.Bang, Lexeme("!"));
                }
                break;
            }

            case '(': {
                advance(1);
                return new Token(TokenType.Left_paren, Lexeme("("));
            }

            case ')': {
                advance(1);
                return new Token(TokenType.Right_paren, Lexeme(")")); 
            }
                
            case '+': {
                advance(1);
                return new Token(TokenType.Plus, Lexeme("+"));
            }

            case '-': {
                advance(1);
                return new Token(TokenType.Minus, Lexeme("-"));
            }

            case '*': {
                advance(1);
                return new Token(TokenType.Star, Lexeme("*"));
            }

            case '/': {
                advance(1);
                return new Token(TokenType.Slash, Lexeme("/"));
            }

            case ',': {
                advance(1);
                return new Token(TokenType.Comma, Lexeme(","));
            }

            case '"': {
                string s = str();
                return new Token(TokenType.String, Lexeme(s));
            }

            case '%': {
                advance(1);
                return new Token(TokenType.Mod, Lexeme("%"));
            }

            case '^': {
                advance(1);
                return new Token(TokenType.Carrot, Lexeme("^"));
            }

            case ';': {
                advance(1);
                return new Token(TokenType.SemiColon, Lexeme(";"));
            }
      
            case ' ': case '\t': advance(1); return next();

            default: {
                if (isDigit(curr)) {
                    Number num = number();
                        
                    if (num.type == typeid(float)) {
                        return new Token(TokenType.Float, Lexeme(num));
                    } else if (num.type == typeid(int)) {
                        return new Token(TokenType.Int, Lexeme(num));
                    }
                } else if (isAlpha(curr)) {
                    string ident = identifier();

                    if (ident == "let") {
                        return new Token(TokenType.Let, Lexeme(ident));
                    } else if (ident == "const") {
                        return new Token(TokenType.Const, Lexeme(ident));
                    } else if (ident == "fn") {
                        return new Token(TokenType.Fn, Lexeme(ident));
                    } else if (ident == "if") {
                        return new Token(TokenType.If, Lexeme(ident));
                    } else if (ident == "elif") {
                        return new Token(TokenType.Elif, Lexeme(ident));
                    } else if (ident == "else") {
                        return new Token(TokenType.Else, Lexeme(ident));
                    } else if (ident == "while") {
                        return new Token(TokenType.While, Lexeme(ident));
                    } else if (ident == "for") {
                        return new Token(TokenType.For, Lexeme(ident));
                    } else if (ident == "return") {
                        return new Token(TokenType.Return, Lexeme(ident));
                    }

                    return new Token(TokenType.Identifier, Lexeme(ident));
                }
            }
            }

        }

        return new Token(TokenType.Eof, Lexeme("EOF"));
    }

    Number number() {
        bool isFloat = false;
        string result;

        while (current < source.length) {
            char curr = source[current];
            if (!isDigit(curr)) break;

            result ~= curr;

            if (!peek().isNull && peek() == '.' ) {
                isFloat = true;
                result ~= '.';
                advance(1);
            }

            advance(1);
        }

        return isFloat ? Number(parse!float(result)) : Number(parse!int(result));

    }

    string identifier() {
        string result;

        while (current < source.length) {
            char curr = source[current];
            if (!isAlpha(curr)) break;

            result ~= curr;
            advance(1);
        }

        return result;
    }

    string str() {
        string result;
        
        advance(1);
        while (current < source.length) {
            char curr = source[current];
            if (curr == '"') break;

            result ~= curr;
            advance(1);
        }

        advance(1);
        return result;
    }

    void debug_print() {
        Token token = next();
        while (token.type != TokenType.Eof) {
            writeln(token);    
            token = next();
        }
        
        writeln(token);
    }

}
