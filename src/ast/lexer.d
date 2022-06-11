import std.variant;
import std.typecons;
import std.format;
import std.stdio;
import std.ascii;
import std.conv;

enum TokenType {
    LEFT_PAREN = "(", RIGHT_PAREN = ")", LEFT_BRACKET = "{", RIGHT_BRACKET = "}",
    LEFT_SQUARE = "[", RIGHT_SQUARE = "]", SEMICOLON = ";", PLUS = "+", PLUS_PLUS = "++", PLUS_EQ = "+=", MINUS = "-", 
    
    STAR = "*", SLASH = "/", INT = "INT", FLOAT = "FLOAT", MOD = "%", CARROT = "^", 
    IDENTIFIER = "IDENTIFIER", COMMA = ",", LET = "LET", CONST = "CONST", EQ = "=", EQ_EQ = "==", BANG = "!",
    BANG_EQ = "!=", GREATER_EQ = ">=", LESS_EQ = "<=", LESS = "<", GREATER = ">",
    FN = "FN", STRUCT = "STRUCT" , RETURN = "RETURN", FOR = "FOR", WHILE = "WHILE", IF = "IF", ELIF = "ELIF", ELSE = "ELSE",
    RANGE = "..", STRING = "STRING", COLON = ":", EOF = "EOF"
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
                    return new Token(TokenType.EQ_EQ, Variant("=="));
                } else {
                    advance(1);
                    return new Token(TokenType.EQ, Variant("="));
                }
                break;
            }

            case '>': {
                if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.GREATER_EQ, Variant(">="));
                } else {
                    advance(1);
                    return new Token(TokenType.GREATER, Variant(">"));
                }
                break;
            }

            case '<': {
                if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.LESS_EQ, Variant("<="));
                } else {
                    advance(1);
                    return new Token(TokenType.LESS, Variant("<"));
                }
                break;
            }

            case '!': {
                if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.BANG_EQ, Variant("!="));
                } else {
                    advance(1);
                    return new Token(TokenType.BANG, Variant("!"));
                }
                break;
            }

            case '(': {
                advance(1);
                return new Token(TokenType.LEFT_PAREN, Variant("("));
            }

            case ')': {
                advance(1);
                return new Token(TokenType.RIGHT_PAREN, Variant(")")); 
            }
                
            case '+': {
                if (!peek().isNull && peek() == '+') {
                    advance(2);
                    return new Token(TokenType.PLUS_PLUS, Variant("++"));
                } else if (!peek().isNull && peek() == '=') {
                    advance(2);
                    return new Token(TokenType.PLUS_EQ, Variant("+="));
                } else {
                    advance(1);
                    return new Token(TokenType.PLUS, Variant("+"));

                }
            }

            case '-': {
                advance(1);
                return new Token(TokenType.MINUS, Variant("-"));
            }

            case '*': {
                advance(1);
                return new Token(TokenType.STAR, Variant("*"));
            }

            case '/': {
                advance(1);
                return new Token(TokenType.SLASH, Variant("/"));
            }

            case ',': {
                advance(1);
                return new Token(TokenType.COMMA, Variant(","));
            }

            case '"': {
                string s = str();
                return new Token(TokenType.STRING, Variant(s));
            }

            case '%': {
                advance(1);
                return new Token(TokenType.MOD, Variant("%"));
            }

            case '^': {
                advance(1);
                return new Token(TokenType.CARROT, Variant("^"));
            }

            case ';': {
                advance(1);
                return new Token(TokenType.SEMICOLON, Variant(";"));
            }

            case '{': {
                advance(1);
                return new Token(TokenType.LEFT_BRACKET, Variant("{"));
            }

            case '}': {
                advance(1);
                return new Token(TokenType.RIGHT_BRACKET, Variant("}"));
            }

            case '[': {
                advance(1);
                return new Token(TokenType.LEFT_SQUARE, Variant("["));
            }

            case ']': {
                advance(1);
                return new Token(TokenType.RIGHT_SQUARE, Variant("]"));
            }

            case ':' : {
                advance(1);
                // allow spaces after : and before type
                while (isWhite(source[current])) advance(1);
                string ident = identifier();
                return new Token(TokenType.COLON, Variant(ident));
            }
      
            case ' ': case '\t': advance(1); return next();

            default: {
                if (isDigit(curr)) {
                    auto num = number();
                        
                    if (num.type == typeid(float)) {
                        return new Token(TokenType.FLOAT, Variant(num));
                    } else if (num.type == typeid(int)) {
                        return new Token(TokenType.INT, Variant(num));
                    }
                } else if (isAlpha(curr)) {
                    string ident = identifier();

                    if (ident == "let") {
                        return new Token(TokenType.LET, Variant(ident));
                    } else if (ident == "const") {
                        return new Token(TokenType.CONST, Variant(ident));
                    } else if (ident == "if") {
                        return new Token(TokenType.IF, Variant(ident));
                    } else if (ident == "elif") {
                        return new Token(TokenType.ELIF, Variant(ident));
                    } else if (ident == "else") {
                        return new Token(TokenType.ELSE, Variant(ident));
                    } else if (ident == "while") {
                        return new Token(TokenType.WHILE, Variant(ident));
                    } else if (ident == "for") {
                        return new Token(TokenType.FOR, Variant(ident));
                    } else if (ident == "return") {
                        return new Token(TokenType.RETURN, Variant(ident));
                    } else if (ident == "fn") {
                        return new Token(TokenType.FN, Variant(ident));
                    } else if (ident == "struct") {
                        return new Token(TokenType.STRUCT, Variant(ident));
                    }

                    return new Token(TokenType.IDENTIFIER, Variant(ident));
                }
            }
            }

        }

        return new Token(TokenType.EOF, Variant("EOF"));
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
        while (token.type != TokenType.EOF) {
            writeln(token);    
            token = next();
        }
        
        writeln(token);
    }

}
