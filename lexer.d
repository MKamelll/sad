import std.variant;
import std.typecons;
import std.format;
import std.stdio;
import std.ascii;
import std.conv;

enum TokenType {
    Left_Paren = "(", Right_Paren = ")", Left_Bracket = "{", Right_Bracket = "}",
    Left_Square = "[", Right_Square = "]", SemiColon = ";", Plus = "+", Minus = "-", 
    
    Star = "*", Slash = "/", Int = "Int", Float = "Float", Mod = "%", Carrot = "^", 
    Identifier = "Identifier", Comma = ",", Let = "let", Const = "const", Eq = "=", Eq_Eq = "==", Bang = "!",
    Bang_Eq = "!=", Greater_Eq = ">=", Less_Eq = "<=", Less = "<", Greater = ">",
    Fn = "fn", Struct = "struct" , Return = "return", For = "for", While = "while", If = "if", Elif = "elif", Else = "else",
    Range = "..", String = "String", Colon = ":", Eof = "Eof"
}

class Token {
    TokenType type;
    Variant lexeme;

    this(TokenType type, Variant lexeme) {
        this.type = type;
        this.lexeme = lexeme;
    }

    override string toString() const {
        if (lexeme.peek!(int) !is null) {
            return format("Token(type: %s, lexeme: %s)", to!string(type), lexeme.get!(int));
        } else if (lexeme.peek!(float) !is null) {
            return format("Token(type: %s, lexeme: %s)", to!string(type), lexeme.get!(float));
        }
        
        return format("Token(type: %s, lexeme: '%s')", to!string(type), lexeme.get!(string));
    }
}

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
                    return new Token(TokenType.Eq_Eq, Variant("=="));
                } else {
                    advance(1);
                    return new Token(TokenType.Eq, Variant("="));
                }
                break;
            }

            case '>': {
                if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.Greater_Eq, Variant(">="));
                } else {
                    advance(1);
                    return new Token(TokenType.Greater, Variant(">"));
                }
                break;
            }

            case '<': {
                if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.Less_Eq, Variant("<="));
                } else {
                    advance(1);
                    return new Token(TokenType.Less, Variant("<"));
                }
                break;
            }

            case '!': {
                if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.Bang_Eq, Variant("!="));
                } else {
                    advance(1);
                    return new Token(TokenType.Bang, Variant("!"));
                }
                break;
            }

            case '(': {
                advance(1);
                return new Token(TokenType.Left_Paren, Variant("("));
            }

            case ')': {
                advance(1);
                return new Token(TokenType.Right_Paren, Variant(")")); 
            }
                
            case '+': {
                advance(1);
                return new Token(TokenType.Plus, Variant("+"));
            }

            case '-': {
                advance(1);
                return new Token(TokenType.Minus, Variant("-"));
            }

            case '*': {
                advance(1);
                return new Token(TokenType.Star, Variant("*"));
            }

            case '/': {
                advance(1);
                return new Token(TokenType.Slash, Variant("/"));
            }

            case ',': {
                advance(1);
                return new Token(TokenType.Comma, Variant(","));
            }

            case '"': {
                string s = str();
                return new Token(TokenType.String, Variant(s));
            }

            case '%': {
                advance(1);
                return new Token(TokenType.Mod, Variant("%"));
            }

            case '^': {
                advance(1);
                return new Token(TokenType.Carrot, Variant("^"));
            }

            case ';': {
                advance(1);
                return new Token(TokenType.SemiColon, Variant(";"));
            }

            case '{': {
                advance(1);
                return new Token(TokenType.Left_Bracket, Variant("{"));
            }

            case '}': {
                advance(1);
                return new Token(TokenType.Right_Bracket, Variant("}"));
            }

            case '[': {
                advance(1);
                return new Token(TokenType.Left_Square, Variant("["));
            }

            case ']': {
                advance(1);
                return new Token(TokenType.Right_Square, Variant("]"));
            }

            case ':' : {
                advance(1);
                // allow spaces after : and before type
                while (isWhite(source[current])) advance(1);
                string ident = identifier();
                return new Token(TokenType.Colon, Variant(ident));
            }
      
            case ' ': case '\t': advance(1); return next();

            default: {
                if (isDigit(curr)) {
                    auto num = number();
                        
                    if (num.type == typeid(float)) {
                        return new Token(TokenType.Float, Variant(num));
                    } else if (num.type == typeid(int)) {
                        return new Token(TokenType.Int, Variant(num));
                    }
                } else if (isAlpha(curr)) {
                    string ident = identifier();

                    if (ident == "let") {
                        return new Token(TokenType.Let, Variant(ident));
                    } else if (ident == "const") {
                        return new Token(TokenType.Const, Variant(ident));
                    } else if (ident == "if") {
                        return new Token(TokenType.If, Variant(ident));
                    } else if (ident == "elif") {
                        return new Token(TokenType.Elif, Variant(ident));
                    } else if (ident == "else") {
                        return new Token(TokenType.Else, Variant(ident));
                    } else if (ident == "while") {
                        return new Token(TokenType.While, Variant(ident));
                    } else if (ident == "for") {
                        return new Token(TokenType.For, Variant(ident));
                    } else if (ident == "return") {
                        return new Token(TokenType.Return, Variant(ident));
                    } else if (ident == "fn") {
                        return new Token(TokenType.Fn, Variant(ident));
                    } else if (ident == "struct") {
                        return new Token(TokenType.Struct, Variant(ident));
                    }

                    return new Token(TokenType.Identifier, Variant(ident));
                }
            }
            }

        }

        return new Token(TokenType.Eof, Variant("EOF"));
    }

    Variant number() {
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

        return isFloat ? Variant(parse!float(result)) : Variant(parse!int(result));

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
