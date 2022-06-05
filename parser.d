module parser;

import lexer;
import std.variant;
import std.algorithm;
import std.exception;
import std.stdio;

alias PrimaryVal = Lexeme;

class Expression {};

class Binary : Expression {
    string op;
    Expression lhs;
    Expression rhs;

    this(string op, Expression lhs, Expression rhs) {
        this.op = op;
        this.lhs = lhs;
        this.rhs = rhs;
    }

    override string toString() {
        return "Binary(op:'" ~ op ~ "'" ~ ", lhs:" ~ lhs.toString() ~ ", rhs:" ~ rhs.toString() ~ ")";
    }

}

class Primary : Expression {};

class Number : Primary {
    PrimaryVal val;

    this (int val) {
        this.val = PrimaryVal(val);
    }

    this (float val) {
        this.val = PrimaryVal(val);
    }

    this (Lexeme val) {
        this.val = val;
    }

    override string toString() {
        return "Number(" ~ val.toString() ~ ")";
    }
}

class Identifier : Primary {
    PrimaryVal val;

    this (string val) {
        this.val = PrimaryVal(val);
    }

    this (Lexeme val) {
        this.val = val;
    }

    override string toString() {
        return "Identifier(" ~ val.toString() ~ ")";
    }
}

class Prefix : Expression {
    string op;
    Expression rhs;

    this (string op, Expression rhs) {
        this.op = op;
        this.rhs = rhs;
    }

    override string toString() {
        return "Prefix(op:'" ~ op ~ "', rhs:" ~ rhs.toString() ~ ")";
    }
}

class StmtExpr : Expression {}

class Let : StmtExpr {
    Expression rhs;

    this (Expression rhs) {
        this.rhs = rhs;
    }

    override string toString() {
        return "Let(expr:" ~ rhs.toString() ~ ")";
    }
}

class Const : StmtExpr {
    Expression rhs;

    this (Expression rhs) {
        this.rhs = rhs;
    }

    override string toString() {
        return "Const(expr:" ~ rhs.toString() ~ ")";
    }
}

enum Assoc {
    Left, Right
}

class Parser : Expression {

    Tokenizer lex;
    Expression[] exprs;
    int[string] prec;
    string[] right_assoc;
    string[] prefix;
    Token curr_token;

    this (Tokenizer lex) {
        this.lex = lex;
        this.prec = [   "=":  1,
                        "==": 2,
                        "!=": 2,
                        ">":  3,
                        ">=": 3,
                        "<":  3,
                        "<=": 3,

                        "+": 4,
                        "-": 4,
                        "*": 5,
                        "/": 5,
                        "%": 5,
                        "^": 6
                        ];
        this.prefix = ["!", "-", "+"];
        this.right_assoc = ["^", "="];
        this.curr_token = lex.next();
    }

    Assoc getAssoc(Token token) {
        if (right_assoc.canFind(token.lexeme.toString())) {
            return Assoc.Right;
        }

        return Assoc.Left;
    }

    int getPrec(Token token) {
        if (auto prec = token.lexeme.toString() in prec) {
            return *prec;
        }

        return -1;
    }

    void advance() {
        curr_token = lex.next();
    }

    Expression[] parse() {
        Expression expr = parse_expr();

        if (!expr) return exprs;

        if (curr_token.type != TokenType.SemiColon) {
            throw new Exception("Where's the ';', mate?");
        }

        advance();
        exprs ~= expr;
        return parse();
    }
    
    Expression parse_expr() {
        Expression lhs = parse_primary();
        
        if (!lhs) return null;
        
        return parse_binary_rhs(0, lhs);
    }

    Expression parse_primary() {
        switch (curr_token.type) {
        case TokenType.Int: case TokenType.Float: return parse_number(); break;
        case TokenType.Identifier: return parse_identifier(); break;
        case TokenType.Left_paren: return parse_paren(); break;
        case TokenType.Let: return parse_let(); break;
        case TokenType.Const: return parse_const(); break;
        case TokenType.Fn: return parse_function_definition(); break;
        default: return null;
        }        
    }

    Number parse_number() {
        Number expr = new Number(curr_token.lexeme);
        advance();

        return expr;
    }

    Identifier parse_identifier() {
        Identifier expr = new Identifier(curr_token.lexeme);
        advance();

        return expr;
    }

    Expression parse_paren() {
        // escape "("
        advance();
        Expression expr = parse_expr();

        // escape ")"
        advance();

        return expr;
    }

    Expression parse_binary_rhs(int search_prec, Expression lhs) {
        while (true) {
            int token_prec = getPrec(curr_token);

            if (token_prec < search_prec)
                return lhs;
            
            string op = curr_token.lexeme.toString();
            
            // advance past the operator
            advance();

            Expression rhs = parse_primary();
            if (!rhs) return null;

            int next_token_prec = getPrec(curr_token);
            
            if (getAssoc(curr_token) == Assoc.Right)
                token_prec -= 1;

            if (token_prec < next_token_prec) {
                rhs = parse_binary_rhs(token_prec, rhs);

                if (!rhs) return null;
            }
            
            lhs = new Binary(op, lhs, rhs);
        }
    }

    Expression parse_let() {
        advance();
        Expression rhs = parse_expr();
        return new Let(rhs);        
    }

    Expression parse_const() {
        advance();
        Expression rhs = parse_expr();
        return new Const(rhs);
    }

}
